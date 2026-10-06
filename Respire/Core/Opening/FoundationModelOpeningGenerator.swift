//
//  FoundationModelOpeningGenerator.swift
//  Respire
//
//  Writes the opening with Apple's on-device system language model.
//
//  - Guided generation (`@Generable`) gives each of the five lines its own job:
//    arrive in the time of day, carry today's gate (or meet the body), feel the
//    weather, notice the heartbeat, take the first breath. A small model given five interchangeable
//    lines tends to ignore the context; named fields make it use every part.
//  - The response streams. A line counts as finished once the model has started
//    the next field, so the first line appears within moments of tapping Begin.
//  - Each opening uses a fresh session: single turn, no transcript carried over,
//    nothing persisted.
//  - Rules in the instructions keep the voice somatic and non-clinical. The
//    pulse is described, never judged, and there's no medical language.
//

import Foundation
import FoundationModels

@Generable(description: "The spoken opening of a breathwork session, guiding attention into the body. Each field is one sentence of 10 to 16 words.")
struct SomaticOpening {
    @Guide(description: "Arrive in this moment, turning the time of day into an image.")
    var arrival: String
    @Guide(description: "Today's gate as one felt, sensory invitation in your own words. Never quote or name it.")
    var practice: String
    @Guide(description: "Turn the weather outside, or else the scene on screen, into a feeling on the skin or in the body.")
    var weather: String
    @Guide(description: "Notice the heartbeat at the pace given, without judging it; with no pulse, name the focus as a felt intention.")
    var heart: String
    @Guide(description: "Invite the first slow breath in, for the count given, spelled out in words.")
    var invitation: String
}

extension SomaticOpening.PartiallyGenerated {
    /// The fields in speaking order; `nil` for any the model hasn't started yet.
    var orderedLines: [String?] { [arrival, practice, weather, heart, invitation] }
}

final class FoundationModelOpeningGenerator: OpeningGenerator {
    let source = OpeningSource.onDeviceModel

    private var preparedSession: LanguageModelSession?

    /// True when Apple Intelligence is on, the model is downloaded, and it speaks the person's language.
    static var isAvailable: Bool {
        let model = SystemLanguageModel.default
        return model.availability == .available && model.supportsLocale(.current)
    }

    func prepare() {
        let session = Self.makeSession()
        session.prewarm(promptPrefix: Prompt(Self.promptLead))
        preparedSession = session
    }

    func lines(for context: SomaticContext) -> AsyncThrowingStream<String, Error> {
        let session = preparedSession ?? Self.makeSession()
        preparedSession = nil
        let prompt = Self.prompt(for: context)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stream = session.streamResponse(
                        to: prompt,
                        generating: SomaticOpening.self,
                        // Some variety from session to session, but no wandering.
                        options: GenerationOptions(temperature: 0.8, maximumResponseTokens: 320)
                    )
                    var emitted = 0
                    var latest: [String] = []
                    for try await snapshot in stream {
                        // Fields generate in declaration order, so the started ones form a prefix.
                        latest = snapshot.content.orderedLines.prefix { $0 != nil }.compactMap { $0 }
                        // Every started field but the newest is complete.
                        while emitted < latest.count - 1 {
                            if let line = Self.clean(latest[emitted]) { continuation.yield(line) }
                            emitted += 1
                        }
                    }
                    while emitted < latest.count {
                        if let line = Self.clean(latest[emitted]) { continuation.yield(line) }
                        emitted += 1
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Prompting

    private static let promptLead = "Write the opening for this session."

    private static func makeSession() -> LanguageModelSession {
        LanguageModelSession(instructions: instructions)
    }

    private static var instructions: String {
        """
        \(localeInstruction)You write the first thirty seconds of a breathwork session in Respire, a mindfulness app.

        Voice: warm, unhurried, quietly poetic, plain words. Second person, present tense. \
        Speak to the body: weight and contact, temperature on the skin, the movement of breath, \
        the softening of the jaw, shoulders, belly, and hands.

        Weave in the moment you are given: the time of day, the weather outside, the scene on \
        screen, and the pulse if there is one. Use each as a sensory image, gently, at most once.

        You are given today's gate: a short awareness practice from a contemplative tradition. \
        The practice line MUST carry its invitation as one sensory line, in plain words. Don't quote it or name it.

        Rules:
        - Never give medical advice, diagnoses, or health claims.
        - If a pulse is given, you may mention it once as something to notice. Never call it high, low, good, bad, healthy, or worrying.
        - Write no digits. The pulse, if mentioned, is spelled in words. No questions, exclamation marks, emoji, or quotation marks.
        - Never tell the person to stand, walk, or move anywhere.
        - Each line is a single sentence of at most 16 words.
        - The last line invites the first breath in, for the length of the inhale you are given.
        """
    }

    /// Apple's guidance: name the locale with this exact phrase, except for U.S. English.
    private static var localeInstruction: String {
        let locale = Locale.current
        if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) { return "" }
        let language = locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "en") ?? "English"
        return "The person's locale is \(locale.identifier). You MUST respond in \(language).\n\n"
    }

    static func prompt(for context: SomaticContext) -> String {
        var facts = [
            "Focus: \(context.focus.title), to \(context.focus.intent).",
        ]
        // Without a gate, the body's weight and support stand in as the practice.
        if let gate = context.gate {
            facts.append("Today's gate, \(gate.title): \(gate.text)")
        } else {
            facts.append("Today's gate, Body-Weight Awareness: Feel the weight of your body and what supports it.")
        }
        facts.append("Time: \(context.weekday) \(context.timeOfDay.phrase).")
        if let weather = context.weather {
            facts.append("Weather outside: \(weather.summary).")
        }
        if let bpm = context.heartRate, let band = context.pulseBand {
            facts.append("Pulse just measured: about \(spelled(bpm)) beats a minute, \(band.phrase).")
        } else {
            facts.append("Pulse: not measured.")
        }
        facts.append("Scene on screen: \(context.sceneTitle).")
        facts.append("First breath: breathe in for a count of \(spelled(max(Int(context.inhaleSeconds.rounded()), 1))).")

        return ([promptLead] + facts).joined(separator: "\n")
    }

    /// Numbers as words, so the model echoes words rather than digits.
    private static func spelled(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }

    private static func clean(_ line: String) -> String? {
        let trimmed = line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'"))
        return trimmed.isEmpty ? nil : trimmed
    }
}
