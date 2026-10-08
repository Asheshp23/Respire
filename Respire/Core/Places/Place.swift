//
//  Place.swift
//  Respire
//
//  Places: short, illustrated destinations you breathe your way through. Each one
//  announces your arrival ("You are now arriving at… Rain Station"), then moves one
//  step per breath:
//
//  - stages   named levels or stops ("Level 2: Steady rain")
//  - find     something revealed each breath ("You have now found 2/4 moths")
//  - counter  quiet time kept ("You have been here for… 30 seconds")
//
//  Every Place breathes at an easy, longer out-breath and lasts about a minute,
//  which makes them the gentlest way in for anyone new.
//

import SwiftUI

struct Place: Identifiable, Hashable {
    enum Mechanic: Hashable {
        case stages([String])
        case find(count: Int, verb: String, noun: String)
        case counter(breaths: Int)
    }

    let id: String
    let title: String
    /// The line that welcomes you: "You are now arriving at…".
    let arrival: String
    let summary: String
    let symbol: String
    let mechanic: Mechanic
    /// The world whose nature sound plays here.
    let sound: BreathTheme
    /// An accent for labels, drawn from the place's own palette.
    let tint: Color
    var inhale: Double = 4
    var exhale: Double = 6

    /// One step per breath.
    var steps: Int {
        switch mechanic {
        case .stages(let names): names.count
        case .find(let count, _, _): count
        case .counter(let breaths): breaths
        }
    }

    var pattern: BreathPattern {
        BreathPattern(id: "place.\(id)", name: title, summary: summary,
                      inhale: inhale, holdFull: 0, exhale: exhale, holdEmpty: 0)
    }

    var duration: TimeInterval { Double(steps) * (inhale + exhale) }

    /// "About 1 minute".
    var durationLabel: String {
        let minutes = max(1, Int((duration / 60).rounded()))
        return minutes == 1 ? "About 1 minute" : "About \(minutes) minutes"
    }

    var mechanicLabel: String {
        switch mechanic {
        case .stages(let names): "\(names.count) stages"
        case .find(let count, _, let noun): "Find \(count) \(noun)"
        case .counter: "Time, gently kept"
        }
    }
}

/// What a Place drawing needs for one frame.
struct PlaceFrame {
    /// Breaths so far, fractional (0 … steps).
    var progress: Double
    var steps: Int
    /// Lung volume, 0 empty … 1 full.
    var openness: Double
    var time: Double

    /// The step you're in now (0-based), held at the last one once finished.
    var stage: Int { min(max(Int(progress), 0), max(steps - 1, 0)) }
    /// How many steps are complete.
    var completed: Int { min(max(Int(progress), 0), steps) }
    /// Progress through the whole place, 0 … 1.
    var fraction: Double { steps > 0 ? min(max(progress / Double(steps), 0), 1) : 0 }

    static func still(steps: Int, at fraction: Double = 0.5) -> PlaceFrame {
        PlaceFrame(progress: Double(steps) * fraction, steps: steps, openness: 0.6, time: 3)
    }
}

// MARK: - Catalog

extension Place {
    static let all: [Place] = [
        Place(id: "dream-station", title: "Dream State Station", arrival: "You are now arriving at…",
              summary: "A night train through firefly woods", symbol: "tram",
              mechanic: .stages(["Fern Hollow", "Firefly Junction", "Moss Bridge", "Starlight Siding", "Dream State"]),
              sound: .aurora, tint: Color(red: 0.86, green: 0.82, blue: 0.45), exhale: 7),
        Place(id: "rain-station", title: "Rain Station", arrival: "You have now arrived at a…",
              summary: "Platforms of rain, one breath each", symbol: "cloud.rain",
              mechanic: .stages(["Light rain", "Steady rain", "Heavy rain", "Passing rain", "After the rain"]),
              sound: .rain, tint: Color(red: 0.95, green: 0.78, blue: 0.55)),
        Place(id: "waterfall-house", title: "Waterfall House", arrival: "You have been here for…",
              summary: "Water pours down through every floor", symbol: "house",
              mechanic: .stages(["Level one", "Level two", "Level three", "Level four"]),
              sound: .waterfall, tint: Color(red: 0.36, green: 0.66, blue: 0.6)),
        Place(id: "cabin-falls", title: "The Sound of the Waterfall", arrival: "Listen to…",
              summary: "A cabin, a pool, a long fall of water", symbol: "drop",
              mechanic: .counter(breaths: 6),
              sound: .waterfall, tint: Color(red: 0.4, green: 0.65, blue: 0.58)),
        Place(id: "moth-garden", title: "Moth Garden", arrival: "In the dark leaves…",
              summary: "Four moths rest on the garden wires", symbol: "leaf",
              mechanic: .find(count: 4, verb: "found", noun: "moths"),
              sound: .wind, tint: Color(red: 0.95, green: 0.7, blue: 0.3)),
        Place(id: "root-tree", title: "The Root Tree", arrival: "You are now entering…",
              summary: "Down through the roots into the rain below", symbol: "tree",
              mechanic: .stages(["Light rain", "Steady rain", "Heavy rain", "Deep roots", "The quiet below"]),
              sound: .rain, tint: Color(red: 0.55, green: 0.75, blue: 1)),
        Place(id: "lighthouse", title: "Lighthouse Stairs", arrival: "You are now climbing…",
              summary: "Five landings up to the turning light", symbol: "light.beacon.max",
              mechanic: .stages(["First landing", "Second landing", "Third landing", "Fourth landing", "The lamp room"]),
              sound: .ocean, tint: Color(red: 1, green: 0.85, blue: 0.55)),
        Place(id: "tea-house", title: "Tea House", arrival: "You are now sitting in a…",
              summary: "Steam on the out-breath, a cup each breath", symbol: "cup.and.saucer",
              mechanic: .find(count: 5, verb: "poured", noun: "cups"),
              sound: .rain, tint: Color(red: 0.6, green: 0.45, blue: 0.3)),
        Place(id: "night-library", title: "Night Library", arrival: "You have now wandered into the…",
              summary: "Light one shelf with every breath", symbol: "books.vertical",
              mechanic: .find(count: 6, verb: "lit", noun: "shelves"),
              sound: .desert, tint: Color(red: 1, green: 0.75, blue: 0.4)),
        Place(id: "lantern-bridge", title: "Lantern Bridge", arrival: "You are now crossing the…",
              summary: "A lantern lit for each breath across the river", symbol: "lamp.table",
              mechanic: .find(count: 6, verb: "lit", noun: "lanterns"),
              sound: .ocean, tint: Color(red: 1, green: 0.68, blue: 0.35)),
        Place(id: "snow-cabin", title: "Snow Cabin", arrival: "You have now arrived at the…",
              summary: "Snow settles, the fire slowly catches", symbol: "snowflake",
              mechanic: .stages(["First flakes", "Snow settling", "Fire catching", "Warm and still"]),
              sound: .wind, tint: Color(red: 0.75, green: 0.85, blue: 1), exhale: 7),
        Place(id: "deep-sea", title: "Deep Sea Elevator", arrival: "You are now descending in the…",
              summary: "Each breath a little deeper and quieter", symbol: "water.waves",
              mechanic: .stages(["The surface", "Twilight zone", "Midnight zone", "The quiet deep", "The sea floor"]),
              sound: .ocean, tint: Color(red: 0.4, green: 0.8, blue: 0.95), exhale: 7),
        Place(id: "observatory", title: "Star Observatory", arrival: "The dome opens at the…",
              summary: "A constellation appears each breath", symbol: "moon.stars",
              mechanic: .find(count: 5, verb: "found", noun: "constellations"),
              sound: .desert, tint: Color(red: 0.7, green: 0.75, blue: 1)),
        Place(id: "cloud-ferry", title: "Cloud Ferry", arrival: "You are now boarding the…",
              summary: "Drifting island to island above the sky", symbol: "cloud",
              mechanic: .stages(["Cirrus Point", "Cumulus Isle", "Nimbus Bay", "Stratus Shore", "Home Cloud"]),
              sound: .wind, tint: Color(red: 1, green: 0.75, blue: 0.7)),
        Place(id: "greenhouse", title: "Greenhouse", arrival: "You have now stepped into the…",
              summary: "A seed blooms open with every breath", symbol: "camera.macro",
              mechanic: .find(count: 5, verb: "bloomed", noun: "flowers"),
              sound: .rain, tint: Color(red: 0.6, green: 0.85, blue: 0.55)),
        Place(id: "paper-boats", title: "Paper Boat Canal", arrival: "Down at the water of the…",
              summary: "Set a paper boat sailing each out-breath", symbol: "sailboat",
              mechanic: .find(count: 5, verb: "sailed", noun: "boats"),
              sound: .rain, tint: Color(red: 0.95, green: 0.9, blue: 0.8)),
        Place(id: "hut-window", title: "Mountain Hut Window", arrival: "You are now looking out the…",
              summary: "Weather passes the window, breath by breath", symbol: "window.casement",
              mechanic: .stages(["Clear morning", "Drifting fog", "Soft rain", "Snowfall", "Starry night"]),
              sound: .wind, tint: Color(red: 0.85, green: 0.65, blue: 0.45)),
        Place(id: "firefly-meadow", title: "Firefly Meadow", arrival: "You are now resting in the…",
              summary: "More fireflies glow with every breath", symbol: "sparkles",
              mechanic: .counter(breaths: 6),
              sound: .wind, tint: Color(red: 0.85, green: 0.95, blue: 0.4)),
        Place(id: "moon-gates", title: "Moon Garden Gates", arrival: "You are now walking through the…",
              summary: "Four round gates, one opening each breath", symbol: "circle.circle",
              mechanic: .stages(["Gate of breath", "Gate of sound", "Gate of body", "Gate of space"]),
              sound: .sakura, tint: Color(red: 0.95, green: 0.85, blue: 0.95), exhale: 7),
        Place(id: "ocean-postbox", title: "Ocean Postbox", arrival: "At the end of the pier, an…",
              summary: "Let a letter go on every out-breath", symbol: "envelope",
              mechanic: .find(count: 5, verb: "sent", noun: "letters"),
              sound: .ocean, tint: Color(red: 0.95, green: 0.55, blue: 0.5)),
        Place(id: "bowl-temple", title: "Singing Bowl Temple", arrival: "You are now entering the…",
              summary: "Ring one bowl on every out-breath", symbol: "dot.radiowaves.left.and.right",
              mechanic: .find(count: 7, verb: "rung", noun: "bowls"),
              sound: .cymatics, tint: Color(red: 0.94, green: 0.8, blue: 0.5), exhale: 7),
    ]

    static func place(id: String) -> Place? { all.first { $0.id == id } }

    /// A different place each day, walking through them all.
    static func placeOfTheDay(for date: Date = .now) -> Place {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return all[day % all.count]
    }
}
