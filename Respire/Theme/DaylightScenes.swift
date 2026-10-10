//
//  DaylightScenes.swift
//  Respire
//
//  The bright scenes, and the scene that follows the day. Daylight scenes are the
//  daytime Places with everything already arrived (every kite up, every bird come),
//  breathing gently with you. "Automatic" picks a scene for the hour: daylight in the
//  morning and afternoon, dusk in the evening, night after dark, a different one each day.
//

import SwiftUI

extension BreathTheme {
    static let daylight: [BreathTheme] = [.meadow, .alpine, .seaside, .garden, .forest, .lake]
    private static let dusk: [BreathTheme] = [.ocean, .sakura, .wind, .waterfall]
    private static let night: [BreathTheme] = [.aurora, .desert, .rain, .sakura]

    var isDaylight: Bool { Self.daylight.contains(self) }

    /// The Place a daylight scene is drawn from.
    var daylightPlaceID: String? {
        switch self {
        case .meadow: "kite-hill"
        case .alpine: "alpine-lake"
        case .seaside: "seaside-promenade"
        case .garden: "garden-bench"
        case .forest: "forest-trail"
        case .lake: "morning-dock"
        default: nil
        }
    }

    /// The world whose nature sound plays: daylight scenes borrow the closest one.
    var soundWorld: BreathTheme {
        switch self {
        case .meadow, .alpine, .forest: .wind
        case .seaside, .lake: .ocean
        case .garden: .sakura
        default: self
        }
    }

    /// The setting: whether the scene follows the time of day. On unless a scene is chosen.
    static let automaticKey = "scene.automatic"

    /// The scene to show now: the hour's own when Automatic, else the one chosen (if it
    /// suits whoever's breathing).
    static func current(at date: Date = .now, persona: Persona = .current, defaults: UserDefaults = .standard) -> BreathTheme {
        let isAutomatic = defaults.object(forKey: automaticKey) as? Bool ?? true
        let chosen = defaults.string(forKey: storageKey).flatMap(BreathTheme.init(rawValue:))
        guard !isAutomatic, let chosen, chosen.personas.contains(persona) else {
            return ofTheMoment(at: date, persona: persona)
        }
        return chosen
    }

    /// The scene for this hour and day, among those that suit whoever's breathing.
    static func ofTheMoment(at date: Date = .now, persona: Persona = .current, calendar: Calendar = .current) -> BreathTheme {
        let band: [BreathTheme] = switch calendar.component(.hour, from: date) {
        case 6..<17: daylight
        case 17..<20: dusk
        default: night
        }
        let suited = band.filter { $0.personas.contains(persona) }
        guard !suited.isEmpty else { return .aurora }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return suited[day % suited.count]
    }
}

/// A daylight scene, breathing: its Place fully arrived, moving with the breath.
struct DaylightScene: View {
    let theme: BreathTheme
    var openness: Double
    var time: Double
    /// How much of the Place has arrived, 0…1; `nil` is everything (the lake keeps some mist).
    var arrived: Double?

    var body: some View {
        if let place = theme.daylightPlaceID.flatMap({ Place.place(id: $0) }) {
            let arrived = arrived ?? (theme == .lake ? 0.4 : 1)
            PlaceCanvas(place: place, frame: PlaceFrame(
                progress: Double(place.steps) * arrived, steps: place.steps, openness: openness, time: time))
        }
    }
}

#Preview("Daylight scenes") {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
        ForEach(BreathTheme.daylight) { theme in
            ThemeBackdrop(theme: theme)
                .frame(height: 220)
                .overlay(alignment: .bottomLeading) {
                    Text(theme.title).font(.caption.bold()).foregroundStyle(.white).padding(6)
                }
                .clipped()
        }
    }
    .background(.black)
}
