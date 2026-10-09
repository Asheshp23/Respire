//
//  SessionView.swift
//  Respire
//
//  The immersive session. The chosen breath world fills the whole canvas (iPhone
//  or full-screen iPad) and breathes with the engine. Before breathing, a short line
//  says what to do, with focus and length on a pane of glass. While breathing, the
//  world itself is the guide: its lotus, tide, or flame breathes with you, with no
//  words on screen. Everything else steps aside.
//
//  With spoken guidance on, Begin first plays a short spoken settling-in (posture,
//  eyes closed, what the session is), then breathing starts. The written opening
//  (see `OpeningPlayer`) is an option in Settings.
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
    /// False for quick sessions that should start breathing straight away.
    private let allowsOpening: Bool
    /// The rhythm to breathe, when opened from the Breathe list.
    private let rhythm: BreathPattern?
    /// A guided practice, which brings its own spoken script and, sometimes, a hum.
    private let practice: Practice?

    @Environment(SessionViewModel.self) private var session
    @Environment(PatternLibrary.self) private var library
    @Environment(DharanaLibrary.self) private var gates
    @AppStorage(BreathTheme.storageKey) private var savedTheme: BreathTheme = .aurora
    @AppStorage(SessionFocus.storageKey) private var savedFocus: SessionFocus = .calmAnxiety
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults
    // Openings are offered, not imposed: off until the person asks for them every time.
    @AppStorage("opening.enabled") private var opensWithPersonalPrompt = false
    // Off until chosen: calm senses by default.
    @AppStorage("sound.nature") private var natureSound = false
    @AppStorage(SolfeggioTone.storageKey) private var tone: SolfeggioTone = .off
    @AppStorage("sound.cues") private var phaseCues = false
    /// The breath sound that guides eyes-closed practice.
    @AppStorage(Soundscape.guideKey) private var breathTone = true
    /// The calm voice: a settling-in, the first breaths, reminders, and a closing.
    @AppStorage(VoiceGuide.storageKey) private var spokenGuidance = true
    /// How long a free session lasts; 0 breathes until stopped.
    @AppStorage("session.minutes") private var minutes = 3

    @State private var isShowingPulseCapture = false
    @State private var isEditingCustom = false
    @State private var isChoosingSound = false
    /// Short canvases (iPhone landscape, slim iPad windows) keep only the guide and controls.
    @State private var isShort = false
    /// The opening currently playing, if any.
    @State private var opening: OpeningPlayer?
    /// The spoken settling-in, while it plays.
    @State private var settling: Task<Void, Never>?
    /// The quick-settings drawer, before breathing.
    @State private var showsQuickSettings = false
    /// While breathing, the controls fade back after a few still seconds; a tap brings them back.
    @State private var controlsResting = false
    @State private var restTask: Task<Void, Never>?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    init(rhythm: BreathPattern? = nil, world: BreathTheme? = nil, focus: SessionFocus? = nil, title: String? = nil,
         guidance: String? = nil, gate: Dharana? = nil, allowsOpening: Bool = true, practice: Practice? = nil) {
        self.rhythm = rhythm
        self.practice = practice
        worldOverride = world
        focusOverride = focus
        titleOverride = title
        self.guidance = guidance
        gateOverride = gate
        self.allowsOpening = allowsOpening
    }

    /// The gate woven into the opening: the one being practiced, or today's.
    private var openingGate: SomaticContext.Gate? {
        (gateOverride ?? gates.gateOfTheDay()).map {
            SomaticContext.Gate(number: $0.number, title: $0.title, text: $0.text)
        }
    }

    /// The chosen scene, unless it isn't one for whoever's breathing (a storm, for a child).
    private var theme: BreathTheme {
        if let worldOverride { return worldOverride }
        return savedTheme.personas.contains(persona) ? savedTheme : .aurora
    }
    private var focus: SessionFocus { focusOverride ?? savedFocus }
    /// A session started from Today or the Breathe list, rather than a course day or a
    /// practice, which bring their own length and completion card.
    private var isFree: Bool { titleOverride == nil && worldOverride == nil }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var showsDetails: Bool {
        !isShort && verticalSizeClass != .compact && !isBreathing && !showsCompletion
    }

    private var showsCompletion: Bool { isFree && session.engine.state == .finished }

    private var isBreathing: Bool { session.engine.state == .running || session.engine.state == .paused }

    var body: some View {
        ZStack {
            // Laid out in the visible detail area so its focal point stays centered
            // beside the sidebar; the extension effect mirrors it underneath the sidebar.
            // A guided practice has a scene of its own, drawn for its technique.
            Group {
                if let practice {
                    PracticeScene(practice: practice, engine: session.engine)
                } else {
                    BreathWorldView(theme: theme, engine: session.engine)
                        .id(theme)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea(edges: .vertical)
            .backgroundExtensionEffect()

            // A soft floor of shade so the words and glass read over bright worlds.
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // While breathing, a soft vignette quiets the edges so the world's breathing heart
            // (the lotus, the tide, the flame) is the one thing to watch.
            RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 120, endRadius: 640)
                .opacity(isBreathing && opening == nil ? 1 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if isBreathing, opening == nil {
                BreathWord(engine: session.engine)
                    .transition(.opacity)
            }

            // The guide sits high in the sky and the controls low, leaving the
            // middle of every world (lotus, candle, crater, cabin) clear to watch.
            if let opening {
                OpeningView(player: opening, onSkip: opening.skip)
                    .transition(.opacity)
            } else if settling != nil {
                SettlingIn(pattern: session.engine.pattern, onSkip: skipSettling)
                    .frame(maxWidth: 560)
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.bottom, Theme.Space.l)
                    .transition(.opacity)
            } else {
                VStack(spacing: Theme.Space.l) {
                    if !isBreathing {
                        PhaseGuide(engine: session.engine, theme: theme, guidance: guidance, listens: breathTone)
                            .padding(.top, Theme.Space.m)
                            .transition(.opacity)
                        if !showsCompletion {
                            RhythmBadge(pattern: session.engine.pattern)
                                .transition(.opacity)
                        }
                    }
                    Spacer(minLength: 0)
                    if showsCompletion {
                        FreeSessionCompletion(minutes: minutes, onAgain: { begin() }, onDone: session.stop)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        TransportControls(onBegin: { begin() })
                            .opacity(controlsResting ? 0.06 : 1)
                            .allowsHitTesting(!controlsResting)
                    }
                    // Journeys and gates set their own focus and length, so there's nothing to choose.
                    if showsDetails, isFree {
                        SessionDetailsCard(focus: $savedFocus, minutes: $minutes, onChooseFocus: chooseRhythm)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, Theme.Space.page)
                .padding(.bottom, Theme.Space.l)
                .transition(.opacity)
            }
        }
        // A tap anywhere brings resting controls back.
        .contentShape(Rectangle())
        .onTapGesture { wakeControls() }
        .onChange(of: session.engine.state) { _, state in
            showsQuickSettings = false
            if state == .running {
                wakeControls()
            } else {
                restTask?.cancel()
                withAnimation(.easeInOut(duration: 0.4)) { controlsResting = false }
            }
        }
        .onGeometryChange(for: Bool.self) { $0.size.height < 560 } action: { isShort = $0 }
        .animation(.easeInOut(duration: 0.8), value: theme)
        // Animate the details stepping aside when breathing starts, but not size-driven
        // changes: the first geometry pass reports a zero size and must apply instantly.
        .animation(.easeInOut(duration: 0.5), value: session.engine.state)
        .animation(.easeInOut(duration: 0.8), value: opening == nil)
        .animation(.easeInOut(duration: 0.8), value: settling == nil)
        .onAppear {
            if let rhythm, session.engine.state == .idle { session.select(rhythm) }
            // Started with one tap from Now: begin straight away. A moment's wait lets a
            // guided practice set its rhythm and length first.
            if session.beginsOnArrival {
                session.beginsOnArrival = false
                Task { begin() }
            }
        }
        .onDisappear {
            opening?.cancel()
            opening = nil
            settling?.cancel()
            settling = nil
            session.soundscape.stop()
            if isFree {
                session.stop()
                session.engine.targetCycles = nil
            }
        }
        // Sound follows what's happening: the opening, breathing, or auditioning choices.
        .onChange(of: session.engine.state) { _, _ in syncSound() }
        .onChange(of: opening == nil) { _, _ in syncSound() }
        .onChange(of: settling == nil) { _, _ in syncSound() }
        .onChange(of: spokenGuidance) { _, isOn in
            syncSound()
            // Voice turned off while it's settling you in: go straight to breathing.
            if !isOn, settling != nil { skipSettling() }
        }
        // Edits to your own rhythm apply straight away.
        .onChange(of: library.custom) { _, custom in
            if session.engine.pattern.id == custom.id { session.select(custom) }
        }
        .onChange(of: theme) { _, _ in syncSound() }
        .onChange(of: natureSound) { _, _ in syncSound() }
        .onChange(of: tone) { _, _ in syncSound() }
        .onChange(of: phaseCues) { _, _ in syncSound() }
        .onChange(of: breathTone) { _, _ in syncSound() }
        .onChange(of: isChoosingSound) { _, _ in syncSound() }
        .navigationTitle(titleOverride ?? session.engine.pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(session.engine.state == .running ? .hidden : .automatic, for: .navigationBar)
        // A session is a place of its own; the tabs wait until you leave.
        .toolbar(.hidden, for: .tabBar)
        // Every tool says what it does: an icon alone left people guessing.
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsQuickSettings = true
                } label: {
                    Label("Sound & voice", systemImage: "slider.horizontal.3")
                        .labelStyle(.titleAndIcon)
                }
                .popover(isPresented: $showsQuickSettings) {
                    QuickSettings(
                        spokenGuidance: $spokenGuidance,
                        breathSound: $breathTone,
                        sceneSound: $natureSound,
                        haptics: session.hapticsSupported
                            ? Binding(get: { session.hapticsEnabled }, set: { session.hapticsEnabled = $0 })
                            : nil,
                        moreTitle: worldOverride == nil ? "Scene, tones & more" : "Tones & more"
                    ) {
                        showsQuickSettings = false
                        // Let the popover close before the sheet rises.
                        Task {
                            try? await Task.sleep(for: .seconds(0.35))
                            isChoosingSound = true
                        }
                    }
                    .presentationCompactAdaptation(.popover)
                }
            }
            if session.engine.pattern.id == BreathPattern.customDefault.id {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isEditingCustom = true
                    } label: {
                        Label("Edit", systemImage: "slider.horizontal.3")
                            .labelStyle(.titleAndIcon)
                    }
                    .accessibilityLabel("Edit rhythm")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingPulseCapture = true
                } label: {
                    Label("Pulse", systemImage: "heart.text.square")
                        .labelStyle(.titleAndIcon)
                }
                .accessibilityLabel("Measure pulse")
            }
        }
        .sheet(isPresented: $isChoosingSound) {
            @Bindable var session = session
            SoundSettingsSheet(
                theme: theme,
                scene: worldOverride == nil ? $savedTheme : nil,
                natureSound: $natureSound,
                tone: $tone,
                opensWithPersonalPrompt: $opensWithPersonalPrompt,
                haptics: session.hapticsSupported ? $session.hapticsEnabled : nil,
                phaseCues: $phaseCues
            )
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
    /// Plays sound while there's something to accompany, and fades it out otherwise.
    private func syncSound() {
        let isBreathing = session.engine.state == .running || session.engine.state == .paused
        guard isBreathing || opening != nil || settling != nil || isChoosingSound else {
            // A finished session ends with its own bell and fade.
            if session.engine.state != .finished { session.soundscape.stop() }
            return
        }
        session.soundscape.play(
            theme: theme,
            nature: natureSound,
            toneHz: tone.frequency(for: theme),
            cues: phaseCues,
            guide: breathTone,
            voice: spokenGuidance,
            hum: practice?.hums ?? false,
            following: session.engine
        )
    }

    /// Choosing a focus chooses the rhythm that suits it, so a beginner needn't know rhythms.
    private func chooseRhythm(for focus: SessionFocus) {
        guard isFree, session.engine.state == .idle || session.engine.state == .finished else { return }
        session.select(focus.recommendedPattern)
    }

    /// Starts a session: the written opening if it's turned on, else the spoken
    /// settling-in if the voice is on, else straight into breathing.
    private func begin() {
        if isFree {
            // Whole breaths that fill the chosen length; open-ended when no length is set.
            let cycle = max(session.engine.pattern.cycleDuration, 1)
            session.engine.targetCycles = minutes > 0 ? max(1, Int((Double(minutes * 60) / cycle).rounded())) : nil
        }
        // A practice has its own spoken settling-in, so the written opening steps aside.
        let writtenOpening = opensWithPersonalPrompt && allowsOpening && practice == nil
        let spokenIntro = spokenGuidance && !writtenOpening && allowsOpening
        if let practice {
            session.voice.prepare(practice: practice, withIntro: spokenIntro)
        } else {
            session.voice.prepare(focus: focus, withIntro: spokenIntro)
        }

        if spokenIntro {
            settle()
            return
        }
        guard writtenOpening else {
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

    /// The spoken settling-in, then breathing.
    private func settle() {
        let cycles = session.engine.targetCycles
        let length = cycles.map { Int((Double($0) * session.engine.pattern.cycleDuration / 60).rounded()) }
        settling = Task {
            // Let the screen finish arriving before the voice begins.
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            await session.voice.intro(minutes: length, guidance: guidance, breathSound: breathTone)
            guard !Task.isCancelled else { return }
            settling = nil
            session.togglePlayback()
        }
    }

    private func skipSettling() {
        settling?.cancel()
        settling = nil
        session.voice.stop()
        session.togglePlayback()
    }

    /// Shows the controls, then lets them rest after a few still seconds while breathing.
    private func wakeControls() {
        restTask?.cancel()
        if controlsResting {
            withAnimation(.easeInOut(duration: 0.3)) { controlsResting = false }
        }
        guard session.engine.state == .running, !voiceOverEnabled else { return }
        restTask = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled, session.engine.state == .running else { return }
            withAnimation(.easeInOut(duration: 1.2)) { controlsResting = true }
        }
    }
}

// MARK: - Settling in

/// While the voice settles you in: what's happening, and a way to skip straight to breathing.
private struct SettlingIn: View {
    let pattern: BreathPattern
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            VStack(spacing: Theme.Space.xs) {
                Text("Settling in")
                    .font(Theme.Typography.instruction)
                    .foregroundStyle(.white)
                Text("Listen, and close your eyes when you're ready.")
                    .font(Theme.Typography.note)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.6), radius: 10)
            .padding(.top, Theme.Space.m)
            .accessibilityElement(children: .combine)

            RhythmBadge(pattern: pattern)

            Spacer(minLength: 0)

            Button("Skip to breathing", action: onSkip)
                .font(Theme.Typography.label)
                .foregroundStyle(.white.opacity(0.9))
                .frame(minHeight: Theme.minTapTarget)
                .padding(.horizontal, Theme.Space.m)
                .background { IceGlass(shape: Capsule(), frost: false) }
        }
    }
}

// MARK: - Guide

/// What to do, in plain words, before breathing begins; a quiet word once it ends.
/// Most people practice with eyes closed, so with the breath sound on, the sound leads;
/// otherwise the scene does, its lotus, tide, or flame breathing with you.
private struct PhaseGuide: View {
    let engine: BreathEngine
    let theme: BreathTheme
    /// A Journey's guiding line, in place of the usual how-to.
    var guidance: String?
    /// Whether the breath sound will guide, so eyes can close.
    var listens = true

    private var howTo: String {
        listens
            ? "Breathe in as the sound rises, and out as it fades."
            : theme.detail(for: nil)
    }

    var body: some View {
        VStack(spacing: Theme.Space.xs) {
            Text(engine.state == .finished ? "Well done" : (listens ? "Close your eyes" : "Breathe with the scene"))
                .font(Theme.Typography.instruction)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 12)
            if engine.state != .finished {
                Text(guidance ?? howTo)
                    .font(Theme.Typography.note)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.6), radius: 10)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Word

/// The phase, for VoiceOver only. Nothing is drawn: the scene, the breath sound,
/// touch, and the voice are the guide, so there are no words to read while breathing.
private struct BreathWord: View {
    let engine: BreathEngine

    private var word: String {
        engine.state == .paused ? "Paused" : engine.phase.instruction
    }

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(word)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Rhythm

/// The rhythm in plain timings on a pane of glass, so a beginner knows what's coming.
private struct RhythmBadge: View {
    let pattern: BreathPattern

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            BreathPulse(pattern: pattern, size: 12)
            Text("\(pattern.name) · \(pattern.timingLabel)")
                .font(.footnote.monospacedDigit().weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, Theme.Space.s)
        .frame(minHeight: 32)
        .background { IceGlass(shape: Capsule(), frost: false) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pattern.name). \(pattern.timingLabel)")
    }
}

// MARK: - Quick settings

/// A few switches for the voice and sound, so they can be changed without leaving the
/// session, and a way into the rest.
private struct QuickSettings: View {
    @Binding var spokenGuidance: Bool
    @Binding var breathSound: Bool
    @Binding var sceneSound: Bool
    /// `nil` on devices without haptics.
    var haptics: Binding<Bool>?
    var moreTitle: String
    var onMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row("Spoken guidance", symbol: "person.wave.2", isOn: $spokenGuidance)
            row("Breath sound", symbol: "wind", isOn: $breathSound)
            row("Sound of the scene", symbol: "leaf", isOn: $sceneSound)
            if let haptics {
                row("Vibration", symbol: "iphone.radiowaves.left.and.right", isOn: haptics)
            }
            Divider()
                .padding(.vertical, Theme.Space.xxs)
            Button(action: onMore) {
                HStack {
                    Text(moreTitle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline)
                .frame(minHeight: Theme.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Space.m)
        .padding(.vertical, Theme.Space.xs)
        .frame(width: 290)
    }

    private func row(_ title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
        }
        .frame(minHeight: Theme.minTapTarget)
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

// MARK: - Completion

/// The end of a free session: a quiet word, a pulse check beside the baseline, and the way on.
private struct FreeSessionCompletion: View {
    @Environment(SessionViewModel.self) private var session
    let minutes: Int
    var onAgain: () -> Void
    var onDone: () -> Void

    var body: some View {
        let pattern = session.engine.pattern
        CompletionCard(eyebrow: "\(minutes) min · \(pattern.name)", hue: pattern.hue, title: "Well breathed.") {
            Text("Notice how you feel now, before you move on.")
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PulseCheckRow()
            HStack(spacing: Theme.Space.s) {
                Button("Again", action: onAgain)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                Button(action: onDone) {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
            }
        }
    }
}

// MARK: - Details

/// The only two choices before a free session: what you're here for, and for how long.
/// Pulse and sound live in the toolbar.
private struct SessionDetailsCard: View {
    @Binding var focus: SessionFocus
    @Binding var minutes: Int
    var onChooseFocus: (SessionFocus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            FocusPicker(focus: $focus, onChoose: onChooseFocus)
            Rule()
            LengthRow(minutes: $minutes)
        }
        .card(padding: Theme.Space.m)
    }
}

/// How long to breathe, as a menu of a few gentle lengths.
private struct LengthRow: View {
    @Binding var minutes: Int

    private static let options = [1, 3, 5, 10, 0]

    var body: some View {
        Menu {
            Picker("Length", selection: $minutes) {
                ForEach(Self.options, id: \.self) { option in
                    Text(Self.label(option)).tag(option)
                }
            }
        } label: {
            HStack {
                Label("Length", systemImage: "timer")
                    .foregroundStyle(Theme.Palette.inkSecondary)
                Spacer()
                Text(Self.label(minutes))
                    .foregroundStyle(Theme.Palette.ink)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
            .font(Theme.Typography.label)
            .frame(minHeight: Theme.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Length, \(Self.label(minutes))")
    }

    private static func label(_ minutes: Int) -> String {
        minutes > 0 ? "\(minutes) min" : "Open-ended"
    }
}

// MARK: - Focus

/// Three capsules: ink-filled when chosen, quiet glass otherwise. Selection is also
/// a trait and a weight change, so color is never the only cue.
private struct FocusPicker: View {
    @Binding var focus: SessionFocus
    var onChoose: (SessionFocus) -> Void = { _ in }

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(SessionFocus.allCases) { option in
                let isSelected = option == focus
                Button {
                    focus = option
                    onChoose(option)
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

#Preview("Breathing") {
    @Previewable @State var session = SessionViewModel(pattern: .calm)
    NavigationStack {
        SessionView()
    }
    .environment(session)
    .environment(PatternLibrary())
    .environment(DharanaLibrary())
    .task {
        session.togglePlayback()
        // Let the in-breath get going before the snapshot.
        try? await Task.sleep(for: .seconds(2.5))
    }
    .preferredColorScheme(.dark)
}

#Preview("Before breathing") {
    NavigationStack {
        SessionView(rhythm: .coherent)
    }
    .environment(SessionViewModel(pattern: .coherent))
    .environment(PatternLibrary())
    .environment(DharanaLibrary())
    .preferredColorScheme(.dark)
}
