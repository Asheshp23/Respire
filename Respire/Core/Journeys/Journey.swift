//
//  Journey.swift
//  Respire
//
//  The content model for Journeys, decoded from bundled `<id>.journey.json` files.
//  The contract is `docs/journey.schema.json`; see `docs/Journeys.md` for the spec.
//

import Foundation

nonisolated struct Journey: Codable, Identifiable, Hashable, Sendable {
    static let supportedSchemaVersion = 1

    var schemaVersion: Int
    var id: String
    /// Position in the sidebar; lower comes first.
    var order: Int?
    var title: String
    var subtitle: String
    var summary: String
    var symbol: String
    /// Starting index into the prism's seven colors; each day steps one hue onward.
    var hue: Int
    var origin: Origin?
    var chapters: [JourneyChapter]

    nonisolated struct Origin: Codable, Hashable, Sendable {
        var title: String
        var body: String
    }

    func chapter(id: JourneyChapter.ID) -> JourneyChapter? {
        chapters.first { $0.id == id }
    }

    /// Stable key for one chapter across all journeys, used for stored progress.
    func key(for chapter: JourneyChapter) -> String {
        "\(id)/\(chapter.id)"
    }
}

nonisolated struct JourneyChapter: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var day: Int
    var title: String
    var tagline: String
    /// The 112 Gates dharana this day is drawn from, if any.
    var gate: Int?
    /// A `BreathTheme` raw value.
    var world: String
    var focus: SessionFocus
    var practice: Practice
    var cards: [StoryCard]
    var reflection: String
    var completion: Completion

    nonisolated struct Practice: Codable, Hashable, Sendable {
        var inhale: Double
        var holdFull: Double
        var exhale: Double
        var holdEmpty: Double
        var minutes: Double
        var guidance: String
    }

    nonisolated struct Completion: Codable, Hashable, Sendable {
        var title: String
        var body: String
    }

    /// The day's rhythm as a pattern the breath engine can play.
    func pattern(in journey: Journey) -> BreathPattern {
        BreathPattern(
            id: "journey.\(journey.key(for: self))",
            name: "Day \(day) · \(title)",
            summary: tagline,
            inhale: practice.inhale,
            holdFull: practice.holdFull,
            exhale: practice.exhale,
            holdEmpty: practice.holdEmpty
        )
    }

    /// Whole breath cycles that fill the practice's minutes.
    func targetCycles(in journey: Journey) -> Int {
        let cycle = pattern(in: journey).cycleDuration
        guard cycle > 0 else { return 1 }
        return max(1, Int((practice.minutes * 60 / cycle).rounded()))
    }
}

nonisolated struct StoryCard: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case origin, image, notice, practice
    }

    var kind: Kind
    var eyebrow: String
    var title: String
    var body: String
    var cue: String?
    /// How open the world appears in the card's art: 0 empty, 1 full breath.
    var openness: Double?
}

extension SessionFocus: Codable {}
