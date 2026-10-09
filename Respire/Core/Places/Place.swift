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
//  - release  one thing let go on each out-breath ("Let go of: the rush of today")
//
//  Every Place breathes at an easy, longer out-breath and lasts about a minute,
//  which makes them the gentlest way in for anyone new. Each names what it's for
//  (its psychological goal), and most are adaptive: the out-breath lengthens a
//  little with each breath, the way a body settles when it's given time.
//

import SwiftUI

struct Place: Identifiable, Hashable {
    enum Mechanic: Hashable {
        case stages([String])
        case find(count: Int, verb: String, noun: String)
        case counter(breaths: Int)
        /// One thing let go of on each out-breath, named in the person's own terms.
        case release(items: [String])
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
    /// What the visit is for, in a few plain words: "To soften and release".
    let psychologicalGoal: String
    var inhale: Double = 4
    var exhale: Double = 6
    /// Whether the out-breath gently lengthens over the visit.
    var isAdaptive = true

    /// One step per breath.
    var steps: Int {
        switch mechanic {
        case .stages(let names): names.count
        case .find(let count, _, _): count
        case .counter(let breaths): breaths
        case .release(let items): items.count
        }
    }

    /// The rhythm of the first breath.
    var pattern: BreathPattern { pattern(atBreath: 0) }

    /// The rhythm for breath `index` (0-based). Adaptive places hold the starting
    /// out-breath for two breaths, then add half a second each breath, up to two
    /// seconds more and never past eight unless they begin there.
    func pattern(atBreath index: Int) -> BreathPattern {
        BreathPattern(id: "place.\(id)", name: title, summary: summary,
                      inhale: inhale, holdFull: 0, exhale: exhale(atBreath: index), holdEmpty: 0)
    }

    /// Lengthening follows who's breathing: a little for children and the Wise, more for others.
    func exhale(atBreath index: Int, persona: Persona = .current) -> Double {
        guard isAdaptive else { return exhale }
        let limit = Place.lengthening(for: persona)
        let lengthening = min(Double(max(index - 1, 0)) * 0.5, limit.most)
        return min(exhale + lengthening, max(exhale, limit.ceiling))
    }

    /// The longest out-breath the visit reaches.
    var finalExhale: Double { exhale(atBreath: max(steps - 1, 0)) }

    var duration: TimeInterval { seconds(atProgress: Double(steps)) }

    /// Time breathed by `progress` breaths (fractional), following the lengthening out-breath.
    func seconds(atProgress progress: Double) -> TimeInterval {
        let whole = min(max(Int(progress), 0), steps)
        var total = (0..<whole).reduce(0.0) { $0 + inhale + exhale(atBreath: $1) }
        if whole < steps {
            total += (progress - Double(whole)) * (inhale + exhale(atBreath: whole))
        }
        return total
    }

    /// "in for 4, out for 6", or "in for 4, out for 6 easing to 8" when it lengthens.
    var rhythmDescription: String {
        let out = Int(exhale)
        let last = finalExhale
        guard last > exhale else { return "in for \(Int(inhale)), out for \(out)" }
        return "in for \(Int(inhale)), out for \(out) easing to \(last.formatted(.number.precision(.fractionLength(0...1))))"
    }

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
        case .release(let items): "Let go of \(items.count) things"
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
              sound: .aurora, tint: Color(red: 0.86, green: 0.82, blue: 0.45),
              psychologicalGoal: "To let the day drift into sleep", exhale: 7),
        Place(id: "rain-station", title: "Rain Station", arrival: "Step off the train, and arrive at…",
              summary: "Each breath carries you through softer rain", symbol: "cloud.rain",
              mechanic: .stages(["Light rain", "Steady rain", "Heavy rain", "Passing rain", "After the rain"]),
              sound: .rain, tint: Color(red: 0.95, green: 0.78, blue: 0.55),
              psychologicalGoal: "To soften as things slow down"),
        Place(id: "waterfall-house", title: "Waterfall House", arrival: "Feel the floor beneath you in the…",
              summary: "Water falls through every floor, and the tension falls with it", symbol: "house",
              mechanic: .stages(["Level one", "Level two", "Level three", "Level four"]),
              sound: .waterfall, tint: Color(red: 0.36, green: 0.66, blue: 0.6),
              psychologicalGoal: "To let tension fall away"),
        Place(id: "cabin-falls", title: "The Sound of the Waterfall", arrival: "Listen to…",
              summary: "Let the long fall of water carry the noise away", symbol: "drop",
              mechanic: .counter(breaths: 6),
              sound: .waterfall, tint: Color(red: 0.4, green: 0.65, blue: 0.58),
              psychologicalGoal: "To let the noise wash out"),
        Place(id: "moth-garden", title: "Moth Garden", arrival: "In the dark leaves…",
              summary: "Four moths rest on the garden wires", symbol: "leaf",
              mechanic: .find(count: 4, verb: "found", noun: "moths"),
              sound: .wind, tint: Color(red: 0.95, green: 0.7, blue: 0.3),
              psychologicalGoal: "To steady scattered attention"),
        Place(id: "root-tree", title: "The Root Tree", arrival: "Sink down, and rest beneath…",
              summary: "Follow the breath down into the roots, where it's quiet", symbol: "tree",
              mechanic: .stages(["Light rain", "Steady rain", "Heavy rain", "Deep roots", "The quiet below"]),
              sound: .rain, tint: Color(red: 0.55, green: 0.75, blue: 1),
              psychologicalGoal: "To feel grounded and held"),
        Place(id: "lighthouse", title: "Lighthouse Stairs", arrival: "You are now climbing…",
              summary: "Five landings up to the turning light", symbol: "light.beacon.max",
              mechanic: .stages(["First landing", "Second landing", "Third landing", "Fourth landing", "The lamp room"]),
              sound: .ocean, tint: Color(red: 1, green: 0.85, blue: 0.55),
              psychologicalGoal: "To gather focus, step by step"),
        Place(id: "tea-house", title: "Tea House", arrival: "Warm your hands, and settle into the…",
              summary: "A cup for each breath, steam rising as you breathe out", symbol: "cup.and.saucer",
              mechanic: .find(count: 5, verb: "poured", noun: "cups"),
              sound: .rain, tint: Color(red: 0.6, green: 0.45, blue: 0.3),
              psychologicalGoal: "To slow down and warm up"),
        Place(id: "night-library", title: "Night Library", arrival: "You have now wandered into the…",
              summary: "Light one shelf with every breath", symbol: "books.vertical",
              mechanic: .find(count: 6, verb: "lit", noun: "shelves"),
              sound: .desert, tint: Color(red: 1, green: 0.75, blue: 0.4),
              psychologicalGoal: "To quiet a busy mind"),
        Place(id: "lantern-bridge", title: "Lantern Bridge", arrival: "You are now crossing the…",
              summary: "A lantern lit for each breath across the river", symbol: "lamp.table",
              mechanic: .find(count: 6, verb: "lit", noun: "lanterns"),
              sound: .ocean, tint: Color(red: 1, green: 0.68, blue: 0.35),
              psychologicalGoal: "To find your way through worry"),
        Place(id: "snow-cabin", title: "Snow Cabin", arrival: "Come in from the cold, to the…",
              summary: "Snow settles outside as the fire warms you through", symbol: "snowflake",
              mechanic: .stages(["First flakes", "Snow settling", "Fire catching", "Warm and still"]),
              sound: .wind, tint: Color(red: 0.75, green: 0.85, blue: 1),
              psychologicalGoal: "To feel safe and warm", exhale: 7),
        Place(id: "deep-sea", title: "Deep Sea Elevator", arrival: "Let yourself sink, slowly, in the…",
              summary: "Each breath takes you deeper into quiet water", symbol: "water.waves",
              mechanic: .stages(["The surface", "Twilight zone", "Midnight zone", "The quiet deep", "The sea floor"]),
              sound: .ocean, tint: Color(red: 0.4, green: 0.8, blue: 0.95),
              psychologicalGoal: "To sink below racing thoughts", exhale: 7),
        Place(id: "observatory", title: "Star Observatory", arrival: "The dome opens at the…",
              summary: "A constellation appears each breath", symbol: "moon.stars",
              mechanic: .find(count: 5, verb: "found", noun: "constellations"),
              sound: .desert, tint: Color(red: 0.7, green: 0.75, blue: 1),
              psychologicalGoal: "To widen your view"),
        Place(id: "cloud-ferry", title: "Cloud Ferry", arrival: "You are now boarding the…",
              summary: "Drifting island to island above the sky", symbol: "cloud",
              mechanic: .stages(["Cirrus Point", "Cumulus Isle", "Nimbus Bay", "Stratus Shore", "Home Cloud"]),
              sound: .wind, tint: Color(red: 1, green: 0.75, blue: 0.7),
              psychologicalGoal: "To feel lighter"),
        Place(id: "greenhouse", title: "Greenhouse", arrival: "You have now stepped into the…",
              summary: "A seed blooms open with every breath", symbol: "camera.macro",
              mechanic: .find(count: 5, verb: "bloomed", noun: "flowers"),
              sound: .rain, tint: Color(red: 0.6, green: 0.85, blue: 0.55),
              psychologicalGoal: "To grow a little patience"),
        Place(id: "paper-boats", title: "Paper Boat Canal", arrival: "Kneel by the water of the…",
              summary: "Fold what's heavy into paper boats, and let them drift", symbol: "sailboat",
              mechanic: .release(items: ["Racing thoughts", "The to-do list", "An old argument", "Worry about tomorrow", "The weight of the day"]),
              sound: .rain, tint: Color(red: 0.95, green: 0.9, blue: 0.8),
              psychologicalGoal: "To let worries float away"),
        Place(id: "hut-window", title: "Mountain Hut Window", arrival: "You are now looking out the…",
              summary: "Weather passes the window, breath by breath", symbol: "window.casement",
              mechanic: .stages(["Clear morning", "Drifting fog", "Soft rain", "Snowfall", "Starry night"]),
              sound: .wind, tint: Color(red: 0.85, green: 0.65, blue: 0.45),
              psychologicalGoal: "To watch feelings pass like weather"),
        Place(id: "firefly-meadow", title: "Firefly Meadow", arrival: "Lie back in the long grass of the…",
              summary: "Fireflies gather as your body grows still", symbol: "sparkles",
              mechanic: .counter(breaths: 6),
              sound: .wind, tint: Color(red: 0.85, green: 0.95, blue: 0.4),
              psychologicalGoal: "To rest in stillness"),
        Place(id: "moon-gates", title: "Moon Garden Gates", arrival: "You are now walking through the…",
              summary: "Four round gates, one opening each breath", symbol: "circle.circle",
              mechanic: .stages(["Gate of breath", "Gate of sound", "Gate of body", "Gate of space"]),
              sound: .sakura, tint: Color(red: 0.95, green: 0.85, blue: 0.95),
              psychologicalGoal: "To move gently from noise to quiet", exhale: 7),
        Place(id: "ocean-postbox", title: "Ocean Postbox", arrival: "At the end of the pier, an…",
              summary: "Post what weighs on you out to sea, one letter each out-breath", symbol: "envelope",
              mechanic: .release(items: ["The rush of today", "What didn't get done", "Someone else's mood", "The tightness in your shoulders", "Needing it to be perfect"]),
              sound: .ocean, tint: Color(red: 0.95, green: 0.55, blue: 0.5),
              psychologicalGoal: "To soften and release"),
        Place(id: "bowl-temple", title: "Singing Bowl Temple", arrival: "You are now entering the…",
              summary: "Ring one bowl on every out-breath", symbol: "dot.radiowaves.left.and.right",
              mechanic: .find(count: 7, verb: "rung", noun: "bowls"),
              sound: .cymatics, tint: Color(red: 0.94, green: 0.8, blue: 0.5),
              psychologicalGoal: "To settle into sound", exhale: 7),
    ]

    static func place(id: String) -> Place? { all.first { $0.id == id } }

    /// A different place each day, walking through them all.
    static func placeOfTheDay(for date: Date = .now) -> Place {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return all[day % all.count]
    }
}
