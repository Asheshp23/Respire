//
//  Anchor.swift
//  Respire
//
//  Anchors: a minute that points you away from the screen, to something every person
//  shares. Each is one sense and one true wonder: the sky, old starlight, the ground,
//  your heartbeat, water, the air. An invitation to notice something real, a few breaths
//  with the screen dimmed and eyes elsewhere, then a quiet fact to come back to.
//
//  The words are plain on purpose, the same for a child and a grandparent: awe is common.
//

import Foundation

struct Anchor: Identifiable, Hashable {
    enum Sense: String {
        case sight, sound, touch, smell, taste, body, breath

        var symbol: String {
            switch self {
            case .sight: "eye"
            case .sound: "ear"
            case .touch: "hand.raised"
            case .smell: "nose"
            case .taste: "drop"
            case .body: "figure.stand"
            case .breath: "wind"
            }
        }

        var title: String {
            switch self {
            case .sight: "Seeing"
            case .sound: "Hearing"
            case .touch: "Touch"
            case .smell: "Smell"
            case .taste: "Taste"
            case .body: "Body"
            case .breath: "Breath"
            }
        }
    }

    /// When an anchor can be found: the sky needs daylight, starlight needs night.
    enum When {
        case day, night, any

        func fits(hour: Int) -> Bool {
            switch self {
            case .day: (7..<19).contains(hour)
            case .night: hour >= 19 || hour < 6
            case .any: true
            }
        }
    }

    let id: String
    let title: String
    let sense: Sense
    let when: When
    /// What to do, in one plain line: spoken, then shown as you look away.
    let invitation: String
    /// A true thing to come back to.
    let wonder: String
    /// Breaths with the screen dimmed; about ten seconds each.
    var breaths = 5

    static func anchor(id: String) -> Anchor? { all.first { $0.id == id } }

    /// The anchor for this hour, a different one through the day and from day to day.
    static func ofTheMoment(at date: Date = .now, calendar: Calendar = .current) -> Anchor {
        let hour = calendar.component(.hour, from: date)
        let fitting = all.filter { $0.when.fits(hour: hour) }
        let pool = fitting.isEmpty ? all : fitting
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        // A new one every four hours, so morning, afternoon, and evening each bring their own.
        return pool[(day * 6 + hour / 4) % pool.count]
    }

    static let all: [Anchor] = [
        Anchor(id: "sky", title: "The Sky Above You", sense: .sight, when: .day,
               invitation: "Look up at the sky. Find the farthest thing you can see.",
               wonder: "The sky looks blue because air scatters blue sunlight more than any other color. You're looking up through about a hundred kilometers of it."),
        Anchor(id: "cloud", title: "A Passing Cloud", sense: .sight, when: .day,
               invitation: "Find one cloud, and watch it change until it's not quite the same cloud.",
               wonder: "Even a small, fluffy cloud holds hundreds of tonnes of water, floating above you on rising air."),
        Anchor(id: "starlight", title: "Old Light", sense: .sight, when: .night,
               invitation: "Look at the night sky, or out of a window, and find one point of light.",
               wonder: "Starlight is old. The light from many stars you can see left them hundreds of years ago, long before you were born."),
        Anchor(id: "sunlight", title: "Sunlight on You", sense: .touch, when: .day,
               invitation: "Find sunlight, on your skin or through a window, and feel its warmth.",
               wonder: "That light left the sun about eight minutes ago, and crossed a hundred and fifty million kilometers to reach you."),
        Anchor(id: "shadow", title: "Light and Shadow", sense: .sight, when: .day,
               invitation: "Find a shadow. Notice its edges, soft or sharp, and the light around it.",
               wonder: "Every shadow is moving, slowly, as the Earth turns toward evening."),
        Anchor(id: "ground", title: "The Ground Holding You", sense: .body, when: .any,
               invitation: "Feel where your body meets the ground or the chair, and let it hold your whole weight.",
               wonder: "The ground under you is spinning with the Earth, in places faster than sixteen hundred kilometers an hour, and you feel perfectly still.",
               breaths: 6),
        Anchor(id: "farthest-sound", title: "The Farthest Sound", sense: .sound, when: .any,
               invitation: "Close your eyes. Listen for the farthest sound you can hear, then the nearest.",
               wonder: "Your hearing never fully switches off. Even while you sleep, your ears keep listening for you.",
               breaths: 6),
        Anchor(id: "heartbeat", title: "Your Heartbeat", sense: .body, when: .any,
               invitation: "Rest a hand on your chest or your wrist, and wait until you feel your heart.",
               wonder: "Your heart beats about a hundred thousand times a day, and it has never once needed you to remember.",
               breaths: 6),
        Anchor(id: "hands", title: "Your Hands", sense: .touch, when: .any,
               invitation: "Look at your hands slowly, as if for the first time. Move each finger.",
               wonder: "Each of your hands has twenty-seven bones. They have held everything you have ever held.",
               breaths: 4),
        Anchor(id: "water", title: "Water", sense: .taste, when: .any,
               invitation: "Take one slow sip of water, or run it over your hands. Feel how cool it is.",
               wonder: "The water in you has been rain, rivers, oceans, and clouds, over and over, for billions of years.",
               breaths: 4),
        Anchor(id: "shared-air", title: "Shared Air", sense: .breath, when: .any,
               invitation: "Breathe in slowly through your nose. Notice the air is cool going in, and warm coming out.",
               wonder: "About half the oxygen in this breath was made by tiny plants drifting in the ocean."),
        Anchor(id: "one-smell", title: "One Smell", sense: .smell, when: .any,
               invitation: "Breathe in gently, and find one smell in the air around you, however faint.",
               wonder: "Smell has a short path to the parts of the brain that keep memories, which is why a scent can bring back a whole day.",
               breaths: 4),
        Anchor(id: "something-alive", title: "Something Alive", sense: .sight, when: .any,
               invitation: "Find something living nearby, a plant, a tree, a bird, a person, and simply watch it.",
               wonder: "Everything alive around you is family, through one tree of life going back nearly four billion years."),
        Anchor(id: "stardust", title: "Made of Stars", sense: .body, when: .night,
               invitation: "Feel your whole body at once, from your feet to the top of your head.",
               wonder: "Most of the atoms in your body, apart from hydrogen, were made inside stars, long before the Earth existed.",
               breaths: 6),
    ]
}
