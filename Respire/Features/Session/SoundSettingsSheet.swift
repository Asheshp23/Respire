//
//  SoundSettingsSheet.swift
//  Respire
//
//  How a session guides you: the personal opening and haptics, then what to hear,
//  the world's own nature sound and an optional solfeggio tone that swells a
//  little with each in-breath. Sound is off until chosen, and changes are heard
//  right away while the sheet is open.
//

import SwiftUI

struct SoundSettingsSheet: View {
    let theme: BreathTheme
    /// The world to breathe in; `nil` when a Journey or gate has already chosen it.
    var scene: Binding<BreathTheme>? = nil
    @Binding var natureSound: Bool
    @Binding var tone: SolfeggioTone
    @Binding var opensWithPersonalPrompt: Bool
    /// `nil` on devices without haptics.
    var haptics: Binding<Bool>?
    @Binding var phaseCues: Bool

    @AppStorage(Soundscape.guideKey) private var breathTone = true
    @AppStorage(VoiceGuide.storageKey) private var spokenGuidance = true

    @Environment(\.dismiss) private var dismiss

    private let toneColumns = [GridItem(.adaptive(minimum: 96), spacing: Theme.Space.s)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    if let scene {
                        section("Scene") {
                            ScenePicker(theme: scene)
                        }
                    }

                    section("Eyes closed") {
                        VStack(spacing: Theme.Space.s) {
                            toggle(
                                "Breath tone",
                                symbol: "waveform.path",
                                detail: "A soft note that rises as you breathe in, falls as you breathe out, and holds level in the pauses.",
                                isOn: $breathTone
                            )
                            toggle(
                                "Spoken guidance",
                                symbol: "person.wave.2",
                                detail: "A voice for the first two breaths, then quiet. At the end, a bell and a word to open your eyes.",
                                isOn: $spokenGuidance
                            )
                        }
                    }

                    section("Guidance") {
                        VStack(spacing: Theme.Space.s) {
                            toggle(
                                "Always begin with an opening",
                                symbol: "text.quote",
                                detail: "Thirty seconds written on this device from the time, the weather, your pulse, and today's gate, before you start breathing.",
                                isOn: $opensWithPersonalPrompt
                            )
                            if let haptics {
                                toggle(
                                    "Haptic guidance",
                                    symbol: "hand.tap",
                                    detail: "A soft swell on each in-breath and a fading release on each out-breath.",
                                    isOn: haptics
                                )
                            }
                            toggle(
                                "Phase chime",
                                symbol: "bell.and.waves.left.and.right",
                                detail: "A soft chime as each phase begins, higher breathing in, lower breathing out. Follow along with your eyes closed.",
                                isOn: $phaseCues
                            )
                        }
                    }

                    section("Nature") {
                        Toggle(isOn: $natureSound) {
                            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                                Label("\(theme.title)", systemImage: theme.symbol)
                                    .font(.body.weight(.semibold))
                                Text("\(theme.natureSound), rising and falling with your breath.")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .tint(Theme.prism[3])
                        .padding(Theme.Space.m)
                        .frame(minHeight: 64)
                        .background { IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false) }
                    }

                    section("Tone") {
                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            Text("A soft, steady tone from the solfeggio tradition, swelling a little as you breathe in. Play it alone or under the nature sound. Something to listen to, not a treatment.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                            LazyVGrid(columns: toneColumns, spacing: Theme.Space.s) {
                                toneTile(.off)
                                toneTile(.scene)
                                ForEach(SolfeggioTone.tones) { option in
                                    toneTile(option)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.Space.page)
            }
            .background(Theme.Palette.paper)
            .navigationTitle(scene == nil ? "Sound & Guidance" : "Scene & Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ title: String, symbol: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Label(title, systemImage: symbol)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Theme.prism[3])
        .padding(Theme.Space.m)
        .background { IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false) }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(title)
                .font(Theme.Typography.meta.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    /// A tone: its frequency, the quality the tradition gives it, and its hue.
    private func toneTile(_ option: SolfeggioTone) -> some View {
        let isSelected = option == tone
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        let sceneTone = SolfeggioTone.tone(for: theme)
        let headline: String = switch option {
        case .off: "Off"
        case .scene: "\(Int(sceneTone.hertz)) Hz"
        default: "\(Int(option.hertz)) Hz"
        }
        let hue = option == .scene ? sceneTone.hue : option.hue

        return Button {
            tone = option
        } label: {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                HStack(spacing: Theme.Space.xxs) {
                    if option == .scene {
                        Image(systemName: theme.symbol)
                            .font(.caption2)
                    }
                    Text(option == .scene ? "Scene" : headline)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.white)
                Text(option == .scene ? headline : option.quality)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(Theme.Space.s)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background {
                ZStack {
                    IceGlass(shape: shape, frost: false)
                    if option != .off {
                        shape.fill(RadialGradient(colors: [hue.opacity(0.35), .clear], center: .topLeading, startRadius: 0, endRadius: 90))
                    }
                }
            }
            .overlay {
                shape.strokeBorder(
                    isSelected
                        ? AnyShapeStyle(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center))
                        : AnyShapeStyle(.white.opacity(0.15)),
                    lineWidth: isSelected ? 2.5 : 1
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option == .scene ? "Match the scene, \(headline)" : (option == .off ? "No tone" : "\(headline), \(option.quality)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    @Previewable @State var nature = true
    @Previewable @State var tone = SolfeggioTone.scene
    @Previewable @State var opening = true
    @Previewable @State var haptics = true
    @Previewable @State var cues = false
    @Previewable @State var scene = BreathTheme.rain
    SoundSettingsSheet(theme: scene, scene: $scene, natureSound: $nature, tone: $tone,
                       opensWithPersonalPrompt: $opening, haptics: $haptics, phaseCues: $cues)
        .preferredColorScheme(.dark)
}
