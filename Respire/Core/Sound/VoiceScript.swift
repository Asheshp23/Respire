//
//  VoiceScript.swift
//  Respire
//
//  Everything the voice says, in one place, so it reads like the script it is.
//  Plain words, said slowly, with room between them: a settling-in, the first two
//  breaths counted through, three quiet reminders spread across the session, a cue
//  for the last breath, and a closing that brings you back. Written for each focus.
//

import Foundation

/// One spoken line and the silence after it, in seconds.
struct VoiceLine {
    let text: String
    var pause: Double = 2
}

enum VoiceScript {
    // MARK: Settling in

    /// The settling-in. `brief` is for people who've heard the full one a few times already:
    /// a welcome back, the one line about this session, and straight in.
    static func intro(focus: SessionFocus, minutes: Int?, guidance: String?, breathSound: Bool, brief: Bool = false) -> [VoiceLine] {
        if brief {
            var lines = [
                VoiceLine(text: "Welcome back.", pause: 1),
                VoiceLine(text: "Get comfortable, and close your eyes when you're ready.", pause: 3),
            ]
            if let guidance, !guidance.isEmpty {
                lines.append(VoiceLine(text: guidance, pause: 2))
            }
            lines.append(VoiceLine(text: "Let's begin.", pause: 1))
            return lines
        }
        var lines: [VoiceLine] = [
            VoiceLine(text: "Welcome.", pause: 1.5),
            VoiceLine(text: "Find a position that feels comfortable. Sitting or lying down are both fine."),
            VoiceLine(text: "Let your hands rest wherever they're easy."),
            VoiceLine(text: "And when you're ready, gently close your eyes.", pause: 4),
            VoiceLine(text: "Notice where your body is supported. The floor, the chair, or the bed beneath you.", pause: 3),
        ]

        let length = switch minutes {
        case .some(1): "For the next minute,"
        case .some(let n) where n > 1: "For the next \(n) minutes,"
        default: "For as long as you like,"
        }
        switch focus {
        case .calmAnxiety:
            lines.append(VoiceLine(text: "\(length) we'll slow the breath down, with an out-breath a little longer than the in-breath."))
            lines.append(VoiceLine(text: "A longer out-breath is one of the simplest ways to help the body settle."))
        case .focus:
            lines.append(VoiceLine(text: "\(length) we'll breathe in an even, steady rhythm."))
            lines.append(VoiceLine(text: "Whenever your attention drifts, the next breath is a place to come back to."))
        case .windDown:
            lines.append(VoiceLine(text: "\(length) we'll breathe slowly, with a long, unhurried out-breath."))
            lines.append(VoiceLine(text: "There's nothing to do now but let the day wind down."))
        }

        if let guidance, !guidance.isEmpty {
            lines.append(VoiceLine(text: "Today's practice.", pause: 1.5))
            lines.append(VoiceLine(text: guidance, pause: 2.5))
        }

        if breathSound {
            lines.append(VoiceLine(text: "You'll hear a soft sound of breath. Breathe in as it rises, and out as it fades."))
        }
        lines.append(VoiceLine(text: "Let's begin.", pause: 1))
        return lines
    }

    // MARK: The first breaths

    static func phase(_ phase: BreathPhase, breath: Int, hadIntro: Bool) -> String {
        switch phase {
        case .inhale: breath == 1 && !hadIntro ? "Close your eyes, and breathe in." : "Breathe in."
        case .holdFull: "Hold, gently."
        case .exhale: "And breathe out."
        case .holdEmpty: "And rest."
        }
    }

    /// "And let go of the rush of today."
    static func letGo(of item: String) -> String {
        "And let go of \(item.prefix(1).lowercased() + item.dropFirst())."
    }

    static let lastBreathIn = "One last breath in."
    static let lastBreathOut = "And let it go."

    // MARK: Along the way

    /// Three reminders, said about a third, a half, and four-fifths of the way through.
    static func reminders(for focus: SessionFocus?) -> [String] {
        switch focus {
        case .calmAnxiety, nil:
            [
                "Let each out-breath be slow and easy, like a long sigh.",
                "If your mind has wandered, that's all right. It's what minds do. Notice where it went, and come back to the breath.",
                "Let your shoulders drop a little. Let your jaw soften.",
            ]
        case .focus:
            [
                "Rest your attention on the feeling of the breath, wherever it's clearest. The nose, the chest, or the belly.",
                "When a thought pulls you away, notice it, and return to the next breath. Each return is the practice.",
                "Steady and even. Nothing to force.",
            ]
        case .windDown:
            [
                "Let your body grow heavy, supported by whatever is beneath you.",
                "If thoughts about the day come up, let them pass. They can wait until tomorrow.",
                "With each out-breath, let yourself sink a little further into rest.",
            ]
        }
    }

    // MARK: Coming back

    /// After the closing bell. `nil` is a Place, a short visit.
    static func closing(for focus: SessionFocus?) -> [VoiceLine] {
        switch focus {
        case .calmAnxiety:
            [
                VoiceLine(text: "Let your breathing return to its own natural rhythm.", pause: 3),
                VoiceLine(text: "Notice how you feel now, compared with when you began.", pause: 4),
                VoiceLine(text: "When you're ready, gently open your eyes.", pause: 0),
            ]
        case .focus:
            [
                VoiceLine(text: "Let the breath return to its own rhythm.", pause: 3),
                VoiceLine(text: "Notice the steadiness you've found. You can come back to it at any time.", pause: 3),
                VoiceLine(text: "When you're ready, open your eyes, and carry on with your day.", pause: 0),
            ]
        case .windDown:
            [
                VoiceLine(text: "Let your breathing return to its own natural pace.", pause: 3),
                VoiceLine(text: "If you're going to sleep, there's no need to open your eyes. Stay with the quiet, and let yourself rest.", pause: 3),
                VoiceLine(text: "Otherwise, when you're ready, gently open your eyes.", pause: 0),
            ]
        case nil:
            [
                VoiceLine(text: "That's the end of this visit.", pause: 2),
                VoiceLine(text: "Notice how you feel.", pause: 3),
                VoiceLine(text: "When you're ready, gently open your eyes.", pause: 0),
            ]
        }
    }
}
