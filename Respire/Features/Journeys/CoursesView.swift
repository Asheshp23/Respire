//
//  CoursesView.swift
//  Respire
//
//  The Courses tab: the five-day courses, and the library of 112 practices.
//

import SwiftUI

struct CoursesView: View {
    @Environment(JourneyLibrary.self) private var journeys
    @Environment(JourneyProgressStore.self) private var progress
    @Environment(DharanaLibrary.self) private var practices

    var body: some View {
        List {
            Section {
                ForEach(journeys.journeys) { journey in
                    NavigationLink(value: CoursesRoute.course(journey.id)) {
                        CourseRow(journey: journey, completed: progress.completedCount(in: journey))
                    }
                }
            } header: {
                Text("Courses")
            } footer: {
                Text("A few minutes a day. Each day opens the morning after the one before.")
            }

            if let collection = practices.collection {
                Section {
                    NavigationLink(value: CoursesRoute.practices) {
                        LibraryRow(count: collection.allDharanas.count, practiced: practices.practiced.count)
                    }
                } header: {
                    Text("Library")
                } footer: {
                    Text("Short meditations adapted from the Vijñāna Bhairava Tantra, an old text on ways of placing attention.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle("Courses")
        .navigationDestination(for: CoursesRoute.self) { route in
            switch route {
            case .course(let id):
                if let journey = journeys.journey(id: id) {
                    JourneyMapView(journey: journey)
                }
            case .practices:
                DharanaLibraryView()
            }
        }
        .navigationDestination(for: Int.self) { number in
            DharanaDetailView(number: number)
        }
    }
}

/// A course: its symbol inside a ring of how far along you are, its title, and the day you're on.
private struct CourseRow: View {
    let journey: Journey
    let completed: Int

    private var hue: Color { Theme.prism[journey.hue % Theme.prism.count] }
    private var fraction: Double { Double(completed) / Double(max(journey.chapters.count, 1)) }

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            ZStack {
                Circle().stroke(.white.opacity(0.12), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(hue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
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
                Text(status)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        let total = journey.chapters.count
        if completed == 0 { return "\(total) days" }
        if completed >= total { return "Finished · \(total) of \(total) days" }
        return "Day \(completed + 1) of \(total)"
    }
}

private struct LibraryRow: View {
    let count: Int
    let practiced: Int

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: "books.vertical")
                .font(.title3)
                .foregroundStyle(Theme.prism[4])
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) Practices")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Text(practiced > 0 ? "\(practiced) practiced" : "Start with the foundations")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { CoursesView() }
        .environment(JourneyLibrary())
        .environment(JourneyProgressStore())
        .environment(DharanaLibrary())
        .environment(SessionViewModel())
        .preferredColorScheme(.dark)
}
