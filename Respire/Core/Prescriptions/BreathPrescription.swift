//
//  BreathPrescription.swift
//  Respire
//
//  A session made for one person, right now: what the on-device model suggests,
//  passed through Respire's own safety rules before anyone breathes it.
//
//  The model is never trusted with safety. Whatever it writes, the rules below decide
//  the final rhythm: whole seconds, no holds when health rules them out, a longer
//  out-breath for anxiety, never faster than ten breaths a minute, no forceful
//  techniques, and a length that fits the time the person has.
//

import Foundation
import FoundationModels

// MARK: - What the model writes

@Generable(description: "A safe, personalised breathwork session.")
struct GeneratedPrescription {
    @Guide(description: "The name of a well-known, gentle technique, e.g. Box Breathing, 4-7-8 Relaxation, Physiological Sigh, Coherent Breathing, Extended Exhale.")
    var techniqueName: String
    @Guide(description: "The primary benefit.", .anyOf(["Anxiety Relief", "Calm", "Focus", "Gentle Energy", "Sleep Prep", "Steadiness"]))
    var targetState: String
    var difficulty: GeneratedDifficulty
    var pattern: GeneratedPattern
    @Guide(description: "One or two comforting spoken sentences to prepare for the session, in plain words.")
    var audioIntro: String
    @Guide(description: "One sentence of posture or grounding advice that suits where the person is.")
    var somaticCue: String
    @Guide(description: "One reflective question to write about right after the session.")
    var journalPrompt: String
}

@Generable
enum GeneratedDifficulty {
    case beginner, intermediate, advanced
}

@Generable(description: "The breathing rhythm, in whole seconds.")
struct GeneratedPattern {
    @Guide(.range(2...8)) var inhaleSeconds: Int
    @Guide(.range(0...7)) var holdTopSeconds: Int
    @Guide(.range(2...12)) var exhaleSeconds: Int
    @Guide(.range(0...6)) var holdBottomSeconds: Int
}

// MARK: - What Respire runs

struct BreathPrescription: Hashable {
    enum Source: Hashable {
        case onDevice, builtIn

        var note: String {
            switch self {
            case .onDevice: "Made on this iPhone by Apple Intelligence, then checked by Respire's safety rules."
            case .builtIn: "Chosen by Respire's own rules."
            }
        }
    }

    enum Difficulty: String, Hashable {
        case beginner = "Beginner", intermediate = "Intermediate", advanced = "Advanced"
    }

    var techniqueName: String
    var targetState: String
    var difficulty: Difficulty
    var minutes: Int
    var inhale: Int
    var holdTop: Int
    var exhale: Int
    var holdBottom: Int
    var cycles: Int
    var audioIntro: String
    var somaticCue: String
    var journalPrompt: String
    /// What the safety rules changed, in plain words, so nothing is changed silently.
    var adjustments: [String] = []
    var source: Source

    var pattern: BreathPattern {
        BreathPattern(id: "prescribed", name: techniqueName, summary: targetState,
                      inhale: Double(inhale), holdFull: Double(holdTop), exhale: Double(exhale), holdEmpty: Double(holdBottom))
    }

    var cycleSeconds: Int { inhale + holdTop + exhale + holdBottom }

    /// The session in the shared JSON shape, for the timer and for anyone exporting it.
    var json: String {
        let object: [String: Any] = [
            "recommendation": [
                "technique_name": techniqueName,
                "target_state": targetState,
                "difficulty": difficulty.rawValue,
                "duration_minutes": minutes,
            ],
            "pattern_config": [
                "inhale_seconds": inhale,
                "hold_top_seconds": holdTop,
                "exhale_seconds": exhale,
                "hold_bottom_seconds": holdBottom,
                "cycles": cycles,
            ],
            "guidance": [
                "audio_intro": audioIntro,
                "somatic_cue": somaticCue,
            ],
            "post_breathwork_journal_prompt": journalPrompt,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - Safety

enum PrescriptionSafety {
    /// Forceful or fast techniques that are never offered, whatever the model writes.
    private static let forceful = ["tummo", "kapalabhati", "bhastrika", "breath of fire", "wim hof", "hyperventilat", "holotropic", "rebirthing"]

    /// The rules every session passes through. `persona` shapes the limits too.
    static func apply(_ draft: BreathPrescription, intake: BreathIntake, persona: Persona) -> BreathPrescription {
        var p = draft
        var notes: [String] = []

        // Nothing forceful, ever: a gentle extended exhale instead.
        let name = p.techniqueName.lowercased()
        if forceful.contains(where: name.contains) {
            p.techniqueName = "Extended Exhale"
            (p.inhale, p.holdTop, p.exhale, p.holdBottom) = (4, 0, 6, 0)
            notes.append("Swapped a forceful technique for a gentle one.")
        }

        // Whole seconds within comfortable ranges.
        p.inhale = min(max(p.inhale, 2), 8)
        p.exhale = min(max(p.exhale, 2), 12)
        p.holdTop = min(max(p.holdTop, 0), 7)
        p.holdBottom = min(max(p.holdBottom, 0), 6)

        // Holds: none when health or age rules them out; short for newcomers and panic.
        let noHolds = !intake.mayHold || persona == .kids || persona == .wise
        if noHolds, p.holdTop + p.holdBottom > 0 {
            p.holdTop = 0
            p.holdBottom = 0
            notes.append(persona == .kids || persona == .wise
                         ? "No breath holds, to keep it easy."
                         : "No breath holds, because of what you told us about your health.")
        }
        if intake.isPanicking || intake.conditions.contains(.panicHistory) {
            if p.holdTop > 2 || p.holdBottom > 0 {
                p.holdTop = min(p.holdTop, 2)
                p.holdBottom = 0
                notes.append("Holds kept very short, since panic is close.")
            }
        } else if intake.experience == .new, p.holdTop > 4 || p.holdBottom > 4 {
            p.holdTop = min(p.holdTop, 4)
            p.holdBottom = min(p.holdBottom, 4)
            notes.append("Holds shortened for a first try.")
        }

        // A longer out-breath when calming or sleeping matters.
        if intake.feeling.needsLongExhale || intake.goal == .calm || intake.goal == .sleep {
            let wanted = min(p.inhale + (intake.isPanicking ? 3 : 2), 12)
            if p.exhale < wanted {
                p.exhale = wanted
                notes.append("Made the out-breath longer than the in-breath, which helps the body settle.")
            }
        }

        // An out-breath that stays comfortable: at most twice the in-breath, and shorter
        // for a first try.
        let longest = max(min(p.inhale * 2, intake.experience == .new ? 8 : 12), 6)
        if p.exhale > longest {
            p.exhale = longest
            notes.append("Kept the out-breath to a comfortable length.")
        }

        // Age: shorter breaths for children, an easy pace for the Wise.
        if persona == .kids {
            p.inhale = min(p.inhale, 4)
            p.exhale = min(max(p.exhale, p.inhale + 1), 6)
        } else if persona == .wise {
            p.exhale = min(p.exhale, 8)
        }

        // Never faster than ten breaths a minute.
        if p.cycleSeconds < 6 {
            p.exhale += 6 - p.cycleSeconds
            notes.append("Slowed the pace so it never feels rushed.")
        }

        // A changed rhythm gets an honest name and an intro that matches it, so nothing
        // promises a hold or a count that isn't there.
        let original = (draft.inhale, draft.holdTop, draft.exhale, draft.holdBottom)
        if original != (p.inhale, p.holdTop, p.exhale, p.holdBottom) {
            p.techniqueName = honestName(for: p)
            p.audioIntro = "We'll breathe in for \(p.inhale) and out for \(p.exhale)"
                + (p.holdTop > 0 ? ", with a short pause at the top" : "")
                + ". Nice and easy, nothing to get right."
        }

        // Exactly as long as the person has.
        p.minutes = intake.minutes
        p.cycles = max(2, Int((Double(intake.minutes * 60) / Double(p.cycleSeconds)).rounded()))
        if p.holdTop + p.holdBottom == 0, p.difficulty == .advanced { p.difficulty = .intermediate }
        p.adjustments = notes
        return p
    }
}

extension PrescriptionSafety {
    /// What a rhythm is, named plainly.
    fileprivate static func honestName(for p: BreathPrescription) -> String {
        switch (p.holdTop, p.holdBottom) {
        case (0, 0): p.exhale > p.inhale ? "Extended Exhale" : "Even Breathing"
        case (let top, let bottom) where top > 0 && bottom > 0: top == p.inhale && bottom == p.inhale ? "Box Breathing" : "Gentle Box"
        default: "Paced Breathing"
        }
    }
}

// MARK: - When there's no model

enum PrescriptionFallback {
    /// A dependable session for the intake, written by hand.
    static func prescription(for intake: BreathIntake) -> BreathPrescription {
        let cue = cue(for: intake.setting)
        let (name, target, rhythm, intro, prompt): (String, String, (Int, Int, Int, Int), String, String) = {
            if intake.isPanicking {
                return ("Physiological Sigh", "Anxiety Relief", (4, 1, 8, 0),
                        "You're safe here. We'll take slow breaths with a long, easy sigh out.",
                        "What did your body do as the breath slowed?")
            }
            switch intake.goal {
            case .sleep:
                return ("4-7-8 Relaxation", "Sleep Prep", (4, 0, 8, 0),
                        "Let the day go. Each breath out is a little longer, a little heavier.",
                        "What are you ready to set down for tonight?")
            case .focus:
                return ("Box Breathing", "Focus", (4, 4, 4, 4),
                        "Four even sides. Follow the box, and let your attention gather.",
                        "What is the one thing that matters most in the next hour?")
            case .energy:
                return ("Coherent Breathing", "Gentle Energy", (5, 0, 5, 0),
                        "Even breaths in and out. Let each in-breath wake you a little.",
                        "Where in your body do you feel more awake now?")
            case .steady:
                return ("Extended Exhale", "Steadiness", (4, 0, 6, 0),
                        "Feel your feet, and let the breath out be a little longer than the breath in.",
                        "What would feeling steady look like in the next few minutes?")
            case .calm:
                return ("Extended Exhale", "Calm", (4, 0, 6, 0),
                        "Nothing to get right. Breathe in softly, and let the breath out take its time.",
                        "What feels even a little softer than before?")
            }
        }()
        return BreathPrescription(
            techniqueName: name, targetState: target, difficulty: .beginner, minutes: intake.minutes,
            inhale: rhythm.0, holdTop: rhythm.1, exhale: rhythm.2, holdBottom: rhythm.3, cycles: 0,
            audioIntro: intro, somaticCue: cue, journalPrompt: prompt, source: .builtIn)
    }

    static func cue(for setting: BreathIntake.Setting) -> String {
        switch setting {
        case .sitting: "Let your feet rest flat on the floor, and soften your jaw and shoulders."
        case .lying: "Let the floor or the bed take your whole weight, arms resting by your sides."
        case .standing: "Stand with your knees soft and your weight even across both feet."
        case .inPublic: "Keep your eyes softly open and your breath quiet; nobody needs to know."
        }
    }
}
