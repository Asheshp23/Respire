//
//  AnchorView.swift
//  Respire
//
//  One anchor, start to finish. It begins on arrival:
//
//  1. Invitation: the one thing to notice, large, and spoken.
//  2. Away: the screen dims to a slow, breathing glow and asks you to look up from it.
//     A soft tap marks each breath so nothing needs watching. Coming back early is fine.
//  3. Wonder: a true thing about what you just noticed, and the way on.
//

import AVFoundation
import SwiftUI

struct AnchorView: View {
    let anchor: Anchor

    @Environment(SessionViewModel.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(VoiceGuide.storageKey) private var spokenGuidance = true
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults

    private enum Stage { case invitation, away, wonder }

    @State private var stage = Stage.invitation
    @State private var breath = 0
    @State private var startedAway = Date.now
    @State private var visit: Task<Void, Never>?
    @State private var began = Date.now
    /// The wonder's buttons wait until it has faded in, so a tap meant for "I'm back"
    /// can't land on Done.
    @State private var wonderReady = false

    /// Breathing in for four and out for six while away.
    private static let breathLength = 10.0

    var body: some View {
        ZStack {
            ThemeBackdrop(theme: .current(persona: persona))
                .opacity(stage == .away ? 0 : 1)
                .ignoresSafeArea()
            // Enough shade over the scene for the words to read, even over busy art.
            Color.black
                .opacity(stage == .away ? 0.92 : 0.45)
                .ignoresSafeArea()

            switch stage {
            case .invitation:
                invitation.transition(.opacity)
            case .away:
                away.transition(.opacity)
            case .wonder:
                wonder
                    .allowsHitTesting(wonderReady)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 1.2), value: stage)
        .onChange(of: stage) { _, stage in
            wonderReady = false
            guard stage == .wonder else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                wonderReady = true
            }
        }
        .toolbar(stage == .away ? .hidden : .automatic, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        // A soft tap on each breath, so the breath can be followed without looking.
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: breath)
        .onAppear {
            // Anchors begin on arrival; nothing here for a session to pick up later.
            session.beginsOnArrival = false
            began = .now
            visit = Task { await run() }
        }
        .onDisappear {
            visit?.cancel()
            session.soundscape.stop()
            if stage != .invitation {
                session.history.record(title: anchor.title, seconds: Date.now.timeIntervalSince(began))
            }
        }
    }

    // MARK: - Stages

    private var invitation: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Spacer()
            Label(anchor.sense.title, systemImage: anchor.sense.symbol)
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.8))
            Text(anchor.title)
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(.white)
            Text(anchor.invitation)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                lookAway()
            } label: {
                Label("I'm ready", systemImage: "eye.slash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pill)
            .spectralEdge()
        }
        .shadow(color: .black.opacity(0.5), radius: 8)
        .padding(Theme.Space.page)
        .frame(maxWidth: 560)
    }

    private var away: some View {
        VStack(spacing: Theme.Space.l) {
            Spacer()
            // A slow glow that fills on the in-breath and fades on the out-breath.
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSince(startedAway).truncatingRemainder(dividingBy: Self.breathLength)
                let fill = t < 4 ? sin(t / 4 * .pi / 2) : cos((t - 4) / 6 * .pi / 2)
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.85, blue: 0.6).opacity(0.5), .clear],
                                         center: .center, startRadius: 0, endRadius: 140))
                    .frame(width: 280, height: 280)
                    .scaleEffect(reduceMotion ? 0.8 : 0.6 + 0.4 * fill)
            }
            .accessibilityHidden(true)
            Text("Look up from the screen.\nI'll call you back.")
                .font(Theme.Typography.note)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Button("I'm back") { comeBack() }
                .font(Theme.Typography.label)
                .foregroundStyle(.white.opacity(0.7))
                .frame(minHeight: Theme.minTapTarget)
                .padding(.horizontal, Theme.Space.l)
                .background { IceGlass(shape: Capsule(), frost: false) }
        }
        .padding(Theme.Space.page)
    }

    private var wonder: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            Spacer()
            Text("Did you know")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.75))
            Text(anchor.wonder)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("Whatever you noticed was real, and it was enough.")
                .font(Theme.Typography.note)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            HStack(spacing: Theme.Space.s) {
                Button("Again") { again() }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                Button {
                    dismiss()
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 8)
        .padding(Theme.Space.page)
        .frame(maxWidth: 560)
    }

    // MARK: - The visit

    /// Speaks the invitation, then looks away for the anchor's breaths, then comes back.
    private func run() async {
        await say(anchor.invitation)
        guard !Task.isCancelled else { return }
        // A moment to read it, too.
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled, stage == .invitation else { return }
        await breatheAway()
    }

    private func lookAway() {
        visit?.cancel()
        session.soundscape.stopVoice()
        visit = Task { await breatheAway() }
    }

    private func breatheAway() async {
        startedAway = .now
        stage = .away
        for _ in 0..<anchor.breaths {
            try? await Task.sleep(for: .seconds(Self.breathLength))
            guard !Task.isCancelled else { return }
            breath += 1
        }
        await say("And gently, come back.")
        guard !Task.isCancelled else { return }
        stage = .wonder
        await say(anchor.wonder)
    }

    private func comeBack() {
        visit?.cancel()
        session.soundscape.stopVoice()
        stage = .wonder
        visit = Task { await say(anchor.wonder) }
    }

    private func again() {
        visit?.cancel()
        session.soundscape.stopVoice()
        breath = 0
        stage = .invitation
        visit = Task { await run() }
    }

    /// Spoken in the persona's voice, when the voice is on.
    private func say(_ text: String) async {
        guard spokenGuidance else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = VoiceGuide.bestVoice()
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * persona.voiceRate
        utterance.pitchMultiplier = persona.voicePitch
        utterance.volume = 0.9
        await session.soundscape.say(utterance)
    }
}

#Preview("Anchor") {
    NavigationStack {
        if let sky = Anchor.anchor(id: "sky") {
            AnchorView(anchor: sky)
        }
    }
    .environment(SessionViewModel())
    .preferredColorScheme(.dark)
}
