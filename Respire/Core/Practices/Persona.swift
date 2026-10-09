//
//  Persona.swift
//  Respire
//
//  Who's breathing. Each persona has its own guided sessions, a voice paced for it,
//  and its own limits: no breath holds for children or for the Wise, short sessions
//  for children, and everything seated and unforced for older bodies.
//

import Foundation

nonisolated enum Persona: String, CaseIterable, Identifiable, Sendable {
    case kids, teens, adults, wise

    static let storageKey = "persona"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kids: "Kids"
        case .teens: "Teens"
        case .adults: "Adults"
        case .wise: "Wise"
        }
    }

    var subtitle: String {
        switch self {
        case .kids: "Ages 5 to 11. Short, playful, and gentle."
        case .teens: "Ages 12 to 17. For stress, sleep, and exams."
        case .adults: "Calm, connection, and classic pranayama."
        case .wise: "60 and over. Gentle, seated, and unhurried."
        }
    }

    var symbol: String {
        switch self {
        case .kids: "teddybear"
        case .teens: "headphones"
        case .adults: "person"
        case .wise: "leaf"
        }
    }

    /// How fast the voice speaks, as a share of the default speech rate.
    var voiceRate: Float {
        switch self {
        case .kids: 0.84
        case .teens: 0.86
        case .adults: 0.8
        case .wise: 0.72
        }
    }

    /// A little brighter for children, a little lower for adults and the Wise.
    var voicePitch: Float {
        switch self {
        case .kids: 1.06
        case .teens: 1.0
        case .adults: 0.92
        case .wise: 0.9
        }
    }

    /// The saved choice; adults unless set.
    static var current: Persona {
        UserDefaults.standard.string(forKey: storageKey).flatMap(Persona.init(rawValue:)) ?? .adults
    }
}
