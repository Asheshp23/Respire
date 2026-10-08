//
//  BreathPattern.swift
//  Respire
//

import Foundation

/// The four canonical segments of a breath cycle.
nonisolated enum BreathPhase: Int, CaseIterable, Sendable, Codable {
    case inhale
    case holdFull
    case exhale
    case holdEmpty

    /// The phase that follows this one in a cycle (before zero-length phases are skipped).
    var next: BreathPhase {
        BreathPhase(rawValue: (rawValue + 1) % BreathPhase.allCases.count) ?? .inhale
    }

    var instruction: String {
        switch self {
        case .inhale: "Breathe in"
        case .holdFull, .holdEmpty: "Hold"
        case .exhale: "Breathe out"
        }
    }
}

/// A breathing rhythm expressed as durations (in seconds) for each phase.
/// A duration of `0` removes that phase from the cycle (e.g. Coherent breathing has no holds).
nonisolated struct BreathPattern: Identifiable, Hashable, Sendable, Codable {
    var id: String
    var name: String
    var summary: String
    var inhale: TimeInterval
    var holdFull: TimeInterval
    var exhale: TimeInterval
    var holdEmpty: TimeInterval

    static let durationRange: ClosedRange<TimeInterval> = 0...20

    func duration(of phase: BreathPhase) -> TimeInterval {
        switch phase {
        case .inhale: inhale
        case .holdFull: holdFull
        case .exhale: exhale
        case .holdEmpty: holdEmpty
        }
    }

    var cycleDuration: TimeInterval { inhale + holdFull + exhale + holdEmpty }

    var breathsPerMinute: Double {
        cycleDuration > 0 ? 60 / cycleDuration : 0
    }

    /// A pattern needs at least an inhale and an exhale to be breathable.
    var isValid: Bool { inhale > 0 && exhale > 0 }

    /// The rhythm in words a beginner can follow: "In 4s · Hold 7s · Out 8s".
    var timingLabel: String {
        BreathPhase.allCases.compactMap { phase in
            let seconds = duration(of: phase)
            guard seconds > 0 else { return nil }
            let name = switch phase {
            case .inhale: "In"
            case .holdFull, .holdEmpty: "Hold"
            case .exhale: "Out"
            }
            return "\(name) \(seconds.formatted(.number.precision(.fractionLength(0...1))))s"
        }
        .joined(separator: " · ")
    }

    /// Compact rhythm label such as "4 · 7 · 8".
    var rhythmLabel: String {
        BreathPhase.allCases
            .map { duration(of: $0) }
            .filter { $0 > 0 }
            .map { $0.formatted(.number.precision(.fractionLength(0...1))) }
            .joined(separator: " · ")
    }
}

nonisolated extension BreathPattern {
    /// In 4, out 6: six breaths a minute with a longer out-breath, the easiest way to settle.
    static let calm = BreathPattern(
        id: "calm", name: "Calm", summary: "A longer out-breath to settle",
        inhale: 4, holdFull: 0, exhale: 6, holdEmpty: 0
    )

    /// In 4, out 8: a long, slow release before rest, with no holds to manage.
    static let unwind = BreathPattern(
        id: "unwind", name: "Unwind", summary: "A long, slow out-breath before rest",
        inhale: 4, holdFull: 0, exhale: 8, holdEmpty: 0
    )

    static let box = BreathPattern(
        id: "box", name: "Box", summary: "Four equal counts: in, hold, out, hold",
        inhale: 4, holdFull: 4, exhale: 4, holdEmpty: 4
    )

    static let relaxing478 = BreathPattern(
        id: "478", name: "4-7-8", summary: "A long hold and a longer out-breath, for sleep",
        inhale: 4, holdFull: 7, exhale: 8, holdEmpty: 0
    )

    static let coherent = BreathPattern(
        id: "coherent", name: "Coherent", summary: "Even and steady, about five breaths a minute",
        inhale: 5.5, holdFull: 0, exhale: 5.5, holdEmpty: 0
    )

    /// Gentlest first: no-hold rhythms, then the classic patterns with holds.
    static let presets: [BreathPattern] = [.calm, .coherent, .unwind, .box, .relaxing478]

    static let customDefault = BreathPattern(
        id: "custom", name: "Custom", summary: "Your own rhythm",
        inhale: 4, holdFull: 2, exhale: 6, holdEmpty: 0
    )
}
