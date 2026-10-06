//
//  SomaticContext.swift
//  Respire
//
//  The minimal, coarse description of "this moment" that personalizes an opening.
//  Deliberately lossy: no coordinates, no place names, no timestamps beyond the
//  part of the day. It exists only in memory for the length of one opening and is
//  never logged, persisted, or sent anywhere.
//

import Foundation

nonisolated struct SomaticContext: Sendable, Equatable {
    var focus: SessionFocus
    var timeOfDay: TimeOfDay
    var weekday: String
    /// Resting pulse from the pre-session baseline, if one was measured recently.
    var heartRate: Int?
    var weather: Weather?
    /// The breath world on screen, so the words and the picture agree.
    var sceneTitle: String
    var patternName: String
    var inhaleSeconds: Double
    /// The awareness gate to weave in: today's gate, or the one being practiced.
    var gate: Gate? = nil

    var pulseBand: PulseBand? { heartRate.map(PulseBand.init(bpm:)) }

    nonisolated struct Gate: Sendable, Equatable {
        var number: Int
        var title: String
        var text: String
    }

    // MARK: - Time

    enum TimeOfDay: String, Sendable {
        case lateNight, earlyMorning, morning, midday, afternoon, evening, night

        init(hour: Int) {
            switch hour {
            case 0..<4: self = .lateNight
            case 4..<7: self = .earlyMorning
            case 7..<11: self = .morning
            case 11..<14: self = .midday
            case 14..<17: self = .afternoon
            case 17..<21: self = .evening
            default: self = .night
            }
        }

        var phrase: String {
            switch self {
            case .lateNight: "the middle of the night"
            case .earlyMorning: "early morning"
            case .morning: "morning"
            case .midday: "midday"
            case .afternoon: "afternoon"
            case .evening: "evening"
            case .night: "night"
            }
        }
    }

    // MARK: - Pulse

    /// Descriptive, never evaluative: the opening must not judge a heart rate.
    enum PulseBand: Sendable {
        case settled, steady, lively, quick

        init(bpm: Int) {
            switch bpm {
            case ..<60: self = .settled
            case 60..<80: self = .steady
            case 80..<100: self = .lively
            default: self = .quick
            }
        }

        var phrase: String {
            switch self {
            case .settled: "slow and settled"
            case .steady: "steady"
            case .lively: "a little lively"
            case .quick: "quick"
            }
        }
    }

    // MARK: - Weather

    nonisolated struct Weather: Sendable, Equatable {
        enum Kind: Sendable {
            case clear, cloudy, rain, snow, storm, haze, wind
        }

        var kind: Kind
        /// The condition in plain words, e.g. "light rain".
        var condition: String
        /// Locale-formatted, e.g. "12°C" or "54°F".
        var temperature: String
        var isDaylight: Bool
        var isWindy: Bool

        /// "light rain, 12°C, after dark, breezy"
        var summary: String {
            var parts = [condition, temperature, isDaylight ? "in daylight" : "after dark"]
            if isWindy, kind != .wind { parts.append("breezy") }
            return parts.joined(separator: ", ")
        }
    }
}
