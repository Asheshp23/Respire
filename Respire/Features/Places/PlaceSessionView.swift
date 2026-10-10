//
//  PlaceSessionView.swift
//  Respire
//
//  Visiting a Place: the scene fills the screen and moves one step with each breath.
//  Before you arrive, only its name and what it's for. Once you're breathing there are
//  no words at all; the scene, the breath sound, touch, and the voice guide you, and the
//  two quiet controls fade away until a tap brings them back. It ends with "You have arrived."
//

import SwiftUI

/// A Place drawing for one frame. `isLive` hands its rain and motes to the GPU.
struct PlaceCanvas: View {
    let place: Place
    var frame: PlaceFrame
    var isLive = false

    var body: some View {
        let handsOff = isLive && place.environment.particles?.replacesSketch == true
        Canvas { context, size in
            Sketch.particlesOnGPU = handsOff
            PlaceArt.draw(place.id, &context, size, frame)
            Sketch.particlesOnGPU = false
        }
        .accessibilityHidden(true)
    }
}

extension Place {
    /// Paper-toned places need dark ink for their words.
    var hasLightGround: Bool { Self.lightGrounds.contains(id) }

    private static let lightGrounds: Set<String> = [
        "waterfall-house", "cabin-falls", "tea-house", "cloud-ferry", "kite-hill", "rainbow-pond", "forest-trail",
        "morning-dock", "alpine-lake", "garden-bench", "seaside-promenade",
    ]
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
    /// While breathing, the controls fade back after a few still seconds; a tap brings them back.
    @State private var controlsResting = false
    @State private var restTask: Task<Void, Never>?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private var engine: BreathEngine { session.engine }
    private let environment: PlaceEnvironment

    init(place: Place) {
        self.place = place
        environment = place.environment
    }
    private var ink: Color { place.hasLightGround ? Sketch.hex(0x2A1A10) : .white }

    var body: some View {
        ZStack {
            // The drawing, lit by the scene's own light: bloom, shafts, vignette, grain.
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let current = frame(at: timeline.date)
                PlaceCanvas(place: place, frame: current, isLive: !reduceMotion)
                    .placeLighting(environment.light, breath: current.openness, time: current.time)
            }
            .ignoresSafeArea()

            // The living air, simulated on the GPU.
            if !reduceMotion, let particles = environment.particles {
                PlaceParticles(particles: particles) { particleInputs() }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: Theme.Space.l) {
                header
                Spacer(minLength: 0)
                footer
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 560)
        }
        // A tap anywhere brings the resting controls back.
        .contentShape(Rectangle())
        .onTapGesture { wakeControls() }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar(engine.state == .running ? .hidden : .automatic, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // A short visit: no settling-in, a word for the first breaths, and a brief closing.
            // Places that let go of something name each thing on its out-breath instead.
            session.voice.prepare(focus: nil, withIntro: false, exhaleLines: releaseLines)
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
        .onChange(of: engine.state) { _, state in
            syncSound()
            if state == .running {
                wakeControls()
            } else {
                restTask?.cancel()
                withAnimation(.easeInOut(duration: 0.4)) { controlsResting = false }
            }
        }
        // Adaptive places lengthen the out-breath a little as each new breath begins.
        .onChange(of: engine.phase) { _, phase in
            guard place.isAdaptive, phase == .inhale, engine.state == .running else { return }
            engine.retune(place.pattern(atBreath: engine.completedCycles))
        }
        .sensoryFeedback(.success, trigger: engine.state == .finished) { _, done in done }
    }

    /// Read by the GPU particles every frame.
    private func particleInputs() -> PlaceParticleInputs {
        let now = Date.now
        let progress: Double = switch engine.state {
        case .idle: 0
        case .finished: Double(place.steps)
        case .running, .paused: engine.cycleProgress(at: now)
        }
        let breath = engine.state == .running || engine.state == .paused
            ? engine.snapshot(at: now).lungVolume
            : 0.4 + 0.1 * sin(now.timeIntervalSince(start) * 0.5)
        let steps = max(place.steps, 1)
        return PlaceParticleInputs(breath: breath, stage: min(Int(progress), steps - 1),
                                   progress: min(progress / Double(steps), 1))
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

    /// Before arriving: the place's name and what it's for. Nothing once you're breathing.
    @ViewBuilder
    private var header: some View {
        if engine.state == .idle {
            VStack(spacing: Theme.Space.s) {
                Text(place.arrival)
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(ink.opacity(0.85))
                Text(place.title.uppercased())
                    .font(.system(.title, design: .serif))
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ink)
                    .accessibilityAddTraits(.isHeader)
                Text(place.psychologicalGoal)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(ink.opacity(0.75))
            }
            .shadow(color: place.hasLightGround ? .clear : .black.opacity(0.7), radius: 10)
            // A soft, blurred shade behind the words, so they read over a bright tower or sky.
            .background {
                if !place.hasLightGround {
                    Ellipse()
                        .fill(.black.opacity(0.28))
                        .padding(-Theme.Space.xl)
                        .blur(radius: 44)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, Theme.Space.s)
            .transition(.opacity)
        }
    }

    /// What each out-breath lets go of, spoken, for places that release.
    private var releaseLines: [String] {
        guard case .release(let items) = place.mechanic(for: .current) else { return [] }
        return items.map { VoiceScript.letGo(of: $0) }
    }

    /// Shows the controls, then lets them rest after a few still seconds while breathing.
    private func wakeControls() {
        restTask?.cancel()
        if controlsResting {
            withAnimation(.easeInOut(duration: 0.3)) { controlsResting = false }
        }
        guard engine.state == .running, !voiceOverEnabled else { return }
        restTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, engine.state == .running else { return }
            withAnimation(.easeInOut(duration: 1.2)) { controlsResting = true }
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
                .accessibilityHint("\(place.durationLabel), \(place.rhythmDescription)")
            }
        case .running, .paused:
            VStack(spacing: Theme.Space.s) {
                // No words on screen; the phase is still announced to VoiceOver.
                Color.clear
                    .frame(height: 1)
                    .accessibilityElement()
                    .accessibilityLabel(engine.state == .paused ? "Paused" : engine.phase.instruction)
                    .accessibilityAddTraits(.updatesFrequently)
                // Resting controls stay faintly visible and still work on the first tap.
                HStack(alignment: .bottom, spacing: Theme.Space.l) {
                    SessionControl(title: engine.state == .paused ? "Resume" : "Pause",
                                   systemImage: engine.state == .paused ? "play.fill" : "pause.fill") {
                        session.togglePlayback()
                    }
                    SessionControl(title: "Leave", systemImage: "xmark") { dismiss() }
                }
                .opacity(controlsResting && engine.state == .running ? 0.35 : 1)
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
                        // Back to the starting rhythm; an adaptive visit lengthens from there.
                        session.select(place.pattern)
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
        case .stages(let names): "You breathed your way from \(names.first ?? place.title) to \(names.last ?? place.title)."
        case .find(let count, let verb, let noun): "You \(verb) all \(count) \(noun), one breath at a time."
        case .counter: "You were here for \(Int(place.duration)) seconds, and that was enough."
        case .release(let items): "You let go of \(items.count) things, one out-breath at a time."
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

#Preview("Kite Hill") {
    NavigationStack {
        if let hill = Place.place(id: "kite-hill") {
            PlaceSessionView(place: hill)
        }
    }
    .environment(SessionViewModel())
    .preferredColorScheme(.dark)
}
