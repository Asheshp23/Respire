//
//  SessionViewModel.swift
//  Respire
//

import Foundation
import Observation

/// Coordinates a breathing session: the breath engine, its haptic accompaniment, the
/// sound and calm voice that guide it with eyes closed, and the optional resting-pulse
/// baseline captured before starting.
@Observable
final class SessionViewModel {
    let engine: BreathEngine
    var baseline: PulseReading?
    /// A reading taken after a session, to set beside the baseline.
    var afterReading: PulseReading?
    /// Set by Today's Start button: the next free session begins as soon as it appears.
    @ObservationIgnored var beginsOnArrival = false
    /// Time, weather, and pulse for the personalized opening. Shared so weather is cached across sessions.
    let contextService = DeviceContextService()
    /// Everything you hear: the world's sound, the breath sound, the chime, and the voice.
    @ObservationIgnored let soundscape: Soundscape
    /// The spoken script, for eyes-closed practice.
    @ObservationIgnored let voice: VoiceGuide
    /// Finished sessions, for the You tab.
    let history = SessionHistory()

    var hapticsEnabled = true {
        didSet { haptics.isEnabled = hapticsEnabled }
    }

    var hapticsSupported: Bool { haptics.isSupported }

    @ObservationIgnored private let haptics = HapticConductor()
    /// The closing words and the fade after a session finishes.
    @ObservationIgnored private var closingTask: Task<Void, Never>?

    init(pattern: BreathPattern = .box) {
        engine = BreathEngine(pattern: pattern)
        soundscape = Soundscape()
        voice = VoiceGuide(soundscape: soundscape)
        engine.onPhaseChange = { [weak self] phase, duration, elapsed in
            guard let self else { return }
            haptics.play(phase, duration: duration, elapsed: elapsed)
            // Chime and speak only when a phase truly begins, not when resuming partway through.
            if elapsed == 0 {
                soundscape.cue(phase)
                voice.phaseBegan(phase, completedCycles: engine.completedCycles, targetCycles: engine.targetCycles)
            }
        }
        engine.onHalt = { [weak self] in
            guard let self else { return }
            haptics.silence()
            if engine.state == .finished { closeSession() }
        }
    }

    func select(_ pattern: BreathPattern) {
        engine.setPattern(pattern)
    }

    func togglePlayback() {
        if engine.state == .idle || engine.state == .finished {
            closingTask?.cancel()
            voice.stop()
            haptics.prepare()
            voice.reset()
            afterReading = nil
        }
        engine.togglePlayback()
    }

    func stop() {
        closingTask?.cancel()
        engine.stop()
        voice.stop()
    }

    /// Haptic engines are torn down by the system in the background; pause so the
    /// user returns to a consistent state rather than a session that ran unattended.
    func enterBackground() {
        closingTask?.cancel()
        engine.pause()
        haptics.shutdown()
        soundscape.stop()
    }

    /// Finished on its own: a bell, the closing words, then the sound fades. With eyes
    /// closed, that's how you know it's over.
    private func closeSession() {
        history.record(title: engine.pattern.name,
                       seconds: Double(engine.completedCycles) * engine.pattern.cycleDuration)
        soundscape.ringEnd()
        closingTask?.cancel()
        closingTask = Task { [weak self] in
            // Let the bell ring out first.
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, let self else { return }
            await voice.closing()
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, engine.state == .finished else { return }
            soundscape.stop()
        }
    }
}
