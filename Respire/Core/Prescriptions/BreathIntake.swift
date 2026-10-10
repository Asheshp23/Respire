//
//  BreathIntake.swift
//  Respire
//
//  What a person tells Respire before it makes them a session: safety first, then how
//  they feel, what they need, how long they have, where they are, and what comes next.
//  Everything stays on the device. Health answers can be remembered so they're asked once.
//

import Foundation

struct BreathIntake: Hashable {
    // MARK: Safety

    /// Right now: any of these means no session today, and a gentle word to get help.
    enum RedFlag: String, CaseIterable, Identifiable {
        case chestPain, cantCatchBreath, faint
        var id: String { rawValue }

        var title: String {
            switch self {
            case .chestPain: "Chest pain or pressure"
            case .cantCatchBreath: "Struggling to breathe"
            case .faint: "Feeling faint or about to pass out"
            }
        }
    }

    /// Health that changes what's safe, remembered between sessions if the person wants.
    enum Condition: String, CaseIterable, Identifiable, Codable {
        case pregnant, heart, breathing, epilepsy, panicHistory, recentSurgery
        var id: String { rawValue }

        var title: String {
            switch self {
            case .pregnant: "Pregnant"
            case .heart: "Heart condition or high blood pressure"
            case .breathing: "Asthma or a lung condition"
            case .epilepsy: "Epilepsy or seizures"
            case .panicHistory: "Panic attacks"
            case .recentSurgery: "Recent surgery or injury to chest or belly"
            }
        }

        /// Breath holds aren't offered with any of these, except a history of panic, which
        /// keeps holds very short instead.
        var rulesOutHolds: Bool { self != .panicHistory }
    }

    // MARK: State

    enum Feeling: String, CaseIterable, Identifiable {
        case anxious, panicky, stressed, angry, sad, scattered, restless, tired, wired, okay
        var id: String { rawValue }

        var title: String {
            switch self {
            case .anxious: "Anxious"
            case .panicky: "Panicky"
            case .stressed: "Stressed"
            case .angry: "Angry"
            case .sad: "Low"
            case .scattered: "Scattered"
            case .restless: "Restless"
            case .tired: "Tired"
            case .wired: "Wired"
            case .okay: "Okay"
            }
        }

        var symbol: String {
            switch self {
            case .anxious: "wind"
            case .panicky: "bolt.heart"
            case .stressed: "tornado"
            case .angry: "flame"
            case .sad: "cloud.drizzle"
            case .scattered: "sparkles"
            case .restless: "figure.walk.motion"
            case .tired: "battery.25percent"
            case .wired: "bolt"
            case .okay: "sun.min"
            }
        }

        /// Feelings where a longer out-breath matters most.
        var needsLongExhale: Bool { [.anxious, .panicky, .stressed, .angry, .wired].contains(self) }
    }

    enum Goal: String, CaseIterable, Identifiable {
        case calm, focus, energy, sleep, steady
        var id: String { rawValue }

        var title: String {
            switch self {
            case .calm: "Calm down"
            case .focus: "Focus"
            case .energy: "Gentle energy"
            case .sleep: "Fall asleep"
            case .steady: "Feel steady for something"
            }
        }
    }

    enum Setting: String, CaseIterable, Identifiable {
        case sitting, lying, standing, inPublic
        var id: String { rawValue }

        var title: String {
            switch self {
            case .sitting: "Sitting"
            case .lying: "Lying down"
            case .standing: "Standing"
            case .inPublic: "Out, with people around"
            }
        }
    }

    enum Next: String, CaseIterable, Identifiable {
        case sleep, work, conversation, exam, movement, nothing
        var id: String { rawValue }

        var title: String {
            switch self {
            case .sleep: "Sleep"
            case .work: "Work or study"
            case .conversation: "A hard conversation"
            case .exam: "A test or performance"
            case .movement: "Exercise or a walk"
            case .nothing: "Nothing in particular"
            }
        }
    }

    enum Experience: String, CaseIterable, Identifiable {
        case new, some, practiced
        var id: String { rawValue }

        var title: String {
            switch self {
            case .new: "New to this"
            case .some: "Some practice"
            case .practiced: "Practice often"
            }
        }
    }

    var redFlags: Set<RedFlag> = []
    /// Confirmed: sitting or lying somewhere safe, not driving and not in water.
    var isSomewhereSafe = false
    var conditions: Set<Condition> = []

    var feeling: Feeling = .stressed
    /// How strong it is, 1 (barely) to 10 (overwhelming).
    var intensity = 5
    var goal: Goal = .calm
    var minutes = 3
    var setting: Setting = .sitting
    var next: Next = .nothing
    var experience: Experience = .new
    /// Whether breathing through the nose is comfortable right now.
    var noseIsClear = true
    /// Anything else, in their own words. Kept short.
    var note = ""

    static let minuteChoices = [1, 3, 5, 10]
    static let noteLimit = 200

    /// Something in a person's own words that needs a person, not a breathing app.
    enum Concern { case medical, crisis }

    /// Words that point to a medical emergency or a crisis. Erring on the side of asking.
    var noteConcern: Concern? {
        let text = note.lowercased()
        let crisis = ["suicid", "kill myself", "end my life", "hurt myself", "self harm", "self-harm", "don't want to live", "dont want to live"]
        let medical = ["chest pain", "chest pressure", "heart attack", "can't breathe", "cant breathe", "cannot breathe", "passing out", "fainting", "stroke"]
        if crisis.contains(where: text.contains) { return .crisis }
        if medical.contains(where: text.contains) { return .medical }
        return nil
    }

    /// Nothing should be made when something urgent is going on.
    var needsHelpNow: Bool { !redFlags.isEmpty || noteConcern != nil }
    var mayHold: Bool { !conditions.contains { $0.rulesOutHolds } }
    var isPanicking: Bool { feeling == .panicky || (feeling.needsLongExhale && intensity >= 8) }

    // MARK: Remembering health answers

    private static let conditionsKey = "prescribe.conditions"

    static func rememberedConditions(in defaults: UserDefaults = .standard) -> Set<Condition> {
        Set((defaults.stringArray(forKey: conditionsKey) ?? []).compactMap(Condition.init(rawValue:)))
    }

    static func remember(_ conditions: Set<Condition>, in defaults: UserDefaults = .standard) {
        defaults.set(conditions.map(\.rawValue).sorted(), forKey: conditionsKey)
    }

    static func forget(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: conditionsKey)
    }
}
