//
//  Practice.swift
//  Respire
//
//  A guided session with its own full spoken script, written for one or more
//  personas: a settling-in, words for particular breaths (which nostril, what to
//  imagine, when to hum), an imagery set that changes from session to session, and a
//  closing. The breath engine keeps the time; the script only supplies the words.
//

import Foundation

/// Words for one breath, phase by phase. Any phase can be left silent.
nonisolated struct BreathCue: Hashable, Sendable {
    var inhale: String?
    var hold: String?
    var exhale: String?
    var rest: String?

    func text(for phase: BreathPhase) -> String? {
        switch phase {
        case .inhale: inhale
        case .holdFull: hold
        case .exhale: exhale
        case .holdEmpty: rest
        }
    }
}

struct Practice: Identifiable, Hashable {
    enum Category: String, CaseIterable {
        case calm, sleep, focus, connection, pranayama

        var title: String {
            switch self {
            case .calm: "Calm"
            case .sleep: "Sleep"
            case .focus: "Focus"
            case .connection: "Connection"
            case .pranayama: "Pranayama"
            }
        }

        var symbol: String {
            switch self {
            case .calm: "leaf"
            case .sleep: "moon.stars"
            case .focus: "scope"
            case .connection: "heart"
            case .pranayama: "wind"
            }
        }
    }

    let id: String
    let title: String
    let summary: String
    let personas: [Persona]
    let category: Category
    var inhale: Double = 4
    var hold: Double = 0
    var exhale: Double = 6
    var rest: Double = 0
    let breaths: Int
    let world: BreathTheme
    let focus: SessionFocus
    /// A soft hum sounds on each out-breath to hum along with.
    var hums = false
    /// Said before beginning, for practices that ask the body for something.
    var caution: String?
    let intro: [VoiceLine]
    /// Words for the first breaths, in order. Later breaths are quiet, apart from imagery.
    var cues: [BreathCue] = []
    /// Cues that repeat for every breath, in turn, such as which nostril.
    var repeatsCues = false
    /// Sets of imagery; one is chosen for each session and spoken along the way.
    var imagery: [[String]] = []
    let closing: [VoiceLine]

    var pattern: BreathPattern {
        BreathPattern(id: "practice.\(id)", name: title, summary: summary,
                      inhale: inhale, holdFull: hold, exhale: exhale, holdEmpty: rest)
    }

    var minutes: Int {
        max(1, Int((Double(breaths) * pattern.cycleDuration / 60).rounded()))
    }

    var lengthLabel: String { minutes == 1 ? "1 min" : "\(minutes) min" }

    /// What's shown before beginning: the summary, and any caution.
    var guidance: String {
        caution.map { "\(summary) \($0)" } ?? summary
    }

    static func == (lhs: Practice, rhs: Practice) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static func practice(id: String) -> Practice? { all.first { $0.id == id } }

    static func practices(for persona: Persona) -> [Practice] {
        all.filter { $0.personas.contains(persona) }
    }
}

// MARK: - Needs

/// How someone is feeling when they open the app, and what helps. Each need points to
/// the best guided session for the persona breathing.
enum Need: String, CaseIterable, Identifiable {
    case calm, sleep, focus, connect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "Calm down"
        case .sleep: "Sleep"
        case .focus: "Focus"
        case .connect: "Connect"
        }
    }

    var symbol: String {
        switch self {
        case .calm: "leaf"
        case .sleep: "moon.stars"
        case .focus: "scope"
        case .connect: "heart"
        }
    }

    /// One word, for the home's relief bar.
    var word: String {
        switch self {
        case .calm: "Calm"
        case .sleep: "Sleep"
        case .focus: "Focus"
        case .connect: "Connect"
        }
    }

    /// The three on the home: the states people most often open the app in.
    static let relief: [Need] = [.calm, .sleep, .focus]

    /// The sessions that answer this need, best first; the first one the persona has wins.
    var preferred: [Practice.ID] {
        switch self {
        case .calm: ["bumble-bee", "box-stress", "gentle-chair", "bhramari", "balloon-belly"]
        case .sleep: ["sleepy-starfish", "sleep-sanctuary", "evening-gratitude"]
        case .focus: ["balloon-belly", "test-prep", "nadi-shodhana"]
        case .connect: ["partner-peace", "conflict-cool", "boundary-breath"]
        }
    }

    /// What most people need at this hour: focus in the morning, calm in the day, sleep at night.
    static func likely(at date: Date, calendar: Calendar = .current) -> Need {
        switch calendar.component(.hour, from: date) {
        case 5..<11: .focus
        case 11..<18: .calm
        default: .sleep
        }
    }
}

extension Practice {
    static func recommended(for need: Need, persona: Persona) -> Practice? {
        need.preferred.lazy.compactMap { practice(id: $0) }.first { $0.personas.contains(persona) }
    }

    /// The session to offer right now, for this hour and this persona.
    static func suggestion(at date: Date, persona: Persona) -> Practice? {
        recommended(for: Need.likely(at: date), persona: persona)
            ?? recommended(for: .calm, persona: persona)
            ?? practices(for: persona).first
    }
}
