//
//  JourneyMapView.swift
//  Respire
//
//  A journey's home: its story, its progress, and the winding path of days.
//
//  - Wide canvases (iPad full screen or a large split): the map on the leading
//    side, the selected day's story cards beside it.
//  - Compact (iPhone, slide-over): the map scrolls, a Continue bar sits in the
//    thumb zone, and a day's cards open in a sheet.
//
//  States are re-evaluated every minute, so a gate opens at midnight even while
//  the map is on screen.
//

import SwiftUI

struct JourneyMapView: View {
    let journey: Journey

    @Environment(JourneyProgressStore.self) private var progress

    @State private var selectedID: JourneyChapter.ID?
    @State private var sheetChapter: JourneyChapter?
    @State private var pendingPractice: JourneyChapter?
    @State private var practicing: JourneyChapter?
    @State private var isWide = false
    @State private var showsOrigin = false

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let states = progress.states(in: journey, now: timeline.date)
            Group {
                if isWide {
                    wideLayout(states: states)
                } else {
                    compactLayout(states: states)
                }
            }
        }
        .paperBackground()
        .onGeometryChange(for: Bool.self) { $0.size.width >= 760 } action: { isWide = $0 }
        .navigationTitle(journey.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheetChapter, onDismiss: startPendingPractice) { chapter in
            NavigationStack {
                StoryCardStack(
                    journey: journey,
                    chapter: chapter,
                    state: progress.state(of: chapter, in: journey),
                    onBeginPractice: {
                        pendingPractice = chapter
                        sheetChapter = nil
                    }
                )
                .padding(Theme.Space.page)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .paperBackground()
                .navigationTitle("Day \(chapter.day)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", systemImage: "xmark") { sheetChapter = nil }
                    }
                }
            }
            .presentationDetents([.large])
        }
        .navigationDestination(item: $practicing) { chapter in
            JourneyPracticeView(journey: journey, chapter: chapter)
        }
    }

    // MARK: - Layouts

    private func wideLayout(states: [ChapterState]) -> some View {
        let chapter = focusedChapter
        return HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    header(states: states)
                    path(states: states)
                }
                .padding(.vertical, Theme.Space.l)
            }
            .frame(width: 440)

            StoryCardStack(
                journey: journey,
                chapter: chapter,
                state: state(of: chapter, in: states),
                onBeginPractice: { practicing = chapter }
            )
            .frame(maxWidth: 560, maxHeight: 760)
            .padding(Theme.Space.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func compactLayout(states: [ChapterState]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                header(states: states)
                path(states: states)
            }
            .padding(.vertical, Theme.Space.l)
        }
        .safeAreaInset(edge: .bottom) {
            continueBar(states: states)
        }
    }

    private func path(states: [ChapterState]) -> some View {
        JourneyPathView(
            journey: journey,
            states: states,
            selectedID: isWide ? focusedChapter.id : nil,
            onSelect: { chapter in
                if isWide {
                    withAnimation(.easeInOut(duration: 0.3)) { selectedID = chapter.id }
                } else {
                    sheetChapter = chapter
                }
            }
        )
    }

    // MARK: - Header

    private func header(states: [ChapterState]) -> some View {
        let completed = states.count { $0.isCompleted }

        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Journey · \(journey.chapters.count) days")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(JourneyPathView.hue(for: 0, in: journey))

            Text(journey.title)
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(journey.summary)
                .font(Theme.Typography.note)
                .lineSpacing(Theme.Typography.noteLineSpacing)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Theme.Space.s) {
                HStack(spacing: 4) {
                    ForEach(states.indices, id: \.self) { index in
                        Capsule()
                            .fill(states[index].isCompleted
                                  ? AnyShapeStyle(JourneyPathView.hue(for: index, in: journey))
                                  : AnyShapeStyle(.white.opacity(0.15)))
                            .frame(height: 4)
                    }
                }
                Text("\(completed) of \(states.count)")
                    .font(Theme.Typography.meta.monospacedDigit())
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(completed) of \(states.count) days complete")

            if let origin = journey.origin {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { showsOrigin.toggle() }
                    } label: {
                        Label(origin.title, systemImage: showsOrigin ? "chevron.down" : "chevron.right")
                            .font(Theme.Typography.label)
                            .foregroundStyle(Theme.Palette.accent)
                            .frame(minHeight: Theme.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if showsOrigin {
                        Text(origin.body)
                            .font(Theme.Typography.meta)
                            .lineSpacing(3)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .card(padding: Theme.Space.m)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Space.page)
    }

    // MARK: - Continue bar

    /// The next step, always within reach of a thumb.
    private func continueBar(states: [ChapterState]) -> some View {
        let next = progress.nextChapter(in: journey)
        let nextState = next.map { state(of: $0, in: states) }
        let isFinished = next == nil
        let completed = states.count { $0.isCompleted }

        return HStack(spacing: Theme.Space.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(next.map { "Day \($0.day) · \($0.title)" } ?? "All \(journey.chapters.count) days complete")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text(continueDetail(isFinished: isFinished, state: nextState))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Space.xs)
            Button {
                sheetChapter = next ?? journey.chapters.last
            } label: {
                Text(isFinished ? "Revisit" : (nextState?.isOpen == true ? (completed == 0 ? "Begin" : "Continue") : "Preview"))
            }
            .buttonStyle(.pill)
            .spectralEdge(nextState == .available)
        }
        .padding(.leading, Theme.Space.l)
        .padding(.trailing, Theme.Space.s)
        .padding(.vertical, Theme.Space.s)
        .background { IceGlass(shape: Capsule(), frost: false) }
        .padding(.horizontal, Theme.Space.page)
        .padding(.bottom, Theme.Space.xs)
    }

    private func continueDetail(isFinished: Bool, state: ChapterState?) -> String {
        if isFinished { return "Every day stays open to practice again" }
        switch state {
        case .available: return "Open now"
        case .opensTomorrow: return "Opens tomorrow"
        case .locked: return "Waiting"
        case .completed, nil: return ""
        }
    }

    // MARK: - Helpers

    /// The day shown beside the map: the one chosen, else the next to walk, else the last.
    private var focusedChapter: JourneyChapter {
        selectedID.flatMap(journey.chapter(id:))
            ?? progress.nextChapter(in: journey)
            ?? journey.chapters[journey.chapters.count - 1]
    }

    private func state(of chapter: JourneyChapter, in states: [ChapterState]) -> ChapterState {
        journey.chapters.firstIndex(of: chapter).map { states[$0] } ?? .locked
    }

    private func startPendingPractice() {
        guard let chapter = pendingPractice else { return }
        pendingPractice = nil
        practicing = chapter
    }
}

#Preview("Journey map") {
    let journeys = JourneyLibrary()
    let progress = JourneyProgressStore(defaults: UserDefaults(suiteName: "preview.journey")!)
    if let journey = journeys.journeys.first {
        // Day 1 done yesterday, so day 2 is open.
        let _ = progress.complete(journey.chapters[0], in: journey, at: .now.addingTimeInterval(-86_400))
        NavigationStack {
            JourneyMapView(journey: journey)
        }
        .environment(progress)
        .environment(journeys)
        .preferredColorScheme(.dark)
    }
}
