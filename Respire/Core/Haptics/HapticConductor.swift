//
//  HapticConductor.swift
//  Respire
//

import CoreHaptics
import Foundation
import os

/// Choreographs CoreHaptics patterns that follow the breath:
/// a slow, warm swell on inhale, a quiet settle on hold, and a long soft fade on exhale.
///
/// Each phase is rendered as one continuous haptic event whose intensity/sharpness are shaped by
/// parameter curves that share the same sinusoidal easing as the visualizer, so touch and sight
/// stay in lockstep.
final class HapticConductor {
    var isEnabled = true {
        didSet { if !isEnabled { silence() } }
    }

    let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private let logger = Logger(subsystem: "Respire", category: "Haptics")

    /// Longest duration CoreHaptics allows for a single continuous event.
    private static let maxContinuousDuration: TimeInterval = 30
    /// Parameter curves are limited to 16 control points.
    private static let curveResolution = 12

    // MARK: - Lifecycle

    func prepare() {
        guard isSupported, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            // These handlers are invoked on an internal CoreHaptics queue; hop back to the main actor.
            engine.resetHandler = { [weak self] in
                Task { @MainActor in self?.handleEngineReset() }
            }
            engine.stoppedHandler = { [weak self] reason in
                Task { @MainActor in self?.handleEngineStopped(reason) }
            }
            try engine.start()
            self.engine = engine
        } catch {
            logger.error("Failed to create haptic engine: \(error.localizedDescription)")
        }
    }

    func shutdown() {
        silence()
        engine?.stop()
        engine = nil
    }

    // MARK: - Playback

    /// Plays the haptic for `phase`, optionally starting part-way through (e.g. after a resume).
    func play(_ phase: BreathPhase, duration: TimeInterval, elapsed: TimeInterval = 0) {
        silence()
        guard isEnabled, isSupported, duration > 0 else { return }
        if engine == nil { prepare() }
        guard let engine else { return }

        do {
            try engine.start()
            let pattern = try Self.pattern(for: phase, duration: min(duration, Self.maxContinuousDuration))
            let player = try engine.makeAdvancedPlayer(with: pattern)
            if elapsed > 0 {
                try player.seek(toOffset: elapsed)
            }
            try player.start(atTime: CHHapticTimeImmediate)
            self.player = player
        } catch {
            logger.error("Failed to play \(String(describing: phase)) haptic: \(error.localizedDescription)")
        }
    }

    func silence() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    // MARK: - Choreography

    /// Shape of a phase: start/end intensity and sharpness plus an easing curve between them.
    private struct Envelope {
        var duration: TimeInterval
        var intensity: (from: Float, to: Float)
        var sharpness: (from: Float, to: Float)
        /// A soft, rounded tap marking the turn into this phase, so the change can be felt
        /// with eyes closed. `nil` for none.
        var turn: Float? = nil
    }

    /// The tap comes first; the phase's swell or release begins just after it.
    private static let turnLead: TimeInterval = 0.06

    private static func pattern(for phase: BreathPhase, duration: TimeInterval) throws -> CHHapticPattern {
        switch phase {
        case .inhale:
            // Swell: a low, round rumble that blooms and brightens slightly as the lungs fill.
            return try continuousPattern(Envelope(
                duration: duration,
                intensity: (0.08, 0.65),
                sharpness: (0.05, 0.30),
                turn: 0.32
            ))

        case .exhale:
            // Release: begins just under the inhale's peak and melts away to nothing.
            return try continuousPattern(Envelope(
                duration: duration,
                intensity: (0.50, 0.0),
                sharpness: (0.20, 0.0),
                turn: 0.28
            ))

        case .holdFull:
            // Settle: a brief, dull afterglow that fades into stillness so the hold feels suspended.
            return try continuousPattern(Envelope(
                duration: min(duration, 1.5),
                intensity: (0.22, 0.0),
                sharpness: (0.05, 0.0),
                turn: 0.2
            ))

        case .holdEmpty:
            // Rest: a single feather-light, rounded tap marking the pause.
            let tap = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.18),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0)
                ],
                relativeTime: 0
            )
            return try CHHapticPattern(events: [tap], parameters: [])
        }
    }

    private static func continuousPattern(_ envelope: Envelope) throws -> CHHapticPattern {
        // The turn's tap plays before the control curves begin, so they don't scale it down.
        let lead = envelope.turn == nil ? 0 : min(turnLead, envelope.duration / 4)
        let length = max(envelope.duration - lead, 0.05)

        // Base values of 1.0 / 0.0 let the control curves define the absolute shape:
        // intensity control multiplies the base; sharpness control is added to it.
        var events = [CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0)
            ],
            relativeTime: lead,
            duration: length
        )]
        if let turn = envelope.turn {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: turn),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12)
                ],
                relativeTime: 0
            ))
        }

        let curves = [
            curve(.hapticIntensityControl, from: envelope.intensity.from, to: envelope.intensity.to, over: length, startingAt: lead),
            curve(.hapticSharpnessControl, from: envelope.sharpness.from, to: envelope.sharpness.to, over: length, startingAt: lead)
        ]
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }

    /// Samples a sinusoidal ease-in-out between two values. CoreHaptics interpolates linearly
    /// between control points, so a dozen samples is plenty for a smooth, organic feel.
    private static func curve(_ id: CHHapticDynamicParameter.ID, from start: Float, to end: Float, over duration: TimeInterval,
                              startingAt offset: TimeInterval = 0) -> CHHapticParameterCurve {
        let points = (0...curveResolution).map { step -> CHHapticParameterCurve.ControlPoint in
            let t = Double(step) / Double(curveResolution)
            let eased = Float(0.5 - 0.5 * cos(.pi * t))
            return CHHapticParameterCurve.ControlPoint(
                relativeTime: t * duration,
                value: start + (end - start) * eased
            )
        }
        return CHHapticParameterCurve(parameterID: id, controlPoints: points, relativeTime: offset)
    }

    // MARK: - Engine recovery

    private func handleEngineReset() {
        // The haptic server restarted; existing players are invalid. Restart lazily on next phase.
        player = nil
        do {
            try engine?.start()
        } catch {
            logger.error("Haptic engine restart failed: \(error.localizedDescription)")
            engine = nil
        }
    }

    private func handleEngineStopped(_ reason: CHHapticEngine.StoppedReason) {
        logger.info("Haptic engine stopped: \(reason.rawValue)")
        player = nil
    }
}
