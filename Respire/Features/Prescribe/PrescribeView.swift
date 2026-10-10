//
//  PrescribeView.swift
//  Respire
//
//  "Make my session": a short check-in, one question a page, then a session made for
//  this moment. Safety comes first: anything urgent stops here with a word to get help,
//  and health answers shape what's offered. The session shows exactly what will happen
//  and what the safety rules changed before it begins, and ends with a journal prompt.
//

import SwiftUI

struct PrescribeView: View {
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults
    @AppStorage("prescribe.remembersHealth") private var remembersHealth = true

    private enum Step: Int, CaseIterable { case safety, health, feeling, need, time, note }
    private enum Stage: Hashable { case asking, making, ready(BreathPrescription), stop }

    @State private var intake = BreathIntake()
    @State private var step = Step.safety
    @State private var stage = Stage.asking
    @State private var practicing: BreathPrescription?

    var body: some View {
        Group {
            switch stage {
            case .asking: asking
            case .making: making
            case .ready(let prescription): ready(prescription)
            case .stop: stop
            }
        }
        .animation(.easeInOut(duration: 0.35), value: stage)
        .animation(.easeInOut(duration: 0.35), value: step)
        // Questions read best over a wash of the scene, not the scene itself.
        .paperBackground(softened: true)
        .navigationTitle("Make my session")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $practicing) { prescription in
            PrescribedSessionView(prescription: prescription)
        }
        .onAppear {
            if remembersHealth, intake.conditions.isEmpty {
                intake.conditions = BreathIntake.rememberedConditions()
            }
        }
    }

    // MARK: - Asking

    private var asking: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                .tint(Theme.prism[3])
                .accessibilityLabel("Question \(step.rawValue + 1) of \(Step.allCases.count)")
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    page
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            footer
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var page: some View {
        switch step {
        case .safety:
            heading("First, are you safe right now?", "Tick anything that's happening at this moment.")
            ForEach(BreathIntake.RedFlag.allCases) { flag in
                choice(flag.title, symbol: "exclamationmark.triangle", isOn: intake.redFlags.contains(flag)) {
                    intake.redFlags.formSymmetricDifference([flag])
                }
            }
            choice("I'm sitting or lying somewhere safe, not driving and not in water", symbol: "checkmark.shield",
                   isOn: intake.isSomewhereSafe) { intake.isSomewhereSafe.toggle() }

        case .health:
            heading("Anything we should know?", "This shapes what's safe for you, like whether to hold the breath. Tick any that apply.")
            ForEach(BreathIntake.Condition.allCases) { condition in
                choice(condition.title, symbol: "heart.text.square", isOn: intake.conditions.contains(condition)) {
                    intake.conditions.formSymmetricDifference([condition])
                }
            }
            Toggle("Remember these on this iPhone", isOn: $remembersHealth)
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.top, Theme.Space.xs)

        case .feeling:
            heading("How are you feeling?", "Pick the closest one.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Theme.Space.xs)], spacing: Theme.Space.xs) {
                ForEach(BreathIntake.Feeling.allCases) { feeling in
                    choice(feeling.title, symbol: feeling.symbol, isOn: intake.feeling == feeling) { intake.feeling = feeling }
                }
            }
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("How strong is it? \(intake.intensity) of 10")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.ink)
                Slider(value: Binding(get: { Double(intake.intensity) }, set: { intake.intensity = Int($0.rounded()) }),
                       in: 1...10, step: 1)
                    .accessibilityValue("\(intake.intensity) of 10")
            }
            .padding(.top, Theme.Space.s)

        case .need:
            heading("What would help most?", nil)
            ForEach(BreathIntake.Goal.allCases) { goal in
                choice(goal.title, symbol: nil, isOn: intake.goal == goal) { intake.goal = goal }
            }
            subheading("What's coming up next?")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: Theme.Space.xs)], spacing: Theme.Space.xs) {
                ForEach(BreathIntake.Next.allCases) { next in
                    choice(next.title, symbol: nil, isOn: intake.next == next) { intake.next = next }
                }
            }

        case .time:
            heading("How long do you have?", nil)
            HStack(spacing: Theme.Space.xs) {
                ForEach(BreathIntake.minuteChoices, id: \.self) { minutes in
                    choice("\(minutes) min", symbol: nil, isOn: intake.minutes == minutes) { intake.minutes = minutes }
                }
            }
            subheading("Where are you?")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: Theme.Space.xs)], spacing: Theme.Space.xs) {
                ForEach(BreathIntake.Setting.allCases) { setting in
                    choice(setting.title, symbol: nil, isOn: intake.setting == setting) { intake.setting = setting }
                }
            }
            subheading("Breathwork so far")
            HStack(spacing: Theme.Space.xs) {
                ForEach(BreathIntake.Experience.allCases) { experience in
                    choice(experience.title, symbol: nil, isOn: intake.experience == experience) { intake.experience = experience }
                }
            }
            Toggle("I can breathe comfortably through my nose", isOn: $intake.noseIsClear)
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.ink)

        case .note:
            heading("Anything else?", "Optional. A few words about what's going on, in your own words.")
            TextField("For example: big meeting in ten minutes, can't stop overthinking", text: $intake.note, axis: .vertical)
                .lineLimit(3...6)
                .padding(Theme.Space.m)
                .background { IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false) }
                .onChange(of: intake.note) { _, note in
                    if note.count > BreathIntake.noteLimit { intake.note = String(note.prefix(BreathIntake.noteLimit)) }
                }
            Label(PrescriptionGenerator.isModelAvailable
                  ? "Made on this iPhone. Nothing you write leaves it."
                  : "Apple Intelligence isn't on, so Respire will choose from its own sessions.",
                  systemImage: "lock")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
    }

    private var footer: some View {
        HStack(spacing: Theme.Space.s) {
            if step != .safety {
                Button("Back") { step = Step(rawValue: step.rawValue - 1) ?? .safety }
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
            }
            Spacer()
            Button {
                advance()
            } label: {
                Text(step == .note ? "Make my session" : "Next")
                    .frame(minWidth: 140)
            }
            .buttonStyle(.pill)
            .spectralEdge(step == .note)
            .disabled(step == .safety && !intake.isSomewhereSafe && intake.redFlags.isEmpty)
        }
    }

    private func advance() {
        if (step == .safety || step == .note), intake.needsHelpNow {
            stage = .stop
            return
        }
        if step == .health {
            if remembersHealth { BreathIntake.remember(intake.conditions) } else { BreathIntake.forget() }
        }
        guard let next = Step(rawValue: step.rawValue + 1) else {
            make()
            return
        }
        step = next
    }

    private func make() {
        stage = .making
        let intake = intake, persona = persona
        Task {
            let prescription = await PrescriptionGenerator.prescribe(for: intake, persona: persona)
            stage = .ready(prescription)
        }
    }

    // MARK: - Making and ready

    private var making: some View {
        VStack(spacing: Theme.Space.m) {
            ProgressView()
                .controlSize(.large)
            Text("Making a session for how you feel…")
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func ready(_ p: BreathPrescription) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("\(p.targetState) · \(p.difficulty.rawValue) · \(p.minutes) min")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.prism[3])
                    Text(p.techniqueName)
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                    Text(p.audioIntro)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    BreathShape(pattern: p.pattern, isLive: true)
                        .frame(height: 56)
                    Text(rhythm(p))
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.ink)
                    Label(p.somaticCue, systemImage: "figure.mind.and.body")
                        .font(Theme.Typography.note)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .card(padding: Theme.Space.m)

                if !p.adjustments.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Label("Kept safe for you", systemImage: "checkmark.shield")
                            .font(Theme.Typography.label)
                            .foregroundStyle(Theme.Palette.ink)
                        ForEach(p.adjustments, id: \.self) { note in
                            Text("• \(note)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Palette.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .card(padding: Theme.Space.m)
                }

                Text("Stop at any time if you feel dizzy or uncomfortable, and breathe normally. \(p.source.note)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Theme.Space.s) {
                    Button("Start over") {
                        step = .feeling
                        stage = .asking
                    }
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                    Button {
                        practicing = p
                    } label: {
                        Label("Begin", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pill)
                    .spectralEdge()
                }
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
    }

    private func rhythm(_ p: BreathPrescription) -> String {
        var parts = ["In \(p.inhale)"]
        if p.holdTop > 0 { parts.append("hold \(p.holdTop)") }
        parts.append("out \(p.exhale)")
        if p.holdBottom > 0 { parts.append("hold \(p.holdBottom)") }
        return parts.joined(separator: " · ") + " seconds, \(p.cycles) breaths"
    }

    // MARK: - Stop

    private var stop: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Spacer()
            Image(systemName: "cross.case")
                .font(.largeTitle)
                .foregroundStyle(Theme.prism[0])
            Text("Let's not do breathwork right now.")
                .font(.system(.title, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
            Text(intake.noteConcern == .crisis
                 ? "You deserve support from a person right now. In Canada or the US, call or text 988, any time. Elsewhere, call your local emergency number, or reach out to someone you trust and tell them how you feel."
                 : "What you're feeling needs a person, not an app. If it's severe or sudden, call your local emergency number now. Otherwise, sit or lie down, breathe normally, and contact a doctor or someone nearby.")
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("I'm okay now, go back") {
                intake.redFlags = []
                intake.note = ""
                step = .safety
                stage = .asking
            }
            .font(Theme.Typography.label)
            .foregroundStyle(Theme.Palette.ink)
            .frame(minHeight: Theme.minTapTarget)
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pieces

    private func heading(_ title: String, _ detail: String?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(title)
                .font(.system(.title, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                Text(detail)
                    .font(Theme.Typography.note)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, Theme.Space.xs)
    }

    private func subheading(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.label)
            .foregroundStyle(Theme.Palette.ink)
            .padding(.top, Theme.Space.s)
    }

    private func choice(_ title: String, symbol: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        return Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                if let symbol {
                    Image(systemName: symbol).frame(width: 24)
                }
                Text(title)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if isOn { Image(systemName: "checkmark").fontWeight(.semibold) }
            }
            .font(Theme.Typography.note)
            .foregroundStyle(isOn ? Theme.Palette.onInk : Theme.Palette.ink)
            .padding(.horizontal, Theme.Space.m)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget + 8, alignment: .leading)
            .background {
                if isOn { shape.fill(Theme.Palette.ink) } else { IceGlass(shape: shape, frost: false) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - The session

/// Breathing the prescription: its rhythm and length, its intro spoken, and its journal
/// prompt at the end, with room to write a line or two that stays on this iPhone.
private struct PrescribedSessionView: View {
    let prescription: BreathPrescription

    @AppStorage(Persona.storageKey) private var persona: Persona = .adults
    @State private var reflection = ""

    private var focus: SessionFocus {
        switch prescription.targetState {
        case "Sleep Prep": .windDown
        case "Focus": .focus
        default: .calmAnxiety
        }
    }

    var body: some View {
        GuidedPracticeView(
            pattern: prescription.pattern,
            cycles: prescription.cycles,
            world: .current(persona: persona),
            focus: focus,
            title: prescription.techniqueName,
            guidance: "\(prescription.audioIntro) \(prescription.somaticCue)",
            onComplete: {}
        ) { leave in
            CompletionCard(eyebrow: "\(prescription.techniqueName) · \(prescription.minutes) min", hue: Theme.prism[3], title: "Well breathed.") {
                Text(prescription.journalPrompt)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                TextField("A line or two, just for you", text: $reflection, axis: .vertical)
                    .lineLimit(2...5)
                    .padding(Theme.Space.s)
                    .background { IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false) }
                Button {
                    BreathJournal.save(prompt: prescription.journalPrompt, text: reflection)
                    leave()
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
            }
        }
    }
}

/// Reflections after a made session, kept on this iPhone only.
enum BreathJournal {
    private static let key = "journal.entries"

    static func save(prompt: String, text: String, defaults: UserDefaults = .standard) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var entries = defaults.array(forKey: key) as? [[String: String]] ?? []
        entries.insert(["date": Date.now.ISO8601Format(), "prompt": prompt, "text": trimmed], at: 0)
        defaults.set(Array(entries.prefix(200)), forKey: key)
    }
}

#Preview {
    NavigationStack { PrescribeView() }
        .environment(SessionViewModel())
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
