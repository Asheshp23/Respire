//
//  SessionFocus.swift
//  Respire
//

import Foundation

/// What the person wants from this session. Shapes the opening's imagery and intent.
nonisolated enum SessionFocus: String, CaseIterable, Identifiable, Sendable {
    case calmAnxiety
    case focus
    case windDown

    static let storageKey = "session.focus"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calmAnxiety: "Calm anxiety"
        case .focus: "Focus"
        case .windDown: "Wind down"
        }
    }

    var symbol: String {
        switch self {
        case .calmAnxiety: "leaf"
        case .focus: "scope"
        case .windDown: "moon.stars"
        }
    }

    /// The somatic intent, phrased for the language model and the template composer alike.
    var intent: String {
        switch self {
        case .calmAnxiety:
            "soften anxious activation: feel the support beneath the body, let the exhale lengthen, release the jaw, shoulders, and belly"
        case .focus:
            "gather scattered attention into one clear, steady point: spine long, eyes soft, alert but unhurried"
        case .windDown:
            "let the day go and move toward rest: heaviness, warmth, the body sinking, thoughts slowing"
        }
    }
}
