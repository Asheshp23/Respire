//
//  DharanaLibraryView.swift
//  Respire
//
//  The 112 Gates, in nine sections. Today's gate leads; the rest sit in fluid grids
//  that run from a single column on iPhone to three or four across a full iPad,
//  and reflow as a split-screen window resizes. Search by words or by number.
//

import SwiftUI

struct DharanaLibraryView: View {
    @Environment(DharanaLibrary.self) private var library

    @State private var query = ""
    @State private var sectionFilter: DharanaSection.ID?
    @State private var showsAttribution = false
    @State private var isShowingMoments = false

    private let columns = [GridItem(.adaptive(minimum: 250, maximum: 420), spacing: Theme.Space.s)]

    var body: some View {
        Group {
            if let collection = library.collection {
                content(collection)
            } else {
                ContentUnavailableView("The gates couldn't be loaded", systemImage: "exclamationmark.triangle")
            }
        }
        .paperBackground()
        .navigationTitle("Practices")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Moments", systemImage: "bell") { isShowingMoments = true }
                    .accessibilityHint("Daily reminders for waking, between tasks, and bedtime")
            }
        }
        .sheet(isPresented: $isShowingMoments) {
            MomentRemindersSheet()
        }
    }

    private func content(_ collection: DharanaCollection) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Space.xl) {
                header(collection)

                if query.isEmpty, sectionFilter == nil, let today = library.gateOfTheDay(),
                   let section = collection.section(containing: today.number) {
                    TodayGateCard(dharana: today, section: section, hue: Theme.prism[section.hue(in: collection)])
                }

                sectionChips(collection)

                let sections = filteredSections(in: collection)
                if sections.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                ForEach(sections, id: \.section.id) { entry in
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SectionHeader(section: entry.section, hue: Theme.prism[entry.section.hue(in: collection)])
                        LazyVGrid(columns: columns, spacing: Theme.Space.s) {
                            ForEach(entry.dharanas) { dharana in
                                NavigationLink(value: dharana.number) {
                                    DharanaTile(
                                        dharana: dharana,
                                        hue: Theme.prism[entry.section.hue(in: collection)],
                                        isPracticed: library.isPracticed(dharana)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.vertical, Theme.Space.l)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .searchable(text: $query, prompt: library.persona == .kids ? "Search" : "Search the gates")
    }

    // MARK: - Header

    private func header(_ collection: DharanaCollection) -> some View {
        let practiced = library.practiced.count
        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("\(collection.allDharanas.count) \(library.persona == .kids ? "practices" : "dharanas") · \(practiced) practiced")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Theme.prism[4])
            Text(collection.title)
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(collection.subtitle)
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.inkSecondary)

            // Where the gates come from is for grown-ups; children just practice.
            if library.persona != .kids {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { showsAttribution.toggle() }
                } label: {
                    Label("About this synthesis", systemImage: showsAttribution ? "chevron.down" : "chevron.right")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.accent)
                        .frame(minHeight: Theme.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showsAttribution {
                    Text(collection.attribution)
                        .font(Theme.Typography.meta)
                        .lineSpacing(3)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .card(padding: Theme.Space.m)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(maxWidth: 720, alignment: .leading)
    }

    // MARK: - Filtering

    private func sectionChips(_ collection: DharanaCollection) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.xs) {
                chip("All", isSelected: sectionFilter == nil) { sectionFilter = nil }
                ForEach(collection.sections) { section in
                    chip("\(section.numeral) · \(shortTitle(section))", isSelected: sectionFilter == section.id) {
                        sectionFilter = sectionFilter == section.id ? nil : section.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { action() }
        } label: {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Theme.Palette.onInk : Theme.Palette.ink)
                .padding(.horizontal, Theme.Space.m)
                .frame(minHeight: Theme.minTapTarget)
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

    /// "Breath & Neural Pacing" → "Breath"; enough to recognize a section in a chip.
    private func shortTitle(_ section: DharanaSection) -> String {
        let first = section.title.components(separatedBy: CharacterSet(charactersIn: "&,:")).first ?? section.title
        return first.replacingOccurrences(of: "The ", with: "").trimmingCharacters(in: .whitespaces)
    }

    private func filteredSections(in collection: DharanaCollection) -> [(section: DharanaSection, dharanas: [Dharana])] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        return collection.sections.compactMap { section in
            guard sectionFilter == nil || sectionFilter == section.id else { return nil }
            let matches = needle.isEmpty ? section.dharanas : section.dharanas.filter { dharana in
                String(dharana.number) == needle
                    || dharana.title.lowercased().contains(needle)
                    || dharana.text.lowercased().contains(needle)
            }
            return matches.isEmpty ? nil : (section, matches)
        }
    }
}

// MARK: - Pieces

/// Today's gate, with its world as art and a direct way in.
private struct TodayGateCard: View {
    let dharana: Dharana
    let section: DharanaSection
    let hue: Color

    @Environment(DharanaLibrary.self) private var library
    private var word: String { library.gateWord }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)

        NavigationLink(value: dharana.number) {
            ViewThatFits(in: .horizontal) {
                // Wide: art beside the words.
                HStack(spacing: 0) {
                    art.frame(width: 340)
                    words.frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 220)
                // Narrow: art above.
                VStack(alignment: .leading, spacing: 0) {
                    art.frame(height: 170)
                    words
                }
            }
            .background { IceGlass(shape: shape, frost: false) }
            .clipShape(shape)
            .overlay { shape.strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 1.5).opacity(0.7) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's \(word.lowercased()), number \(dharana.number): \(dharana.title). \(dharana.text)")
    }

    private var art: some View {
        BreathWorldScene(theme: section.theme, openness: 0.6, time: 3)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(library.persona == .kids ? "Today's practice" : "Today's \(word.lowercased()) · \(dharana.number)")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(hue)
            Text(dharana.title)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
            Text(dharana.text)
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("Open", systemImage: "arrow.right")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.accent)
                .padding(.top, Theme.Space.xxs)
        }
        .padding(Theme.Space.l)
    }
}

private struct SectionHeader: View {
    let section: DharanaSection
    let hue: Color

    @Environment(DharanaLibrary.self) private var library
    private var persona: Persona { library.persona }

    var body: some View {
        let pattern = section.pattern(for: section.dharanas[0])
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(persona == .kids
                 ? "\(section.dharanas.count) practices"
                 : "\(section.numeral) · Gates \(section.range.lowerBound)–\(section.range.upperBound)")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(hue)
            Text(section.title)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(section.subtitle)
                .font(Theme.Typography.meta)
                .foregroundStyle(Theme.Palette.inkSecondary)
            HStack(spacing: Theme.Space.m) {
                Label(section.theme.title, systemImage: section.theme.symbol)
                Label(pattern.rhythmLabel, systemImage: "waveform.path")
                Label("\(section.practice.minutes.formatted()) min", systemImage: "clock")
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Palette.inkTertiary)
            .padding(.top, 2)
        }
        .padding(.top, Theme.Space.s)
    }
}

/// A gate in the grid: its number in the section's hue, title, and the practice in brief.
private struct DharanaTile: View {
    let dharana: Dharana
    let hue: Color
    let isPracticed: Bool

    @Environment(DharanaLibrary.self) private var library

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)

        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(dharana.number)")
                    .font(.system(.title3, design: .serif, weight: .semibold).monospacedDigit())
                    .foregroundStyle(hue)
                Spacer(minLength: 0)
                if isPracticed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(hue)
                        .accessibilityLabel("Practiced")
                }
                if dharana.caution != nil {
                    Image(systemName: "hand.raised")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                        .accessibilityLabel("Has a safety note")
                }
            }
            Text(dharana.title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(dharana.text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            if let level = dharana.level {
                Label(level.title, systemImage: level.symbol)
                    .font(Theme.Typography.caption.weight(.medium))
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
        }
        .padding(Theme.Space.m)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background { IceGlass(shape: shape, frost: false) }
        .overlay(alignment: .leading) {
            // A thread of the section's color down the leading edge.
            Capsule().fill(hue.opacity(0.8)).frame(width: 3).padding(.vertical, Theme.Space.m)
        }
        .contentShape(shape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(library.gateWord) \(dharana.number), \(dharana.title)\(dharana.level.map { ", \($0.title)" } ?? "")\(isPracticed ? ", practiced" : "")")
        .accessibilityHint(dharana.text)
    }
}

#Preview("112 Gates") {
    NavigationStack {
        DharanaLibraryView()
    }
    .environment(DharanaLibrary())
    .environment(MomentReminders())
    .preferredColorScheme(.dark)
}

#Preview("For kids") {
    let gates = DharanaLibrary()
    gates.persona = .kids
    return NavigationStack {
        DharanaLibraryView()
    }
    .environment(gates)
    .environment(MomentReminders())
    .preferredColorScheme(.dark)
}

#Preview("For the Wise") {
    let gates = DharanaLibrary()
    gates.persona = .wise
    return NavigationStack {
        DharanaLibraryView()
    }
    .environment(gates)
    .environment(MomentReminders())
    .preferredColorScheme(.dark)
}
