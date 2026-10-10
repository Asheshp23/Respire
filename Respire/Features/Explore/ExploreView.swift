//
//  ExploreView.swift
//  Respire
//
//  The Library tab: everything in Respire as shelves to browse, like a record shop.
//  Guided sessions for whoever's breathing, Places, Courses, Rhythms, and the library
//  of 112 practices, with your week at a glance above them.
//
//  Also here: the persona menu, and where the home's stack can go.
//

import SwiftUI

/// Everything in Respire as shelves: guided sessions for whoever's breathing, Places,
/// Courses, Rhythms, and the library.
struct HomeShelves: View {
    @Environment(PatternLibrary.self) private var library
    @Environment(JourneyLibrary.self) private var journeys
    @Environment(JourneyProgressStore.self) private var progress
    @Environment(DharanaLibrary.self) private var practices
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults

    /// Children and the Wise breathe without holds.
    private var rhythms: [BreathPattern] {
        guard persona == .kids || persona == .wise else { return library.allPatterns }
        return library.allPatterns.filter { $0.holdFull == 0 && $0.holdEmpty == 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            NavigationLink(value: ExploreRoute.prescribe) {
                MakeSessionCard()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Space.page)

            Shelf(title: "Anchors", subtitle: "A minute away from the screen, with something real.") {
                ForEach(Anchor.all) { anchor in
                    NavigationLink(value: ExploreRoute.anchor(anchor.id)) {
                        AnchorShelfCard(anchor: anchor)
                    }
                }
            }

            Shelf(title: "Guided sessions", subtitle: persona.subtitle) {
                ForEach(Practice.practices(for: persona)) { practice in
                    NavigationLink(value: ExploreRoute.practice(practice.id)) {
                        PracticeCard(practice: practice)
                    }
                }
            }

            Shelf(title: "Places", subtitle: "A minute each. Every breath moves you one step.", seeAll: .places) {
                ForEach(Place.places(for: persona)) { place in
                    NavigationLink(value: ExploreRoute.place(place.id)) {
                        PlaceCard(place: place)
                    }
                }
            }

            // The courses walk the gates in grown-up words, so children don't see them.
            if persona != .kids {
                Shelf(title: "Courses", subtitle: "A few minutes a day, for five days.") {
                    ForEach(journeys.journeys.filter { $0.suits(persona) }) { journey in
                        NavigationLink(value: ExploreRoute.course(journey.id)) {
                            CourseCard(journey: journey, completed: progress.completedCount(in: journey))
                        }
                    }
                }
            }

            Shelf(title: "Rhythms", subtitle: "Just you and the breath, at a pace you choose.") {
                ForEach(rhythms) { pattern in
                    NavigationLink(value: ExploreRoute.rhythm(pattern.id)) {
                        RhythmCard(pattern: pattern)
                    }
                }
            }

            if let collection = practices.collection {
                NavigationLink(value: ExploreRoute.practices) {
                    LibraryCard(count: collection.allDharanas.count, practiced: practices.practiced.count, persona: persona)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Space.page)
            }
        }
    }
}

/// The Library tab: your week at a glance, then every shelf. Who's breathing sits in the bar.
struct ExploreView: View {
    @Environment(SessionViewModel.self) private var session
    @State private var isShowingPractice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                WeekStrip(history: session.history) { isShowingPractice = true }
                    .padding(.horizontal, Theme.Space.page)
                HomeShelves()
            }
            .padding(.vertical, Theme.Space.m)
        }
        .paperBackground()
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { PersonaMenu() }
        }
        .sheet(isPresented: $isShowingPractice) {
            NavigationStack {
                YouView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { isShowingPractice = false }
                        }
                    }
            }
        }
        .respireDestinations()
    }
}

/// The last seven days as quiet dots, and how many sessions; opens your practice.
private struct WeekStrip: View {
    let history: SessionHistory
    var action: () -> Void

    var body: some View {
        let week = history.week()
        let totals = history.lastSevenDays()
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        Button(action: action) {
            HStack(spacing: Theme.Space.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This week")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                    Text(totals.sessions == 0 ? "A minute is enough" : "\(totals.sessions) \(totals.sessions == 1 ? "session" : "sessions") · \(totals.minutes) min")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.ink)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(week, id: \.day) { day in
                        Circle()
                            .fill(day.practiced ? Theme.prism[3] : Theme.Palette.inkTertiary.opacity(0.3))
                            .frame(width: 9, height: 9)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
            .padding(Theme.Space.m)
            .frame(minHeight: Theme.minTapTarget)
            .background { IceGlass(shape: shape, frost: false) }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("This week: \(totals.sessions) sessions, \(totals.minutes) minutes")
        .accessibilityHint("Opens your practice")
        .accessibilityAddTraits(.isButton)
    }
}

/// Who's breathing, as one small glass button that opens a menu.
struct PersonaMenu: View {
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults

    var body: some View {
        Menu {
            Picker("Who's breathing", selection: $persona) {
                ForEach(Persona.allCases) { option in
                    Label(option.title, systemImage: option.symbol).tag(option)
                }
            }
        } label: {
            HStack(spacing: Theme.Space.xs) {
                Image(systemName: persona.symbol)
                Text("For \(persona.title.lowercased())")
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(Theme.Typography.label)
            .foregroundStyle(Theme.Palette.ink)
        }
        .accessibilityLabel("Who's breathing: \(persona.title)")
    }
}

// MARK: - Shelf

/// A titled row of cards that scrolls sideways, snapping card by card.
private struct Shelf<Content: View>: View {
    let title: String
    var subtitle: String?
    var seeAll: ExploreRoute?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                    }
                }
                Spacer(minLength: 0)
                if let seeAll {
                    NavigationLink("See all", value: seeAll)
                        .font(Theme.Typography.label)
                }
            }
            .padding(.horizontal, Theme.Space.page)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: Theme.Space.s) {
                    content
                        .buttonStyle(.plain)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Theme.Space.page, for: .scrollContent)
        }
    }
}

// MARK: - Cards

private let cardShape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)

/// A guided session: its world as the picture, and what it's for.
private struct PracticeCard: View {
    let practice: Practice

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PracticeCanvas(practice: practice, frame: PlaceFrame(progress: 2.4, steps: practice.breaths, openness: 0.6, time: 3))
                .allowsHitTesting(false)
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Label(practice.category.title, systemImage: practice.category.symbol)
                    .font(Theme.Typography.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.8))
                Text(practice.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(practice.lengthLabel + (practice.hums ? " · humming" : ""))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(Theme.Space.s)
        }
        .frame(width: 210, height: 150)
        .clipShape(cardShape)
        .overlay { cardShape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
        .accessibilityHint(practice.summary)
    }
}

/// The way into a session made for how you feel right now.
private struct MakeSessionCard: View {
    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: "wand.and.sparkles")
                .font(.title2)
                .foregroundStyle(Theme.prism[3])
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Make my session")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                Text("A few quick questions, safety first, then a session made for how you feel.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)
        }
        .padding(Theme.Space.m)
        .background { IceGlass(shape: cardShape, frost: false) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
    }
}

/// An anchor on the shelf: its sense, its name, and what to notice.
private struct AnchorShelfCard: View {
    let anchor: Anchor

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Image(systemName: anchor.sense.symbol)
                .font(.title2)
                .foregroundStyle(Theme.prism[(Anchor.all.firstIndex(of: anchor) ?? 0) % Theme.prism.count])
            Spacer(minLength: 0)
            Text(anchor.title)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(2)
            Text(anchor.sense.title)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .padding(Theme.Space.s)
        .frame(width: 150, alignment: .topLeading)
        .frame(minHeight: 150, alignment: .topLeading)
        .background { IceGlass(shape: cardShape, frost: false) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
        .accessibilityHint(anchor.invitation)
    }
}

private struct PlaceCard: View {
    let place: Place

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlaceCanvas(place: place, frame: .still(steps: place.steps, at: 0.6))
                .allowsHitTesting(false)
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
            Text(place.title)
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(Theme.Space.s)
        }
        .frame(width: 150, height: 150)
        .clipShape(cardShape)
        .overlay { cardShape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
        .accessibilityHint(place.psychologicalGoal)
    }
}

private struct CourseCard: View {
    let journey: Journey
    let completed: Int

    private var hue: Color { Theme.prism[journey.hue % Theme.prism.count] }

    var body: some View {
        let total = journey.chapters.count
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Image(systemName: journey.symbol)
                .font(.title2)
                .foregroundStyle(hue)
            Spacer(minLength: 0)
            Text(journey.title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            // Five quiet dots: a day each.
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { day in
                    Circle()
                        .fill(day < completed ? hue : Theme.Palette.inkTertiary.opacity(0.35))
                        .frame(width: 6, height: 6)
                }
            }
            Text(completed == 0 ? "\(total) days" : (completed >= total ? "Finished" : "Day \(completed + 1) of \(total)"))
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .padding(Theme.Space.m)
        // Grows for larger text rather than clipping the title or the days.
        .frame(width: 200, alignment: .topLeading)
        .frame(minHeight: 150, alignment: .topLeading)
        .background { IceGlass(shape: cardShape, frost: false) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
    }
}

private struct RhythmCard: View {
    let pattern: BreathPattern

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            BreathShape(pattern: pattern)
                .frame(height: 40)
            Spacer(minLength: 0)
            Text(pattern.name)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
            RhythmTiming(pattern: pattern)
        }
        .padding(Theme.Space.m)
        .frame(width: 170, height: 130, alignment: .topLeading)
        .background { IceGlass(shape: cardShape, frost: false) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pattern.name). \(pattern.timingLabel)")
    }
}

private struct LibraryCard: View {
    let count: Int
    let practiced: Int
    let persona: Persona

    private var title: String {
        persona == .kids ? "Little practices: \(count) to try" : "The library: \(count) practices"
    }

    private var detail: String {
        let about = switch persona {
        case .kids: "Tiny ways to notice your breath, your body, and the world."
        case .teens: "Short practices for focus and calm, from an ancient tradition."
        case .adults, .wise: "Short meditations from the Vijñāna Bhairava Tantra."
        }
        return practiced > 0 ? "\(practiced) practiced. \(about)" : about
    }

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: "books.vertical")
                .font(.title2)
                .foregroundStyle(Theme.prism[4])
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                Text(detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)
        }
        .padding(Theme.Space.m)
        .background { IceGlass(shape: cardShape, frost: false) }
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Destinations

extension View {
    /// Where the home's stack can go.
    func respireDestinations() -> some View {
        navigationDestination(for: ExploreRoute.self) { route in
            RespireDestination(route: route)
        }
        .navigationDestination(for: Int.self) { number in
            DharanaDetailView(number: number)
        }
    }
}

private struct RespireDestination: View {
    let route: ExploreRoute

    @Environment(PatternLibrary.self) private var library
    @Environment(JourneyLibrary.self) private var journeys

    var body: some View {
        switch route {
        case .practice(let id):
            if let practice = Practice.practice(id: id) {
                PracticeSessionView(practice: practice)
            }
        case .place(let id):
            if let place = Place.place(id: id) {
                PlaceSessionView(place: place)
            }
        case .course(let id):
            if let journey = journeys.journey(id: id) {
                JourneyMapView(journey: journey)
            }
        case .rhythm(let id):
            SessionView(rhythm: library.pattern(id: id))
        case .places:
            PlacesView()
        case .practices:
            DharanaLibraryView()
        case .oneMinute:
            SessionView(rhythm: .calm, allowsOpening: false, length: 1)
        case .anchor(let id):
            if let anchor = Anchor.anchor(id: id) {
                AnchorView(anchor: anchor)
            }
        case .prescribe:
            PrescribeView()
        }
    }
}

#Preview {
    NavigationStack { ExploreView() }
        .environment(PatternLibrary())
        .environment(SessionViewModel())
        .environment(JourneyLibrary())
        .environment(JourneyProgressStore())
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
