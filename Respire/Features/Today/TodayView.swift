//
//  TodayView.swift
//  Respire
//
//  The day's starting point, and where the app opens. One big button that starts
//  breathing straight away. Beneath it, quietly, two other ways in: today's Place
//  and the journey in progress. Nothing else, so there's never a question of where to begin.
//

import SwiftUI

struct TodayView: View {
    @Environment(PatternLibrary.self) private var library
    @Environment(JourneyLibrary.self) private var journeys
    @Environment(JourneyProgressStore.self) private var progress
    @Environment(SessionViewModel.self) private var session
    @AppStorage(SessionFocus.storageKey) private var focus: SessionFocus = .calmAnxiety

    @State private var breathingPlace: Place?

    private let columns = [GridItem(.adaptive(minimum: 300), spacing: Theme.Space.m, alignment: .top)]

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    greeting(at: timeline.date)
                    StartBreathingCard(action: startBreathing)

                    Text("Or")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                        .padding(.top, Theme.Space.s)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Space.m) {
                        PlaceOfTheDayCard(place: Place.placeOfTheDay(for: timeline.date)) {
                            breathingPlace = Place.placeOfTheDay(for: timeline.date)
                        }
                        if let journey = currentJourney {
                            ContinueJourneyCard(journey: journey, now: timeline.date) {
                                library.openCourse(journey.id)
                            }
                        }
                    }
                }
                .padding(Theme.Space.page)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .paperBackground()
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $breathingPlace) { place in
            PlaceSessionView(place: place)
        }
    }

    /// Opens a free session in the rhythm that suits the person's focus, already starting.
    private func startBreathing() {
        library.open(focus.recommendedPattern, beginsAtOnce: true, in: session)
    }

    // MARK: - Greeting

    private func greeting(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(date.formatted(.dateTime.weekday(.wide).month().day()))
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.inkTertiary)
            Text(Self.salutation(at: date))
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Tap start, close your eyes, and follow the sound.")
                .font(Theme.Typography.note)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
    }

    static func salutation(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "A quiet night"
        }
    }

    // MARK: - Journey

    /// The journey in progress; else the first one not yet finished; else the first.
    private var currentJourney: Journey? {
        let all = journeys.journeys
        return all.first { progress.completedCount(in: $0) > 0 && progress.nextChapter(in: $0) != nil }
            ?? all.first { progress.nextChapter(in: $0) != nil }
            ?? all.first
    }
}

// MARK: - Cards

/// The one obvious first step: breathing starts the moment it's tapped. It shows the
/// chosen world you'll breathe in.
private struct StartBreathingCard: View {
    var action: () -> Void

    @AppStorage(BreathTheme.storageKey) private var theme: BreathTheme = .aurora
    @AppStorage(SessionFocus.storageKey) private var focus: SessionFocus = .calmAnxiety
    @AppStorage("session.minutes") private var minutes = 3

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
        let length = minutes > 0 ? "\(minutes) min" : "As long as you like"

        Button(action: action) {
            ZStack {
                BreathWorldScene(theme: theme, openness: 0.5, time: 3)
                    .allowsHitTesting(false)
                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)

                VStack(spacing: Theme.Space.s) {
                    Spacer(minLength: 0)
                    Label("Start breathing", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.Palette.onInk)
                        .padding(.horizontal, Theme.Space.l)
                        .frame(minHeight: Theme.minTapTarget + 8)
                        .background(Theme.Palette.ink, in: Capsule())
                        .spectralEdge()
                    Text("\(length) · \(focus.title)")
                        .font(Theme.Typography.meta)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(Theme.Space.l)
            }
            .frame(height: 300)
            .clipShape(shape)
            .overlay { shape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Start breathing, \(length), \(focus.title)")
        .accessibilityHint("Starts right away. Close your eyes: breathe in as the sound rises, out as it falls.")
        .accessibilityAddTraits(.isButton)
    }
}

/// Today's Place, offered quietly as another way in.
private struct PlaceOfTheDayCard: View {
    let place: Place
    var action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)

        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                PlaceCanvas(place: place, frame: .still(steps: place.steps, at: 0.6))
                    .allowsHitTesting(false)
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text("Today's place")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(place.title)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(.white)
                    Text(place.durationLabel)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(Theme.Space.m)
            }
            .frame(height: 120)
            .clipShape(shape)
            .overlay { shape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("A short visit where each breath moves you one step")
    }
}

private struct ContinueJourneyCard: View {
    let journey: Journey
    let now: Date
    var action: () -> Void

    @Environment(JourneyProgressStore.self) private var progress

    var body: some View {
        let next = progress.nextChapter(in: journey)
        let chapter = next ?? journey.chapters[journey.chapters.count - 1]
        let index = journey.chapters.firstIndex(of: chapter) ?? 0
        let state = progress.state(of: chapter, in: journey, now: now)
        let completed = progress.completedCount(in: journey)

        Button(action: action) {
            HStack(alignment: .top, spacing: Theme.Space.m) {
                JourneyNode(day: chapter.day, state: state, hue: JourneyPathView.hue(for: index, in: journey))
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text(completed == 0 ? "Begin a journey" : (next == nil ? "Journey complete" : "Continue"))
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(JourneyPathView.hue(for: index, in: journey))
                    Text(journey.title)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                    Text("Day \(chapter.day) · \(chapter.title)")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                    Text(stateText(state, isFinished: next == nil))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .card(padding: Theme.Space.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the journey map")
    }

    private func stateText(_ state: ChapterState, isFinished: Bool) -> String {
        if isFinished { return "Every day stays open to practice again" }
        switch state {
        case .available: return "Open now"
        case .opensTomorrow: return "Opens tomorrow"
        case .locked: return "Waiting"
        case .completed: return "Done"
        }
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environment(PatternLibrary())
    .environment(JourneyLibrary())
    .environment(JourneyProgressStore(defaults: UserDefaults(suiteName: "preview.today")!))
    .environment(DharanaLibrary())
    .environment(MomentReminders(defaults: UserDefaults(suiteName: "preview.today.moments")!))
    .environment(SessionViewModel())
    .preferredColorScheme(.dark)
}
