//
//  PlacePersonas.swift
//  Respire
//
//  Which Places and scenes suit whom. Children get the gentle, magical places and no
//  storms or volcanoes; teens the adventurous and reflective ones; the Wise the calm,
//  homely ones; adults everything. A few places speak differently to children: the
//  Paper Boat Canal lets go of child-sized worries.
//

import Foundation

extension Place {
    /// Who this place is for.
    var personas: Set<Persona> {
        switch id {
        case "dream-station", "cloud-ferry", "deep-sea", "observatory", "firefly-meadow", "lantern-bridge":
            [.kids, .teens, .adults, .wise]
        case "rain-station", "snow-cabin":
            [.kids, .teens, .adults, .wise]
        case "moth-garden", "greenhouse":
            [.kids, .adults, .wise]
        case "paper-boats":
            [.kids, .teens, .adults]
        case "bowl-temple", "cabin-falls":
            [.kids, .adults, .wise]
        case "root-tree":
            [.teens, .adults]
        case "lighthouse", "night-library", "hut-window":
            [.teens, .adults, .wise]
        case "tea-house", "moon-gates", "waterfall-house", "ocean-postbox":
            [.adults, .wise]
        default:
            [.adults]
        }
    }

    static func places(for persona: Persona) -> [Place] {
        all.filter { $0.personas.contains(persona) }
    }

    /// A different place each day, from those that suit this persona.
    static func placeOfTheDay(for date: Date = .now, persona: Persona) -> Place {
        let suited = places(for: persona)
        guard !suited.isEmpty else { return placeOfTheDay(for: date) }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return suited[day % suited.count]
    }

    /// The mechanic in this persona's words: children let go of child-sized things.
    func mechanic(for persona: Persona) -> Mechanic {
        guard persona == .kids, case .release(let items) = mechanic else { return mechanic }
        switch id {
        case "paper-boats":
            return .release(items: ["A grumpy feeling", "A worry", "Something that went wrong", "Feeling tired", "A wobbly feeling"])
        default:
            return .release(items: items)
        }
    }

    /// How much longer the out-breath may grow over a visit, and its longest length.
    /// Children and the Wise lengthen only a little.
    static func lengthening(for persona: Persona) -> (most: Double, ceiling: Double) {
        switch persona {
        case .kids: (1, 7)
        case .wise: (1, 8)
        case .teens, .adults: (2, 8)
        }
    }
}

extension BreathTheme {
    /// Who this scene is for. Storms and volcanoes are left out for children.
    var personas: Set<Persona> {
        switch self {
        case .thunder, .volcano: [.teens, .adults, .wise]
        default: Set(Persona.allCases)
        }
    }

    static func scenes(for persona: Persona) -> [BreathTheme] {
        allCases.filter { $0.personas.contains(persona) }
    }
}
