//
//  SolfeggioTone.swift
//  Respire
//
//  The nine solfeggio tones, one for each world, plus "match the scene". Offered as
//  a listening experience in an old tuning tradition. Respire makes no claims about
//  what they do to the body.
//

import SwiftUI

enum SolfeggioTone: String, CaseIterable, Identifiable {
    case off, scene
    case hz174, hz285, hz396, hz417, hz528, hz639, hz741, hz852, hz963

    static let storageKey = "sound.tone"

    /// The nine tones, low to high.
    static let tones: [SolfeggioTone] = [.hz174, .hz285, .hz396, .hz417, .hz528, .hz639, .hz741, .hz852, .hz963]

    var id: String { rawValue }

    var hertz: Double {
        switch self {
        case .off, .scene: 0
        case .hz174: 174
        case .hz285: 285
        case .hz396: 396
        case .hz417: 417
        case .hz528: 528
        case .hz639: 639
        case .hz741: 741
        case .hz852: 852
        case .hz963: 963
        }
    }

    /// The quality the tradition gives each tone.
    var quality: String {
        switch self {
        case .off: "Silence"
        case .scene: "Each world's own"
        case .hz174: "Grounding"
        case .hz285: "Renewal"
        case .hz396: "Letting go"
        case .hz417: "Change"
        case .hz528: "Warmth"
        case .hz639: "Connection"
        case .hz741: "Clarity"
        case .hz852: "Intuition"
        case .hz963: "Oneness"
        }
    }

    /// The tone each world carries when matching the scene.
    static func tone(for theme: BreathTheme) -> SolfeggioTone {
        switch theme {
        case .thunder: .hz174
        case .waterfall: .hz285
        case .volcano: .hz396
        case .rain: .hz417
        case .sakura: .hz528
        case .ocean: .hz639
        case .wind: .hz741
        case .desert: .hz852
        case .aurora: .hz963
        // The tone most often sung to water.
        case .cymatics: .hz528
        // Daylight scenes carry the tone of the world they borrow their sound from.
        case .meadow, .alpine, .seaside, .garden, .forest, .lake: tone(for: theme.soundWorld)
        }
    }

    /// The frequency to play in this world; 0 for none.
    func frequency(for theme: BreathTheme) -> Double {
        self == .scene ? Self.tone(for: theme).hertz : hertz
    }

    /// Low tones warm, high tones cool: the prism, red to violet.
    var hue: Color {
        guard let index = Self.tones.firstIndex(of: self) else { return .white }
        let position = Double(index) / Double(Self.tones.count - 1) * Double(Theme.prism.count - 1)
        return Theme.prism[Int(position.rounded())]
    }
}

extension BreathTheme {
    /// What you hear in each world, for the sound settings.
    var natureSound: String {
        switch self {
        case .aurora: "A soft, breathing drone and faint air"
        case .ocean: "Surf that swells as you breathe in"
        case .sakura: "A light breeze and wind chimes"
        case .desert: "A whisper of wind and a crackling candle"
        case .waterfall: "Steady falling water"
        case .volcano: "A deep rumble and ember crackle"
        case .rain: "Rain on the pond, softer as you breathe out"
        case .wind: "Gusts that rise with the in-breath"
        case .thunder: "Rain, and thunder rolling far away"
        case .cymatics: "A singing bowl, humming as you breathe"
        case .meadow, .forest: "A warm breeze through the grass and trees"
        case .alpine: "Cool mountain air"
        case .seaside, .lake: "Gentle waves lapping"
        case .garden: "A light breeze and wind chimes"
        }
    }
}
