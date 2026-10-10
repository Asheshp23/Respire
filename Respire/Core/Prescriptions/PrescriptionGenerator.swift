//
//  PrescriptionGenerator.swift
//  Respire
//
//  Makes a session from an intake with Apple's on-device model, so nothing a person
//  says about their body or mood leaves the iPhone. Guided generation gives the exact
//  shape the timer needs (no JSON to parse, no stray prose), and Respire's safety rules
//  check the result. Without the model, or if it fails, a hand-written session is used.
//

import Foundation
import FoundationModels
import os

enum PrescriptionGenerator {
    private static let logger = Logger(subsystem: "Respire", category: "Prescriptions")

    /// True when Apple Intelligence is on, the model is downloaded, and it speaks the person's language.
    static var isModelAvailable: Bool {
        let model = SystemLanguageModel.default
        return model.availability == .available && model.supportsLocale(.current)
    }

    /// A session for this person, now. Never throws: the fallback is always there.
    static func prescribe(for intake: BreathIntake, persona: Persona) async -> BreathPrescription {
        var draft = PrescriptionFallback.prescription(for: intake)
        if isModelAvailable {
            do {
                let session = LanguageModelSession(instructions: instructions(for: persona))
                let response = try await session.respond(
                    to: prompt(for: intake, persona: persona),
                    generating: GeneratedPrescription.self,
                    // Room for every field; a tight cap cut answers short and they failed to decode.
                    options: GenerationOptions(temperature: 0.6, maximumResponseTokens: 900)
                )
                draft = prescription(from: response.content, intake: intake)
            } catch {
                // Guardrails, an unsupported language, or a busy model: the fallback stands.
                logger.info("Fell back to a built-in session: \(String(describing: error))")
            }
        }
        return PrescriptionSafety.apply(draft, intake: intake, persona: persona)
    }

    private static func prescription(from generated: GeneratedPrescription, intake: BreathIntake) -> BreathPrescription {
        let difficulty: BreathPrescription.Difficulty = switch generated.difficulty {
        case .beginner: .beginner
        case .intermediate: .intermediate
        case .advanced: .advanced
        }
        return BreathPrescription(
            techniqueName: clean(generated.techniqueName, fallback: "Extended Exhale"),
            targetState: generated.targetState,
            difficulty: difficulty,
            minutes: intake.minutes,
            inhale: generated.pattern.inhaleSeconds,
            holdTop: generated.pattern.holdTopSeconds,
            exhale: generated.pattern.exhaleSeconds,
            holdBottom: generated.pattern.holdBottomSeconds,
            cycles: 0,
            audioIntro: clean(generated.audioIntro, fallback: "Settle in, and let the breath slow down."),
            somaticCue: clean(generated.somaticCue, fallback: PrescriptionFallback.cue(for: intake.setting)),
            journalPrompt: clean(generated.journalPrompt, fallback: "What do you notice now that you didn't before?"),
            source: .onDevice
        )
    }

    // MARK: - Prompting

    /// Framed as a gentle wellness guide: clinical framing ("assess their mental state")
    /// together with a personal note trips the model's content guardrails.
    private static func instructions(for persona: Persona) -> String {
        """
        You design short, gentle breathing exercises for a wellness app. Choose one calm, \
        well-known breathing exercise that suits how the person feels and what comes next, with \
        timings in whole seconds, a short spoken welcome, a posture tip for where they are, and \
        one reflective question for afterwards.

        Rules:
        - Keep it gentle: slow, comfortable breathing only. No fast or forceful breathing, such as \
        Kapalabhati, Bhastrika, or Breath of Fire, and no long breath holds.
        - When someone feels anxious, panicky, or tense, make the breath out longer than the breath \
        in, as in the Physiological Sigh or 4-7-8 Relaxation.
        - Follow every limit you are given.
        - Only mention holding the breath if a hold timing is above zero.
        - Don't give health advice or promise results.
        - Write for \(audience(for: persona)). Plain, warm words. No emoji.
        """
    }

    private static func audience(for persona: Persona) -> String {
        switch persona {
        case .kids: "a child, in short, simple, playful sentences"
        case .teens: "a teenager, honestly and without talking down"
        case .adults: "an adult"
        case .wise: "an older adult, gently and clearly, without hurry"
        }
    }

    static func prompt(for intake: BreathIntake, persona: Persona) -> String {
        var facts = [
            "Make this person's session.",
            "Feeling: \(intake.feeling.title.lowercased()), strength \(intake.intensity) out of 10.",
            "They want to: \(intake.goal.title.lowercased()).",
            "Time available: \(intake.minutes) minute\(intake.minutes == 1 ? "" : "s").",
            "Position: \(intake.setting.title.lowercased()).",
            "Coming up next: \(intake.next.title.lowercased()).",
            "Experience: \(intake.experience.title.lowercased()).",
        ]
        if !intake.noseIsClear { facts.append("Breathing through the nose isn't comfortable right now; breathe through the mouth.") }
        // Limits the rules will enforce anyway; telling the model gives better words around them.
        if !intake.mayHold || persona == .kids || persona == .wise {
            facts.append("Limit: no breath holds at all. Both hold timings must be 0.")
        } else if intake.isPanicking {
            facts.append("Limit: hold at the top for at most 2 seconds, and no hold at the bottom.")
        }
        if intake.feeling.needsLongExhale || intake.goal == .calm || intake.goal == .sleep {
            facts.append("Limit: the exhale must be longer than the inhale.")
        }
        if intake.setting == .inPublic { facts.append("They're around other people, so keep it discreet, with eyes open.") }
        let note = intake.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty { facts.append("In their words: \(note.prefix(BreathIntake.noteLimit))") }
        return facts.joined(separator: "\n")
    }

    private static func clean(_ text: String, fallback: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
        return trimmed.isEmpty ? fallback : trimmed
    }
}
