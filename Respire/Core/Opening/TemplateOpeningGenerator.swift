//
//  TemplateOpeningGenerator.swift
//  Respire
//
//  A hand-written, on-device fallback for when the system model isn't available
//  (no Apple Intelligence, model still downloading, unsupported language) or
//  declines. It composes five lines in the same shape the model uses: arrive,
//  today's gate (or meet the body), the world outside, the pulse or the intention,
//  the first breath.
//  The phrasing varies by day, so it doesn't repeat word for word.
//

import Foundation

struct TemplateOpeningGenerator: OpeningGenerator {
    let source = OpeningSource.template

    func lines(for context: SomaticContext) -> AsyncThrowingStream<String, Error> {
        let lines = Self.compose(for: context)
        return AsyncThrowingStream { continuation in
            for line in lines { continuation.yield(line) }
            continuation.finish()
        }
    }

    static func compose(for context: SomaticContext, on date: Date = .now) -> [String] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        // Stable within a day (hash values are randomized per launch, so use the case index).
        let focusIndex = SessionFocus.allCases.firstIndex(of: context.focus) ?? 0
        var rng = SeededGenerator(seed: UInt64(day) &* 31 &+ UInt64(focusIndex))

        let fourth: String
        if let bpm = context.heartRate {
            fourth = pulse(bpm)
        } else {
            fourth = intention(context.focus).randomElement(using: &rng) ?? ""
        }

        let second: String
        if let gate = context.gate {
            second = gateLine(gate)
        } else {
            second = body(context.focus).randomElement(using: &rng) ?? ""
        }

        return [
            arrival(context.timeOfDay),
            second,
            outside(context.weather, scene: context.sceneTitle),
            fourth,
            invitation(inhale: context.inhaleSeconds),
        ].filter { !$0.isEmpty }
    }

    /// The closing line alone, for finishing an opening the model left incomplete.
    static func closing(for context: SomaticContext) -> String {
        invitation(inhale: context.inhaleSeconds)
    }

    // MARK: - Phrase banks

    private static func arrival(_ time: SomaticContext.TimeOfDay) -> String {
        switch time {
        case .lateNight: "In the deep quiet of the night, let this moment be small and soft."
        case .earlyMorning: "The day has barely begun, and already you have arrived here."
        case .morning: "This morning is still unfolding, and you can meet it slowly."
        case .midday: "In the middle of the day, you have found a pocket of stillness."
        case .afternoon: "The afternoon can wait outside for a few slow breaths."
        case .evening: "The evening is gathering, and the day can begin to loosen its grip."
        case .night: "Night has settled in, and nothing more is asked of you now."
        }
    }

    private static func body(_ focus: SessionFocus) -> [String] {
        switch focus {
        case .calmAnxiety: [
            "Feel whatever holds you now, the chair or the floor, taking your full weight.",
            "Let your jaw unclench and your shoulders drift a little further from your ears.",
        ]
        case .focus: [
            "Let your spine grow long, as if a thread lifts the crown of your head.",
            "Rest your eyes softly on one point, and let the edges of the room blur.",
        ]
        case .windDown: [
            "Let your body grow heavy, sinking deeper, with nothing left to hold up.",
            "Unclench your hands and let the warmth of the day drain from your fingers.",
        ]
        }
    }

    private static func outside(_ weather: SomaticContext.Weather?, scene: String) -> String {
        guard let weather else {
            return "Here at \(scene), the world slows to the pace of your breathing."
        }
        switch weather.kind {
        case .clear where weather.isDaylight:
            return "Outside the sky is open and clear; let that openness settle behind your eyes."
        case .clear:
            return "Outside the sky is clear and dark; borrow a little of its spaciousness."
        case .cloudy:
            return "Clouds soften the light outside; let your thoughts soften the same way."
        case .rain:
            return "Rain is falling outside; let each drop be one less thing to carry."
        case .snow:
            return "Snow is falling somewhere near; let your mind grow as quiet as fresh snow."
        case .storm:
            return "A storm moves through the sky outside, and here you are sheltered and still."
        case .haze:
            return "The air outside is soft and hazy; you need not see far right now."
        case .wind:
            return "Wind moves outside; let it carry off whatever thoughts are ready to go."
        }
    }

    /// "Today's gate is Blinking as Reset: treat every eye blink as…"
    private static func gateLine(_ gate: SomaticContext.Gate) -> String {
        let text = gate.text.prefix(1).lowercased() + gate.text.dropFirst()
        return "Today's gate is \(gate.title): \(text)"
    }

    private static func pulse(_ bpm: Int) -> String {
        "Your heart is keeping time at about \(bpm) beats a minute; simply notice its rhythm."
    }

    private static func intention(_ focus: SessionFocus) -> [String] {
        switch focus {
        case .calmAnxiety: [
            "There is nothing to fix here, only breath arriving and leaving on its own.",
            "Let each exhale be a little longer, a little softer, than the one before.",
        ]
        case .focus: [
            "Let one clear point of attention gather, steady as a flame in still air.",
            "Everything else can wait at the edges while this breath has your attention.",
        ]
        case .windDown: [
            "Let the day's last thoughts drift past like leaves on slow water.",
            "There is nowhere else to be now, and nothing left that needs your hands.",
        ]
        }
    }

    private static func invitation(inhale: Double) -> String {
        let count = max(Int(inhale.rounded()), 1)
        // The phrase banks are English, so spell the count in English too.
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .spellOut
        let spelled = formatter.string(from: NSNumber(value: count)) ?? String(count)
        return "When you are ready, breathe in slowly for a count of \(spelled)."
    }
}
