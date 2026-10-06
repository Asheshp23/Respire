//
//  DharanaDetailView.swift
//  Respire
//
//  One gate: its world as art, the practice in a large serif, any safety note,
//  traditional words explained plainly, and how it's practiced in Respire.
//  Previous, Practice, and Next live in a bar at the bottom, in thumb reach, so
//  the library can be walked gate by gate.
//

import SwiftUI

struct DharanaDetailView: View {
    @Environment(DharanaLibrary.self) private var library

    @State private var number: Int
    @State private var practicing: Int?

    init(number: Int) {
        _number = State(initialValue: number)
    }

    var body: some View {
        Group {
            if let collection = library.collection,
               let dharana = collection.dharana(number: number),
               let section = collection.section(containing: number) {
                content(collection: collection, dharana: dharana, section: section)
            } else {
                ContentUnavailableView("Gate not found", systemImage: "questionmark.circle")
            }
        }
        .paperBackground()
        .navigationTitle("Gate \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $practicing) { number in
            DharanaPracticeView(number: number)
        }
    }

    private func content(collection: DharanaCollection, dharana: Dharana, section: DharanaSection) -> some View {
        let hue = Theme.prism[section.hue(in: collection)]
        let terms = collection.glossary(for: dharana)
        let pattern = section.pattern(for: dharana)

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                BreathWorldScene(theme: section.theme, openness: 0.55, time: 3)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .id(section.id)

                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("Gate \(dharana.number) of 112 · \(section.title)")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(hue)
                    Text(dharana.title)
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(dharana.text)
                        .font(.system(.title3, design: .serif))
                        .lineSpacing(5)
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let caution = dharana.caution {
                    Label {
                        Text(caution)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "hand.raised")
                            .foregroundStyle(hue)
                    }
                    .font(Theme.Typography.meta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .card(padding: Theme.Space.m)
                }

                if !terms.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        Text("Words from the tradition")
                            .font(Theme.Typography.eyebrow)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.Palette.inkTertiary)
                        ForEach(terms) { term in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(term.term)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(Theme.Palette.ink)
                                Text(term.meaning)
                                    .font(Theme.Typography.meta)
                                    .foregroundStyle(Theme.Palette.inkSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .card(padding: Theme.Space.m)
                }

                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("Practiced in Respire")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                    BreathShape(pattern: pattern, isLive: true)
                        .frame(height: 48)
                    HStack(spacing: Theme.Space.m) {
                        Label(section.theme.title, systemImage: section.theme.symbol)
                        Label(pattern.rhythmLabel, systemImage: "waveform.path")
                        Label("\(section.practice.minutes.formatted()) min", systemImage: "clock")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    if let date = library.practiced[dharana.number] {
                        Label("Last practiced \(date.formatted(.relative(presentation: .named)))", systemImage: "checkmark.circle")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(hue)
                    }
                }
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar(collection: collection, dharana: dharana)
        }
        .animation(.easeInOut(duration: 0.3), value: number)
    }

    /// Previous · Practice · Next, in the thumb zone.
    private func bottomBar(collection: DharanaCollection, dharana: Dharana) -> some View {
        let count = collection.allDharanas.count
        return HStack(spacing: Theme.Space.s) {
            Button {
                number = dharana.number > 1 ? dharana.number - 1 : count
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.tool)
            .accessibilityLabel("Previous gate")

            Button {
                practicing = dharana.number
            } label: {
                Label("Practice", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pill)
            .spectralEdge()

            Button {
                number = dharana.number < count ? dharana.number + 1 : 1
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.tool)
            .accessibilityLabel("Next gate")
        }
        .padding(Theme.Space.xs)
        .background { IceGlass(shape: Capsule(), frost: false) }
        .frame(maxWidth: 520)
        .padding(.horizontal, Theme.Space.page)
        .padding(.bottom, Theme.Space.xs)
    }
}

/// Practicing a gate: its section's world and rhythm, with the gate as the guiding line.
struct DharanaPracticeView: View {
    let number: Int

    @Environment(DharanaLibrary.self) private var library

    var body: some View {
        if let collection = library.collection,
           let dharana = collection.dharana(number: number),
           let section = collection.section(containing: number) {
            GuidedPracticeView(
                pattern: section.pattern(for: dharana),
                cycles: section.targetCycles(for: dharana),
                world: section.theme,
                focus: section.focus,
                title: "Gate \(dharana.number) · \(dharana.title)",
                guidance: dharana.text,
                gate: dharana,
                onComplete: { library.markPracticed(dharana) }
            ) { leave in
                CompletionCard(eyebrow: "Gate \(dharana.number) practiced", hue: Theme.prism[section.hue(in: collection)], title: dharana.title) {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Text("To carry with you")
                            .font(Theme.Typography.eyebrow)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.Palette.inkTertiary)
                        Text(dharana.text)
                            .font(.system(.title3, design: .serif).italic())
                            .foregroundStyle(Theme.Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button(action: leave) {
                        Text("Return to the gate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pill)
                }
            }
        }
    }
}

#Preview("Gate 2") {
    NavigationStack {
        DharanaDetailView(number: 2)
    }
    .environment(DharanaLibrary())
    .preferredColorScheme(.dark)
}
