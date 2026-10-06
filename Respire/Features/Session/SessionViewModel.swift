//
//  SessionViewModel.swift
//  Respire
//

import Foundation
import Observation

/// Coordinates a breathing session: the breath engine, its haptic accompaniment,
/// and the optional resting-pulse baseline captured before starting.
@Observable
final class SessionViewModel {
    let engine: BreathEngine
    var baseline: PulseReading?
    /// Time, weather, and pulse for the personalized opening. Shared so weather is cached across sessions.
    let contextService = DeviceContextService()
    /// Nature sound and solfeggio tone, breathing with the engine.
    @ObservationIgnored let soundscape = Soundscape()

    var hapticsEnabled = true {
        didSet { haptics.isEnabled = hapticsEnabled }
    }

    var hapticsSupported: Bool { haptics.isSupported }

    @ObservationIgnored private let haptics = HapticConductor()

    init(pattern: BreathPattern = .box) {
        engine = BreathEngine(pattern: pattern)
        engine.onPhaseChange = { [weak self] phase, duration, elapsed in
            self?.haptics.play(phase, duration: duration, elapsed: elapsed)
        }
        engine.onHalt = { [weak self] in
            self?.haptics.silence()
        }
    }

    func select(_ pattern: BreathPattern) {
        engine.setPattern(pattern)
    }

    func togglePlayback() {
        if engine.state == .idle { haptics.prepare() }
        engine.togglePlayback()
    }

    func stop() {
        engine.stop()
    }

    /// Haptic engines are torn down by the system in the background; pause so the
    /// user returns to a consistent state rather than a session that ran unattended.
    func enterBackground() {
        engine.pause()
        haptics.shutdown()
        soundscape.stop()
    }
}
