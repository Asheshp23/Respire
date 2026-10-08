//
//  PlaceSessionView.swift
//  Respire
//
//  Visiting a Place: the drawing fills the screen and moves one step with each
//  breath. Above it, the arrival ("You are now arriving at… Rain Station") and the
//  quiet progress: a list of stages, what's been found, or the time kept. Below,
//  the breath and a single control. It ends with "You have arrived."
//

import SwiftUI

/// A Place drawing for one frame.
struct PlaceCanvas: View {
    let place: Place
    var frame: PlaceFrame

    var body: some View {
        Canvas { context, size in
            PlaceArt.draw(place.id, &context, size, frame)
        }
        .accessibilityHidden(true)
    }
}

extension Place {
    /// Paper-toned places need dark ink for their words.
    var hasLightGround: Bool {
        ["waterfall-house", "cabin-falls", "tea-house", "cloud-ferry"].contains(id)
    }
}

struct PlaceSessionView: View {
    let place: Place

    @Environment(SessionViewModel.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("sound.nature") private var natureSound = false
    @AppStorage(SolfeggioTone.storageKey) private var tone: SolfeggioTone = .off
    @AppStorage("sound.cues") private var phaseCues = false
    @AppStorage(Soundscape.guideKey) private var breathTone = true
    @AppStorage(VoiceGuide.storageKey) private var spokenGuidance = true

    @State private var start = Date.now

    private var engine: BreathEngine { session.engine }
    private var ink: Color { place.hasLightGround ? Sketch.hex(0x2A1A10) : .white }

    var body: some View {
        ZStack {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                PlaceCanvas(place: place, frame: frame(at: timeline.date))
            }
            .ignoresSafeArea()

            VStack(spacing: Theme.Space.l) {
                header
                Spacer(minLength: 0)
                footer
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 560)
        }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // A short visit: no settling-in, a word for the first breaths, and a brief closing.
            session.voice.prepare(focus: nil, withIntro: false)
            session.select(place.pattern)
            engine.targetCycles = place.steps
            start = .now
            syncSound()
        }
        .onDisappear {
            session.stop()
            engine.targetCycles = nil
            session.soundscape.stop()
        }
        .onChange(of: engine.state) { _, _ in syncSound() }
        .sensoryFeedback(.success, trigger: engine.state == .finished) { _, done in done }
    }

    private func frame(at date: Date) -> PlaceFrame {
        let progress: Double = switch engine.state {
        case .idle: 0
        case .finished: Double(place.steps)
        case .running, .paused: engine.cycleProgress(at: date)
        }
        let openness = engine.state == .idle || engine.state == .finished
            ? 0.4 + 0.1 * sin(date.timeIntervalSince(start) * 0.5)
            : engine.snapshot(at: date).lungVolume
        return PlaceFrame(progress: progress, steps: place.steps, openness: openness,
                          time: reduceMotion ? 0 : date.timeIntervalSince(start))
    }

    // MARK: - Header

    private var isBreathing: Bool { engine.state == .running || engine.state == .paused }

    /// The arrival and the full progress before and after; while breathing, one quiet line,
    /// so the breath word below is the only thing to read.
    private var header: some View {
        VStack(spacing: Theme.Space.s) {
            if !isBreathing {
                Text(place.arrival)
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(ink.opacity(0.85))
                Text(place.title.uppercased())
                    .font(.system(.title, design: .serif))
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ink)
                    .accessibilityAddTraits(.isHeader)
            }

            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                if isBreathing {
                    quietProgress(at: timeline.date)
                } else {
                    progressView(at: timeline.date)
                }
            }
        }
        .shadow(color: place.hasLightGround ? .clear : .black.opacity(0.7), radius: 10)
        .padding(.top, Theme.Space.s)
        .animation(.easeInOut(duration: 0.5), value: isBreathing)
    }

    /// Where you are, in a few words: "Steady rain · 2 of 4", "3 of 7 bowls", "30 seconds".
    private func quietProgress(at date: Date) -> some View {
        let progress = engine.cycleProgress(at: date)
        let done = min(Int(progress), place.steps)
        let current = min(done, place.steps - 1)
        let text: String = switch place.mechanic {
        case .stages(let names): "\(names[current]) · \(current + 1) of \(names.count)"
        case .find(let count, _, let noun): "\(done) of \(count) \(noun)"
        case .counter: "\(Int(progress * (place.inhale + place.exhale))) seconds"
        }
        return Text(text)
            .font(.system(.subheadline, design: .serif))
            .monospacedDigit()
            .foregroundStyle(ink.opacity(0.8))
            .contentTransition(.numericText())
            .animation(.easeInOut, value: text)
    }

    @ViewBuilder
    private func progressView(at date: Date) -> some View {
        let progress = engine.state == .idle ? 0 : (engine.state == .finished ? Double(place.steps) : engine.cycleProgress(at: date))
        let done = min(Int(progress), place.steps)
        let current = min(done, place.steps - 1)

        switch place.mechanic {
        case .stages(let names):
            VStack(spacing: Theme.Space.xxs) {
                ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                    let isNow = index == current && engine.state != .idle && engine.state != .finished
                    HStack(spacing: Theme.Space.xs) {
                        Text("\(index + 1)")
                            .monospacedDigit()
                        Text(name)
                    }
                    .font(.system(isNow ? .headline : .subheadline, design: .serif))
                    .foregroundStyle(ink.opacity(isNow ? 1 : (index < done ? 0.55 : 0.35)))
                    .overlay(alignment: .bottom) {
                        if isNow {
                            Capsule().fill(ink.opacity(0.8)).frame(height: 1.5).offset(y: 3)
                        }
                    }
                }
            }
            .padding(.top, Theme.Space.xs)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(engine.state == .idle ? "\(names.count) stages" : "Stage \(current + 1): \(names[current])")
        case .find(let count, let verb, let noun):
            Text("You have now \(verb) \(done)/\(count) \(noun)")
                .font(.system(.title3, design: .serif))
                .monospacedDigit()
                .foregroundStyle(ink)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: done)
        case .counter:
            let seconds = Int(progress * (place.inhale + place.exhale))
            VStack(spacing: 2) {
                Text("You have been here for…")
                    .font(.system(.subheadline, design: .serif).italic())
                Text("\(seconds) seconds")
                    .font(.system(.title2, design: .serif))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(ink)
            .animation(.easeInOut, value: seconds)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch engine.state {
        case .idle:
            VStack(spacing: Theme.Space.xs) {
                Button {
                    start = .now
                    session.togglePlayback()
                } label: {
                    Label("Arrive", systemImage: "play.fill")
                }
                .buttonStyle(.pill)
                .spectralEdge()
                Text("\(place.durationLabel) · in for \(Int(place.inhale)), out for \(Int(place.exhale))")
                    .font(Theme.Typography.meta)
                    .foregroundStyle(ink.opacity(0.75))
            }
        case .running, .paused:
            VStack(spacing: Theme.Space.s) {
                Text(engine.state == .paused ? "Paused" : engine.phase.instruction)
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(ink)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: engine.phase)
                    .shadow(color: place.hasLightGround ? .clear : .black.opacity(0.7), radius: 10)
                HStack(spacing: Theme.Space.s) {
                    Button {
                        session.togglePlayback()
                    } label: {
                        Image(systemName: engine.state == .paused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.tool)
                    .accessibilityLabel(engine.state == .paused ? "Resume" : "Pause")
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.tool)
                    .accessibilityLabel("Leave")
                }
            }
        case .finished:
            CompletionCard(eyebrow: place.durationLabel, hue: place.tint, title: "You have arrived.") {
                Text(closingLine)
                    .font(Theme.Typography.note)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PulseCheckRow()
                HStack(spacing: Theme.Space.s) {
                    Button("Visit again") {
                        start = .now
                        session.stop()
                        session.togglePlayback()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                    Button {
                        dismiss()
                    } label: {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pill)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var closingLine: String {
        switch place.mechanic {
        case .stages(let names): "You breathed your way to \(names.last ?? place.title)."
        case .find(let count, let verb, let noun): "You \(verb) all \(count) \(noun), one breath at a time."
        case .counter: "You were here for \(Int(place.duration)) seconds, and that was enough."
        }
    }

    private func syncSound() {
        let active = engine.state == .running || engine.state == .paused
        guard active else {
            // Arriving ends with its own bell and fade.
            if engine.state != .finished { session.soundscape.stop() }
            return
        }
        session.soundscape.play(theme: place.sound, nature: natureSound, toneHz: tone.frequency(for: place.sound),
                                cues: phaseCues, guide: breathTone, voice: spokenGuidance, following: engine)
    }
}

#Preview("Rain Station") {
    NavigationStack {
        PlaceSessionView(place: Place.place(id: "rain-station")!)
    }
    .environment(SessionViewModel())
    .preferredColorScheme(.dark)
}

#Preview("Singing Bowl Temple") {
    NavigationStack {
        if let temple = Place.place(id: "bowl-temple") {
            PlaceSessionView(place: temple)
        }
    }
    .environment(SessionViewModel())
    .preferredColorScheme(.dark)
}
