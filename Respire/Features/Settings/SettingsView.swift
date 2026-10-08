//
//  SettingsView.swift
//  Respire
//
//  Every choice in one ordinary place: how a session guides you, how long it lasts,
//  what you hear, reminders, and the optional written opening.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SessionViewModel.self) private var session

    @AppStorage(Soundscape.guideKey) private var breathSound = true
    @AppStorage(VoiceGuide.storageKey) private var spokenGuidance = true
    @AppStorage("sound.cues") private var phaseChime = false
    @AppStorage("sound.nature") private var natureSound = false
    @AppStorage(SolfeggioTone.storageKey) private var tone: SolfeggioTone = .off
    @AppStorage(BreathTheme.storageKey) private var scene: BreathTheme = .aurora
    @AppStorage(SessionFocus.storageKey) private var focus: SessionFocus = .calmAnxiety
    @AppStorage("session.minutes") private var minutes = 3
    @AppStorage("opening.enabled") private var writtenOpening = false
    @AppStorage("onboarding.done") private var onboardingDone = true

    @State private var isShowingReminders = false
    @State private var isPlayingSample = false

    var body: some View {
        @Bindable var session = session

        Form {
            Section {
                Toggle("Breath sound", systemImage: "wind", isOn: $breathSound)
                Toggle("Spoken guidance", systemImage: "person.wave.2", isOn: $spokenGuidance)
                if spokenGuidance {
                    Button(isPlayingSample ? "Playing…" : "Hear the voice", systemImage: "play.circle") {
                        playSample()
                    }
                    .disabled(isPlayingSample)
                }
                Toggle("Chime at each breath", systemImage: "bell", isOn: $phaseChime)
                if session.hapticsSupported {
                    Toggle("Vibration", systemImage: "iphone.radiowaves.left.and.right", isOn: $session.hapticsEnabled)
                }
            } header: {
                Text("Guidance")
            } footer: {
                Text(guidanceFooter)
            }

            Section("Sessions") {
                Picker("Focus", selection: $focus) {
                    ForEach(SessionFocus.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                Picker("Length", selection: $minutes) {
                    ForEach([1, 3, 5, 10, 0], id: \.self) { option in
                        Text(option > 0 ? "\(option) min" : "Open-ended").tag(option)
                    }
                }
            }

            Section {
                Picker("Scene", selection: $scene) {
                    ForEach(BreathTheme.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                Toggle("Sound of the scene", isOn: $natureSound)
                Picker("Tone", selection: $tone) {
                    ForEach(SolfeggioTone.allCases) { option in
                        Text(Self.label(for: option)).tag(option)
                    }
                }
            } header: {
                Text("Scene & sound")
            } footer: {
                Text("Tones follow the old solfeggio tuning, offered for listening only. Respire makes no claims about what they do.")
            }

            Section("Reminders") {
                Button("Daily reminders", systemImage: "bell.badge") { isShowingReminders = true }
            }

            Section {
                Toggle("Written opening", systemImage: "text.quote", isOn: $writtenOpening)
            } header: {
                Text("Optional")
            } footer: {
                Text("Before breathing, a short passage written on this device from the time, the weather, and your pulse. It uses approximate location for the weather and replaces the spoken settling-in.")
            }

            Section("About") {
                Text("Respire is a simple breathing and meditation app. Everything, including the voice, runs on your device.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                Button("Show the welcome again") { onboardingDone = false }
            }
        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingReminders) {
            MomentRemindersSheet()
        }
    }

    private var guidanceFooter: String {
        let base = "Made for practicing with your eyes closed: the breath sound rises as you breathe in and fades as you breathe out, and the voice talks you in and out of each session."
        guard spokenGuidance, !VoiceGuide.hasNaturalVoice else { return base }
        return base + " For a more natural voice, download an Enhanced or Premium voice in the Settings app, under Accessibility › Spoken Content › Voices."
    }

    private func playSample() {
        isPlayingSample = true
        Task {
            await session.voice.sample()
            isPlayingSample = false
        }
    }

    static func label(for tone: SolfeggioTone) -> String {
        switch tone {
        case .off: "Off"
        case .scene: "Match the scene"
        default: "\(Int(tone.hertz)) Hz · \(tone.quality)"
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(SessionViewModel())
        .environment(MomentReminders())
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
