//
//  VoiceGuide.swift
//  Respire
//
//  The calm voice that guides a session with eyes closed, following `VoiceScript`:
//  an optional settling-in before the first breath, the words for the first two
//  breaths, three quiet reminders along the way, a cue for the last breath, and a
//  closing after the bell. Spoken on device, slowly and low, through the session's
//  own soundscape so it mixes with everything else.
//

import AVFoundation

final class VoiceGuide {
    /// The setting; on unless turned off.
    static let storageKey = "sound.voice"
    /// Breaths spoken aloud before the voice falls quiet.
    private static let spokenBreaths = 2

    private let soundscape: Soundscape
    /// `nil` for a Place, which has a shorter closing.
    private var focus: SessionFocus?
    private var hadIntro = false
    private var breaths = 0
    private var remindersSaid = 0
    private var lastReminderCycle = 0
    private var isOnLastBreath = false

    init(soundscape: Soundscape) {
        self.soundscape = soundscape
    }

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.storageKey) as? Bool ?? true
    }

    /// The best installed voice for the person's language: premium, then enhanced, then default.
    private lazy var voice: AVSpeechSynthesisVoice? = Self.bestVoice()

    static func bestVoice() -> AVSpeechSynthesisVoice? {
        let language = AVSpeechSynthesisVoice.currentLanguageCode()
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        return voices.first { $0.quality == .premium }
            ?? voices.first { $0.quality == .enhanced }
            ?? AVSpeechSynthesisVoice(language: language)
    }

    /// Whether a natural-sounding voice is installed; otherwise the settings suggest downloading one.
    static var hasNaturalVoice: Bool {
        guard let quality = bestVoice()?.quality else { return false }
        return quality == .premium || quality == .enhanced
    }

    // MARK: - Session

    /// Sets up the script for the next session.
    func prepare(focus: SessionFocus?, withIntro: Bool) {
        self.focus = focus
        hadIntro = withIntro
    }

    /// Breathing is starting over.
    func reset() {
        breaths = 0
        remindersSaid = 0
        lastReminderCycle = 0
        isOnLastBreath = false
    }

    /// The settling-in, line by line. Returns when it's done, or as soon as it's skipped.
    func intro(minutes: Int?, guidance: String?, breathSound: Bool) async {
        guard isEnabled else { return }
        let lines = VoiceScript.intro(focus: focus ?? .calmAnxiety, minutes: minutes, guidance: guidance, breathSound: breathSound)
        await speak(lines)
    }

    /// A phase has just begun (not resumed partway through).
    func phaseBegan(_ phase: BreathPhase, completedCycles: Int, targetCycles: Int?) {
        guard isEnabled else { return }
        if phase == .inhale { breaths += 1 }

        // The last breath, called out so the end doesn't arrive as a surprise.
        if let targetCycles, targetCycles >= 3 {
            if phase == .inhale, completedCycles == targetCycles - 1 {
                isOnLastBreath = true
                say(VoiceScript.lastBreathIn)
                return
            }
            if isOnLastBreath {
                if phase == .exhale { say(VoiceScript.lastBreathOut) }
                return
            }
        }

        if breaths <= Self.spokenBreaths {
            say(VoiceScript.phase(phase, breath: breaths, hadIntro: hadIntro))
            return
        }

        // A reminder, at the start of an out-breath, when nothing else is being said.
        guard phase == .exhale, !soundscape.isSpeaking else { return }
        let reminders = VoiceScript.reminders(for: focus)
        if let targetCycles {
            let marks = [0.3, 0.55, 0.8]
            guard remindersSaid < marks.count,
                  Double(completedCycles) / Double(targetCycles) >= marks[remindersSaid],
                  completedCycles < targetCycles - 1 else { return }
            say(reminders[remindersSaid])
            remindersSaid += 1
        } else if completedCycles >= 4, completedCycles - lastReminderCycle >= 8 {
            // Open-ended: one every eight breaths or so, round and round.
            say(reminders[remindersSaid % reminders.count])
            remindersSaid += 1
            lastReminderCycle = completedCycles
        }
    }

    /// The closing, after the bell.
    func closing() async {
        guard isEnabled else { return }
        await speak(VoiceScript.closing(for: focus))
    }

    /// A few lines to hear what the voice sounds like, from Settings.
    func sample() async {
        await speak([
            VoiceLine(text: "Breathe in.", pause: 1.5),
            VoiceLine(text: "And breathe out.", pause: 1.5),
            VoiceLine(text: "When you're ready, gently open your eyes.", pause: 0.5),
        ])
        soundscape.stop()
    }

    func stop() {
        soundscape.stopVoice()
    }

    // MARK: - Speaking

    private func say(_ text: String) {
        let utterance = utterance(text)
        Task { await soundscape.say(utterance) }
    }

    private func speak(_ lines: [VoiceLine]) async {
        for line in lines {
            guard !Task.isCancelled else { return }
            await soundscape.say(utterance(line.text))
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .seconds(line.pause))
        }
    }

    /// Slow, a little low, and soft.
    private func utterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        utterance.pitchMultiplier = 0.92
        utterance.volume = 0.9
        return utterance
    }
}
