//
//  PatternListView.swift
//  Respire
//
//  Everything in the app on one list: Today, Places, the practice library, courses,
//  and the rhythms. Each row opens its place in the tabs.
//

import SwiftUI

struct PatternListView: View {
    @Environment(PatternLibrary.self) private var library
    @Environment(JourneyLibrary.self) private var journeys
    @Environment(JourneyProgressStore.self) private var progress
    @Environment(DharanaLibrary.self) private var gates
    @Environment(SessionViewModel.self) private var session

    var body: some View {
        List {
            Section {
                TodayRow(isSelected: library.tab == .today) { library.tab = .today }
            }

            if let collection = gates.collection {
                Section {
                    PlacesRow(isSelected: false) {
                        var path = NavigationPath()
                        path.append(BreatheRoute.places)
                        library.breathePath = path
                        library.tab = .breathe
                    }
                    GatesRow(
                        collection: collection,
                        practiced: gates.practiced.count,
                        isSelected: false
                    ) {
                        var path = NavigationPath()
                        path.append(CoursesRoute.practices)
                        library.coursesPath = path
                        library.tab = .courses
                    }
                } header: {
                    sectionHeader("Explore")
                }
            }

            if !journeys.journeys.isEmpty {
                Section {
                    ForEach(journeys.journeys) { journey in
                        JourneyRow(
                            journey: journey,
                            completed: progress.completedCount(in: journey),
                            isSelected: false
                        ) { library.openCourse(journey.id) }
                    }
                } header: {
                    sectionHeader("Journeys")
                }
            }

            Section {
                ForEach(library.presets) { pattern in
                    PatternRow(pattern: pattern, isSelected: false) { library.open(pattern, in: session) }
                }
            } header: {
                sectionHeader("How to breathe")
            }

            Section {
                PatternRow(pattern: library.custom, isSelected: false) { library.open(library.custom, in: session) }
            } header: {
                sectionHeader("Your own")
            }
        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle("Respire")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.meta.weight(.semibold))
            .foregroundStyle(.white.opacity(0.7))
            .textCase(.uppercase)
    }
}

/// A rhythm as a picture of its breath, with its name, counts in its hue, and purpose.
private struct PatternRow: View {
    let pattern: BreathPattern
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                BreathShape(pattern: pattern, isLive: isSelected)
                    .frame(height: 44)
                HStack(alignment: .firstTextBaseline) {
                    Text(pattern.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Spacer(minLength: 0)
                    Text(pattern.rhythmLabel)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(pattern.hue)
                }
                Text(pattern.summary)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            .padding(.vertical, Theme.Space.xxs)
        }
        .listRowBackground(
            IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 2)
                    }
                }
                .padding(.vertical, 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pattern.name), \(pattern.rhythmLabel) seconds. \(pattern.summary)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A journey in the sidebar: its symbol, title, and how far along the path you are.
private struct JourneyRow: View {
    let journey: Journey
    let completed: Int
    let isSelected: Bool
    var action: () -> Void

    private var hue: Color { Theme.prism[journey.hue % Theme.prism.count] }
    private var fraction: Double { Double(completed) / Double(max(journey.chapters.count, 1)) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                ZStack {
                    Circle().stroke(.white.opacity(0.12), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: journey.symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(hue)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(journey.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text(statusText)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
            }
            .padding(.vertical, Theme.Space.xxs)
        }
        .listRowBackground(
            IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 2)
                    }
                }
                .padding(.vertical, 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var statusText: String {
        let total = journey.chapters.count
        if completed == 0 { return "\(total) days · Begin" }
        if completed >= total { return "Complete · \(total) of \(total) days" }
        return "Day \(completed + 1) of \(total)"
    }
}

/// The 112 Gates library in the sidebar, with today's gate.
private struct GatesRow: View {
    let collection: DharanaCollection
    let practiced: Int
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        let today = collection.dharanaOfTheDay(practicedCount: practiced)
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                ZStack {
                    Circle()
                        .fill(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center))
                        .opacity(0.85)
                    Text("112")
                        .font(.system(.caption, design: .serif, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(collection.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text(today.map { "Today: \($0.number) · \($0.title)" } ?? collection.subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                    if practiced > 0 {
                        Text("\(practiced) practiced")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Palette.inkTertiary)
                    }
                }
            }
            .padding(.vertical, Theme.Space.xxs)
        }
        .listRowBackground(
            IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 2)
                    }
                }
                .padding(.vertical, 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Today: the day's starting point.
private struct TodayRow: View {
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
            } icon: {
                Image(systemName: "sun.horizon")
                    .font(.title3)
                    .foregroundStyle(Theme.prism[1])
                    .frame(width: 44, height: 44)
            }
            .padding(.vertical, Theme.Space.xxs)
        }
        .listRowBackground(
            IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 2)
                    }
                }
                .padding(.vertical, 3)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Places: twenty little destinations, one step per breath.
private struct PlacesRow: View {
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        let today = Place.placeOfTheDay()
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                PlaceCanvas(place: today, frame: .still(steps: today.steps, at: 0.6))
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Places")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text("Today: \(today.title)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, Theme.Space.xxs)
        }
        .listRowBackground(
            IceGlass(shape: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous), frost: false)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 2)
                    }
                }
                .padding(.vertical, 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
