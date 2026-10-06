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

    /// Compact rhythm label such as "4 · 7 · 8".
    var rhythmLabel: String {
        BreathPhase.allCases
            .map { duration(of: $0) }
            .filter { $0 > 0 }
            .map { $0.formatted(.number.precision(.fractionLength(0...1))) }
            .joined(separator: " · ")
    }
}

extension BreathPattern {
    static let box = BreathPattern(
        id: "box", name: "Box", summary: "Steady focus and composure",
        inhale: 4, holdFull: 4, exhale: 4, holdEmpty: 4
    )

    static let relaxing478 = BreathPattern(
        id: "478", name: "4-7-8", summary: "Deep relaxation before sleep",
        inhale: 4, holdFull: 7, exhale: 8, holdEmpty: 0
    )

    static let coherent = BreathPattern(
        id: "coherent", name: "Coherent", summary: "Balance heart-rate variability",
        inhale: 5.5, holdFull: 0, exhale: 5.5, holdEmpty: 0
    )

    static let presets: [BreathPattern] = [.box, .relaxing478, .coherent]

    static let customDefault = BreathPattern(
        id: "custom", name: "Custom", summary: "Your own rhythm",
        inhale: 4, holdFull: 2, exhale: 6, holdEmpty: 0
    )
}
