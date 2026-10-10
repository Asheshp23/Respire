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
        // The daytime places.
        case "kite-hill", "rainbow-pond":
            [.kids, .adults]
        case "garden-bench", "seaside-promenade":
            [.kids, .adults, .wise]
        case "rooftop-sunrise":
            [.teens, .adults]
        case "forest-trail", "morning-dock", "alpine-lake":
            [.teens, .adults, .wise]
        default:
            [.adults]
        }
    }

    /// The places that suit a persona, its own favorites first.
    static func places(for persona: Persona) -> [Place] {
        let suited = all.filter { $0.personas.contains(persona) }
        let first = featured(for: persona)
        return suited.filter { first.contains($0.id) }.sorted { (first.firstIndex(of: $0.id) ?? 0) < (first.firstIndex(of: $1.id) ?? 0) }
            + suited.filter { !first.contains($0.id) }
    }

    /// The places made with each persona in mind, so they lead the shelf.
    private static func featured(for persona: Persona) -> [String] {
        switch persona {
        case .kids: ["kite-hill", "rainbow-pond", "garden-bench", "seaside-promenade"]
        case .teens: ["rooftop-sunrise", "forest-trail", "alpine-lake", "morning-dock"]
        case .adults: ["morning-dock", "alpine-lake", "forest-trail", "seaside-promenade"]
        case .wise: ["garden-bench", "seaside-promenade", "morning-dock", "alpine-lake"]
        }
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
