//
//  SessionView.swift
//  Respire
//
//  The immersive session. The chosen breath world fills the whole canvas (iPhone
//  or full-screen iPad) and breathes with the engine; the guidance, transport
//  controls, and a pane of icy glass with the session's details float over it.
//  While breathing, the details step aside so only the world and its words remain.
//
//  Begin first plays a personalized opening (see `OpeningPlayer`), written on device
//  from the moment's time, weather, pulse, and the chosen focus; breathing follows.
//

import SwiftUI

struct SessionView: View {
    /// Set by a Journey chapter: its world, focus, title, and guiding line take the
    /// place of the person's saved choices without overwriting them.
    private let worldOverride: BreathTheme?
    private let focusOverride: SessionFocus?
    private let titleOverride: String?
    private let guidance: String?
    /// The gate this session practices; otherwise the opening weaves in today's gate.
    private let gateOverride: Dharana?

    @Environment(SessionViewModel.self) private var session
    @Environment(PatternLibrary.self) private var library
    @Environment(DharanaLibrary.self) private var gates
    @AppStorage(BreathTheme.storageKey) private var savedTheme: BreathTheme = .aurora
    @AppStorage(SessionFocus.storageKey) private var savedFocus: SessionFocus = .calmAnxiety
    @AppStorage("opening.enabled") private var opensWithPersonalPrompt = true
    // Off until chosen: calm senses by default.
    @AppStorage("sound.nature") private var natureSound = false
    @AppStorage(SolfeggioTone.storageKey) private var tone: SolfeggioTone = .off

    @State private var isShowingPulseCapture = false
    @State private var isEditingCustom = false
    @State private var isChoosingScene = false
    @State private var isChoosingSound = false
    /// Short canvases (iPhone landscape, slim iPad windows) keep only the guide and controls.
    @State private var isShort = false
    /// The opening currently playing, if any.
    @State private var opening: OpeningPlayer?

    init(world: BreathTheme? = nil, focus: SessionFocus? = nil, title: String? = nil, guidance: String? = nil, gate: Dharana? = nil) {
        worldOverride = world
        focusOverride = focus
        titleOverride = title
        self.guidance = guidance
        gateOverride = gate
    }

    /// The gate woven into the opening: the one being practiced, or today's.
    private var openingGate: SomaticContext.Gate? {
        (gateOverride ?? gates.collection?.dharanaOfTheDay()).map {
            SomaticContext.Gate(number: $0.number, title: $0.title, text: $0.text)
        }
    }

    private var theme: BreathTheme { worldOverride ?? savedTheme }
    private var focus: SessionFocus { focusOverride ?? savedFocus }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var showsDetails: Bool {
        !isShort && verticalSizeClass != .compact && session.engine.state != .running
    }

    var body: some View {
        ZStack {
            // Laid out in the visible detail area so its focal point stays centered
            // beside the sidebar; the extension effect mirrors it underneath the sidebar.
            BreathWorldView(theme: theme, engine: session.engine)
                .id(theme)
                .transition(.opacity)
                .ignoresSafeArea(edges: .vertical)
                .backgroundExtensionEffect()

            // A soft floor of shade so the words and glass read over bright worlds.
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // The guide sits high in the sky and the controls low, leaving the
            // middle of every world (lotus, candle, crater, cabin) clear to watch.
            if let opening {
                OpeningView(player: opening, onSkip: opening.skip)
                    .transition(.opacity)
            } else {
                VStack(spacing: Theme.Space.l) {
                    PhaseGuide(engine: session.engine, theme: theme, guidance: guidance)
                        .padding(.top, Theme.Space.m)
                    Spacer(minLength: 0)
                    TransportControls(onBegin: begin)
                    if showsDetails {
                        SessionDetailsCard(
                            focus: focusOverride == nil ? $savedFocus : nil,
                            soundSummary: soundSummary,
                            onMeasurePulse: { isShowingPulseCapture = true },
                            onChooseSound: { isChoosingSound = true }
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, Theme.Space.page)
                .padding(.bottom, Theme.Space.l)
                .transition(.opacity)
            }
        }
        .onGeometryChange(for: Bool.self) { $0.size.height < 560 } action: { isShort = $0 }
        .animation(.easeInOut(duration: 0.8), value: theme)
        // Animate the details stepping aside when breathing starts, but not size-driven
        // changes: the first geometry pass reports a zero size and must apply instantly.
        .animation(.easeInOut(duration: 0.5), value: session.engine.state)
        .animation(.easeInOut(duration: 0.8), value: opening == nil)
        .onDisappear {
            opening?.cancel()
            opening = nil
            session.soundscape.stop()
        }
        // Sound follows what's happening: the opening, breathing, or auditioning choices.
        .onChange(of: session.engine.state) { _, _ in syncSound() }
        .onChange(of: opening == nil) { _, _ in syncSound() }
        .onChange(of: theme) { _, _ in syncSound() }
        .onChange(of: natureSound) { _, _ in syncSound() }
        .onChange(of: tone) { _, _ in syncSound() }
        .onChange(of: isChoosingSound) { _, _ in syncSound() }
        .navigationTitle(titleOverride ?? session.engine.pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // A Journey day happens in its own world, so the scene choice steps aside.
            if worldOverride == nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isChoosingScene = true
                    } label: {
                        Label(theme.title, systemImage: theme.symbol)
                    }
                    .accessibilityLabel("Scene: \(theme.title)")
                    .accessibilityHint("Choose where to breathe")
                }
            }
            if session.engine.pattern.id == BreathPattern.customDefault.id {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit rhythm", systemImage: "slider.horizontal.3") {
                        isEditingCustom = true
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Measure pulse", systemImage: "heart.text.square") {
                    isShowingPulseCapture = true
                }
            }
        }
        .sheet(isPresented: $isChoosingSound) {
            @Bindable var session = session
            SoundSettingsSheet(
                theme: theme,
                natureSound: $natureSound,
                tone: $tone,
                opensWithPersonalPrompt: $opensWithPersonalPrompt,
                haptics: session.hapticsSupported ? $session.hapticsEnabled : nil
            )
        }
        .sheet(isPresented: $isChoosingScene) {
            ThemePickerSheet(theme: $savedTheme)
        }
        .sheet(isPresented: $isShowingPulseCapture) {
            PulseCaptureView { reading in
                session.baseline = reading
            }
        }
        .sheet(isPresented: $isEditingCustom) {
            @Bindable var library = library
            PatternEditorView(pattern: $library.custom)
                .presentationDetents([.medium, .large])
        }
    }
}

extension SessionView {
    private var soundSummary: String {
        let hertz = tone.frequency(for: theme)
        switch (natureSound, hertz > 0) {
        case (true, true): return "\(theme.title) · \(Int(hertz)) Hz"
        case (true, false): return theme.title
        case (false, true): return "\(Int(hertz)) Hz"
        case (false, false): return "Off"
        }
    }

    /// Plays sound while there's something to accompany, and fades it out otherwise.
    private func syncSound() {
        let isBreathing = session.engine.state == .running || session.engine.state == .paused
        guard isBreathing || opening != nil || isChoosingSound else {
            session.soundscape.stop()
            return
        }
        session.soundscape.play(
            theme: theme,
            nature: natureSound,
            toneHz: tone.frequency(for: theme),
            following: session.engine
        )
    }

    /// Starts a session, opening with the personalized prompt when it's enabled.
    private func begin() {
        guard opensWithPersonalPrompt else {
            session.togglePlayback()
            return
        }
        let player = OpeningPlayer()
        player.onFinish = {
            opening = nil
            session.togglePlayback()
        }
        player.start(
            focus: focus,
            baseline: session.baseline,
            sceneTitle: theme.title,
            pattern: session.engine.pattern,
            gate: openingGate,
            contextService: session.contextService
        )
        opening = player
    }
}

// MARK: - Guide

/// The instruction in the world's own words: a large serif line, the scene's
/// guiding phrase beneath it, and a quiet countdown.
private struct PhaseGuide: View {
    let engine: BreathEngine
    let theme: BreathTheme
    /// A Journey's guiding line, shown before breathing begins.
    var guidance: String?

    var body: some View {
        VStack(spacing: Theme.Space.xs) {
            Text(title)
                .font(Theme.Typography.instruction)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 12)
                .contentTransition(.opacity)

            Text(detail)
                .font(Theme.Typography.note)
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.6), radius: 10)
                .contentTransition(.opacity)

            if engine.state == .running || engine.state == .paused {
                TimelineView(.periodic(from: .now, by: 0.25)) { context in
                    let remaining = engine.snapshot(at: context.date).secondsRemaining
                    Text("\(Int(remaining.rounded(.up)))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                        .contentTransition(.numericText(countsDown: true))
                }
                .accessibilityHidden(true)
            }
        }
        .multilineTextAlignment(.center)
        .animation(.easeInOut(duration: 0.6), value: title)
        .animation(.easeInOut(duration: 0.6), value: detail)
        .frame(minHeight: 110)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var title: String {
        switch engine.state {
        case .idle: "Settle in"
        case .paused: "Paused"
        case .finished: "Well done"
        case .running: engine.phase.instruction
        }
    }

    private var detail: String {
        switch engine.state {
        case .running, .paused: theme.detail(for: engine.phase)
        case .idle, .finished: guidance ?? theme.detail(for: nil)
        }
    }
}

// MARK: - Controls

/// Begin is the one action that refracts: a solid ink pill with the spectral edge.
/// While breathing, quiet glass tools pause and stop.
private struct TransportControls: View {
    @Environment(SessionViewModel.self) private var session
    var onBegin: () -> Void

    private var state: BreathEngine.State { session.engine.state }

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            switch state {
            case .idle, .finished, .paused:
                Button {
                    if state == .paused { session.togglePlayback() } else { onBegin() }
                } label: {
                    Label(state == .paused ? "Resume" : "Begin", systemImage: "play.fill")
                }
                .buttonStyle(.pill)
                .spectralEdge()
                .transition(.opacity)

            case .running:
                Button {
                    session.togglePlayback()
                } label: {
                    Image(systemName: "pause.fill")
                }
                .buttonStyle(.tool)
                .accessibilityLabel("Pause")
                .transition(.opacity)
            }

            if state == .running || state == .paused {
                Button {
                    session.stop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.tool)
                .accessibilityLabel("Stop")
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}

// MARK: - Details

/// Rhythm, pace, cycles, the resting-pulse baseline, and haptic guidance, on one pane of glass.
private struct SessionDetailsCard: View {
    @Environment(SessionViewModel.self) private var session
    /// `nil` when a Journey has already set the focus.
    var focus: Binding<SessionFocus>?
    var soundSummary: String
    var onMeasurePulse: () -> Void
    var onChooseSound: () -> Void

    private var pattern: BreathPattern { session.engine.pattern }

    var body: some View {
        @Bindable var session = session

        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if let focus {
                FocusPicker(focus: focus)

                Rule()
            }

            // One compact line: the rhythm in its hue, and its pace.
            HStack(spacing: Theme.Space.s) {
                Label(pattern.rhythmLabel, systemImage: "waveform.path")
                    .foregroundStyle(pattern.hue)
                Text("\(pattern.breathsPerMinute.formatted(.number.precision(.fractionLength(0...1)))) breaths/min")
                    .foregroundStyle(Theme.Palette.inkTertiary)
                Spacer(minLength: 0)
            }
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityElement(children: .combine)

            Button(action: onMeasurePulse) {
                HStack {
                    Label("Resting pulse", systemImage: "heart.fill")
                        .foregroundStyle(Theme.Palette.inkSecondary)
                    Spacer()
                    Text(session.baseline.map { "\($0.beatsPerMinute) BPM" } ?? "Measure")
                        .monospacedDigit()
                        .foregroundStyle(session.baseline == nil ? Theme.Palette.accent : Theme.Palette.pulse)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
                .font(Theme.Typography.label)
                .frame(minHeight: Theme.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onChooseSound) {
                HStack {
                    Label("Sound & guidance", systemImage: "waveform")
                        .foregroundStyle(Theme.Palette.inkSecondary)
                    Spacer()
                    Text(soundSummary)
                        .foregroundStyle(soundSummary == "Off" ? Theme.Palette.inkTertiary : Theme.Palette.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
                .font(Theme.Typography.label)
                .frame(minHeight: Theme.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

        }
        .card(padding: Theme.Space.m)
    }
}

// MARK: - Focus

/// Three capsules: ink-filled when chosen, quiet glass otherwise. Selection is also
/// a trait and a weight change, so color is never the only cue.
private struct FocusPicker: View {
    @Binding var focus: SessionFocus

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(SessionFocus.allCases) { option in
                let isSelected = option == focus
                Button {
                    focus = option
                } label: {
                    // Icon and title when there's room; the title alone on narrow screens.
                    ViewThatFits(in: .horizontal) {
                        Label(option.title, systemImage: option.symbol)
                        Text(option.title)
                    }
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                        .foregroundStyle(isSelected ? Theme.Palette.onInk : Theme.Palette.ink)
                        .padding(.horizontal, Theme.Space.s)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                        .background {
                            if isSelected {
                                Capsule().fill(Theme.Palette.ink)
                            } else {
                                IceGlass(shape: Capsule(), frost: false)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.easeInOut(duration: 0.2), value: focus)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Focus")
    }
}
