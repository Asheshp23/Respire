//
//  BreathEngine.swift
//  Respire
//

import Foundation
import Observation

/// A point-in-time reading of the breath cycle, sampled by the visualizer every frame.
nonisolated struct BreathSnapshot: Sendable, Equatable {
    var phase: BreathPhase
    /// Linear progress through the current phase, 0...1.
    var phaseProgress: Double
    /// Eased "lung fullness", 0 (empty) ... 1 (full). Drives size, glow, and haptic intensity.
    var lungVolume: Double
    var secondsRemaining: TimeInterval

    static let resting = BreathSnapshot(phase: .holdEmpty, phaseProgress: 0, lungVolume: 0, secondsRemaining: 0)
}

/// Drift-free state machine that walks through a `BreathPattern`.
///
/// The engine only publishes *discrete* changes (state, phase, cycle count). Continuous values
/// such as progress and lung volume are derived on demand via `snapshot(at:)`, so views can
/// sample them from a `TimelineView` at display refresh rate without the engine ticking at 60 Hz.
@Observable
final class BreathEngine {
    enum State: Equatable {
        case idle
        case running
        case paused
        case finished
    }

    private(set) var pattern: BreathPattern
    private(set) var state: State = .idle
    private(set) var phase: BreathPhase = .inhale
    private(set) var completedCycles = 0

    /// When non-nil, the session ends after this many full cycles.
    var targetCycles: Int?

    /// Called whenever a phase begins (or resumes), with the phase, its full duration, and the time
    /// already elapsed within it. Used to drive haptics/audio in lockstep with the visuals.
    @ObservationIgnored var onPhaseChange: ((_ phase: BreathPhase, _ duration: TimeInterval, _ elapsed: TimeInterval) -> Void)?
    /// Called on any transition that should silence feedback (pause, stop, finish).
    @ObservationIgnored var onHalt: (() -> Void)?

    @ObservationIgnored private var phaseStartedAt: Date = .now
    @ObservationIgnored private var phaseDuration: TimeInterval = 0
    @ObservationIgnored private var pausedElapsed: TimeInterval = 0
    @ObservationIgnored private var advanceTask: Task<Void, Never>?

    init(pattern: BreathPattern) {
        self.pattern = pattern
    }

    // MARK: - Events

    func start(at date: Date = .now) {
        guard pattern.isValid else { return }
        cancelTimer()
        completedCycles = 0
        state = .running
        enter(firstActivePhase(), startingAt: date)
    }

    func pause(at date: Date = .now) {
        guard state == .running else { return }
        cancelTimer()
        pausedElapsed = min(date.timeIntervalSince(phaseStartedAt), phaseDuration)
        state = .paused
        onHalt?()
    }

    func resume(at date: Date = .now) {
        guard state == .paused else { return }
        state = .running
        phaseStartedAt = date.addingTimeInterval(-pausedElapsed)
        // Restart feedback for the remainder of the current phase.
        onPhaseChange?(phase, phaseDuration, pausedElapsed)
        scheduleAdvance()
    }

    func stop() {
        cancelTimer()
        state = .idle
        phase = .inhale
        pausedElapsed = 0
        onHalt?()
    }

    func togglePlayback() {
        switch state {
        case .idle, .finished: start()
        case .running: pause()
        case .paused: resume()
        }
    }

    /// Swaps the rhythm. A running session restarts cleanly on the new pattern.
    func setPattern(_ newPattern: BreathPattern) {
        guard newPattern != pattern else { return }
        let wasActive = state == .running || state == .paused
        stop()
        pattern = newPattern
        if wasActive { start() }
    }

    /// Adjusts the rhythm without restarting: the phase underway keeps its length and
    /// later phases use the new one. For gently lengthening the out-breath mid-session;
    /// call it as an in-breath begins, so the cycle's progress stays continuous.
    func retune(_ newPattern: BreathPattern) {
        guard newPattern.isValid else { return }
        pattern = newPattern
    }

    // MARK: - Sampling

    func snapshot(at date: Date) -> BreathSnapshot {
        guard state != .idle && state != .finished, phaseDuration > 0 else { return .resting }

        let elapsed = state == .paused ? pausedElapsed : date.timeIntervalSince(phaseStartedAt)
        let progress = min(max(elapsed / phaseDuration, 0), 1)
        return BreathSnapshot(
            phase: phase,
            phaseProgress: progress,
            lungVolume: Self.lungVolume(for: phase, progress: progress),
            secondsRemaining: max(phaseDuration - elapsed, 0)
        )
    }

    /// Breaths so far, including the fraction of the current one: 2.4 means two complete
    /// cycles and 40% of the third. Places advance one stage per breath with this.
    func cycleProgress(at date: Date) -> Double {
        switch state {
        case .idle: return 0
        case .finished: return Double(completedCycles)
        case .running, .paused: break
        }
        let cycle = pattern.cycleDuration
        guard cycle > 0 else { return Double(completedCycles) }
        let snapshot = snapshot(at: date)
        var elapsed = 0.0
        for earlier in BreathPhase.allCases {
            if earlier == phase { break }
            elapsed += pattern.duration(of: earlier)
        }
        elapsed += snapshot.phaseProgress * pattern.duration(of: phase)
        return Double(completedCycles) + min(elapsed / cycle, 1)
    }

    /// Sinusoidal ease-in-out mirrors the natural acceleration/deceleration of airflow.
    nonisolated static func lungVolume(for phase: BreathPhase, progress: Double) -> Double {
        let eased = 0.5 - 0.5 * cos(.pi * progress)
        switch phase {
        case .inhale: return eased
        case .holdFull: return 1
        case .exhale: return 1 - eased
        case .holdEmpty: return 0
        }
    }

    // MARK: - Transitions

    private func enter(_ newPhase: BreathPhase, startingAt date: Date) {
        phase = newPhase
        phaseDuration = pattern.duration(of: newPhase)
        phaseStartedAt = date
        pausedElapsed = 0
        onPhaseChange?(newPhase, phaseDuration, 0)
        scheduleAdvance()
    }

    private func advance() {
        guard state == .running else { return }
        // Anchor the next phase to the scheduled boundary (not "now") so timing never drifts.
        let boundary = phaseStartedAt.addingTimeInterval(phaseDuration)
        let next = nextActivePhase(after: phase)

        if next.rawValue <= phase.rawValue {
            completedCycles += 1
            if let targetCycles, completedCycles >= targetCycles {
                cancelTimer()
                state = .finished
                onHalt?()
                return
            }
        }
        enter(next, startingAt: boundary)
    }

    private func scheduleAdvance() {
        cancelTimer()
        let deadline = phaseStartedAt.addingTimeInterval(phaseDuration)
        advanceTask = Task { [weak self] in
            let delay = max(deadline.timeIntervalSinceNow, 0)
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.advance()
        }
    }

    private func cancelTimer() {
        advanceTask?.cancel()
        advanceTask = nil
    }

    private func firstActivePhase() -> BreathPhase {
        pattern.duration(of: .inhale) > 0 ? .inhale : nextActivePhase(after: .inhale)
    }

    /// Returns the next phase with a non-zero duration, wrapping around the cycle.
    private func nextActivePhase(after current: BreathPhase) -> BreathPhase {
        var candidate = current.next
        for _ in BreathPhase.allCases where pattern.duration(of: candidate) == 0 {
            candidate = candidate.next
        }
        return candidate
    }
}
