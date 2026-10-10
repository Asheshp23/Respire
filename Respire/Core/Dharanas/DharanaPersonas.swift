//
//  DharanaPersonas.swift
//  Respire
//
//  The 112 practices, shaped for whoever's breathing.
//
//  Kids: a small set of gentle sensing practices, in their own words, breathed with no
//  holds and for a few minutes at most.
//  Teens: the foundations and deepenings, without breath retention, in plain words.
//  Adults: all 112, as written.
//  Wise: everything but breath retention, in the language of home and garden rather than
//  screens, breathed with no holds and a long, easy exhale.
//

import Foundation

extension Persona {
    /// Gates that ask for breath retention.
    fileprivate static let retentionGates: Set<Int> = [2]
}

extension Dharana {
    /// Whether this gate is offered to a persona at all.
    func suits(_ persona: Persona) -> Bool {
        switch persona {
        case .kids: Self.kidsVersions[number] != nil
        case .teens: level != .nondual && !Persona.retentionGates.contains(number)
        case .adults: true
        case .wise: !Persona.retentionGates.contains(number)
        }
    }

    /// A gate retold for one persona. A `nil` caution keeps the original note.
    struct Wording {
        var title: String
        var text: String
        var caution: String?

        init(_ title: String, _ text: String, _ caution: String? = nil) {
            self.title = title
            self.text = text
            self.caution = caution
        }
    }

    /// The gate as a persona reads it: kids, teens, and the Wise get their own words.
    func adapted(for persona: Persona) -> Dharana {
        let versions: [Int: Wording] = switch persona {
        case .kids: Self.kidsVersions
        case .teens: Self.teenVersions
        case .wise: Self.wiseVersions
        case .adults: [:]
        }
        guard let version = versions[number] else { return self }
        var gate = self
        gate.title = version.title
        gate.text = version.text
        gate.caution = version.caution ?? caution
        return gate
    }

    /// Child-language versions of the gentlest gates: sensing, body, and rest.
    static let kidsVersions: [Int: Wording] = [
        1: .init("The Little Pause",
            "Breathe in, and notice the tiny stop at the top before the air goes out again."),
        4: .init("Tingly Hands",
            "Hold your hands up, just apart. Can you feel them tingle and buzz?"),
        5: .init("A Warm Heart",
            "Put a hand on your chest and breathe warm, kind air into it."),
        7: .init("Three Quiet Breaths",
            "Take three slow breaths, and let your thinking rest, like a puppy taking a nap."),
        11: .init("Breathing Out Everywhere",
            "As you breathe out, pretend the air leaves through your whole body, like a sponge squeezing out."),
        12: .init("The Breath String",
            "Breathe in and out without stopping, like one long, soft string."),
        15: .init("Touch Without Words",
            "Touch something near you, a blanket or your sleeve. Feel it without saying what it is."),
        16: .init("Colors Behind Your Eyes",
            "Close your eyes. What colors and shapes do you see behind your eyelids?"),
        20: .init("Sniff the Air",
            "Take a slow sniff. What does the air smell like right now?"),
        21: .init("A Sip of Water",
            "Take one sip of water slowly. Feel it cool in your mouth and down your throat."),
        23: .init("Blink Like a Camera",
            "Blink slowly. Each blink is a camera click: snap, and here you are."),
        61: .init("Heavy Like a Rock",
            "Let your body feel heavy, like a rock resting on the ground."),
        65: .init("Find Your Heartbeat",
            "Rest a hand on your chest, stay very still, and see if you can feel your heart going thump-thump."),
        67: .init("Tree Roots Feet",
            "Press your feet into the floor and pretend roots grow from them, deep into the earth."),
        68: .init("Warm Hands",
            "Rub your hands together fast, then hold them still. Feel the warmth glow."),
        70: .init("Strong Bones",
            "Feel the strong bones inside you, holding you up like the frame of a little house."),
        87: .init("Good Morning, Me",
            "When you wake up, before anything else, take one big breath and say hello to the day."),
        94: .init("Melting Into Bed",
            "Lie down and let your body melt into the bed, like ice cream on a warm day.",
            "Lie somewhere cozy and safe."),
    ]
}

extension DharanaSection {
    /// The section as a persona practices it: only the gates that suit them, in their
    /// words, at a rhythm they can breathe easily.
    func adapted(for persona: Persona, keepingAll: Bool = false) -> DharanaSection {
        var section = self
        section.dharanas = dharanas.filter { keepingAll || $0.suits(persona) }.map { $0.adapted(for: persona) }
        section.practice = practice.adapted(for: persona)
        let words: [String: (title: String, subtitle: String)] = switch persona {
        case .kids: Self.kidsWords
        case .teens: Self.teenWords
        case .wise: Self.wiseWords
        case .adults: [:]
        }
        if let words = words[numeral] {
            section.title = words.title
            section.subtitle = words.subtitle
        }
        return section
    }

    /// Section names a child can read, for the sections that hold their practices.
    static let kidsWords: [String: (title: String, subtitle: String)] = [
        "I": ("Breathing", "Slow, soft breaths that help you feel calm"),
        "II": ("Your Senses", "Looking, listening, touching, smelling, and tasting"),
        "VI": ("Your Body", "Feeling heavy, warm, strong, and steady"),
        "VIII": ("Waking & Sleeping", "Hello to the morning, goodnight to the day"),
    ]

    /// Section names for the Wise, in the language of a lifetime rather than of machines.
    static let wiseWords: [String: (title: String, subtitle: String)] = [
        "I": ("Breath & Pace", "Letting the body slow to the speed of the breath"),
        "II": ("The Senses", "Returning to simple seeing, hearing, touch, smell, and taste"),
        "III": ("Open Space", "The quiet space beneath thoughts and plans"),
        "IV": ("Feelings & Freedom", "Meeting hurry, anger, and longing as sensation"),
        "V": ("Inner Sound", "Sound and vibration as doorways to stillness"),
        "VI": ("Body & Ground", "Coming back to weight, bone, breath, and skin"),
        "VII": ("Awareness Itself", "The awareness that watches all the thinking"),
        "VIII": ("Sleep & Thresholds", "Thresholds of waking, sleeping, and changing"),
        "IX": ("One Field", "One field: the room, the world, the heart"),
    ]
}

extension DharanaSection.Practice {
    /// Kids and Wise breathe without holds; kids also keep it short.
    func adapted(for persona: Persona) -> DharanaSection.Practice {
        switch persona {
        case .kids:
            .init(inhale: 3, holdFull: 0, exhale: 4, holdEmpty: 0, minutes: min(minutes, 3))
        case .wise:
            .init(inhale: 4, holdFull: 0, exhale: max(exhale, 6), holdEmpty: 0, minutes: minutes)
        case .teens, .adults:
            self
        }
    }
}

extension DharanaCollection {
    /// The collection for a persona: their gates in their words, at their rhythm.
    /// With `keepingAll`, every gate stays (reworded and re-paced where possible), for
    /// places that name a gate directly, like reminders and courses.
    func adapted(for persona: Persona, keepingAll: Bool = false) -> DharanaCollection {
        var collection = self
        collection.sections = sections
            .map { $0.adapted(for: persona, keepingAll: keepingAll) }
            .filter { !$0.dharanas.isEmpty }
        // The title counts what this persona actually sees.
        let count = collection.sections.reduce(0) { $0 + $1.dharanas.count }
        switch persona {
        case .kids:
            collection.title = "Little Practices"
            collection.subtitle = "Gentle ways to notice your breath, your body, and the world around you"
            collection.attribution += "\n\nThese are the gentlest of the gates, retold in words for children."
        case .wise:
            if !keepingAll { collection.title = "\(count) Gates" }
            collection.subtitle = "Ancient ways of resting attention, for a quiet, unhurried life"
            collection.attribution += "\n\nHere the gates are retold in everyday language, without screens or machines."
        case .teens:
            if !keepingAll { collection.title = "\(count) Gates" }
            collection.subtitle = "Short practices for focus and calm, from an ancient tradition"
            collection.attribution += "\n\nHere the gates are retold in plain words for teens."
        case .adults:
            break
        }
        return collection
    }
}
