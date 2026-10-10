//
//  PlacesView.swift
//  Respire
//
//  Every Place in a fluid grid: two across on iPhone, up to five on iPad.
//  Today's place leads. Each tile is a still frame of its drawing.
//

import SwiftUI

struct PlacesView: View {
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults

    private var places: [Place] { Place.places(for: persona) }

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: Theme.Space.s)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("\(places.count) places · about a minute each")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.prism[1])
                    Text("Places")
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Little destinations you breathe your way through. Each breath moves you one step: a new platform, a moth found, a lantern lit.")
                        .font(Theme.Typography.note)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 680, alignment: .leading)

                LazyVGrid(columns: columns, spacing: Theme.Space.s) {
                    ForEach(places) { place in
                        NavigationLink(value: place) {
                            PlaceTile(place: place, isToday: place == Place.placeOfTheDay(persona: persona))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .paperBackground()
        .navigationTitle("Places")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Place.self) { place in
            PlaceSessionView(place: place)
        }
    }
}

struct PlaceTile: View {
    let place: Place
    var isToday = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        ZStack(alignment: .bottomLeading) {
            PlaceCanvas(place: place, frame: .still(steps: place.steps, at: 0.6))
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                if isToday {
                    Text("Today")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(place.tint)
                }
                Label(place.title, systemImage: place.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(place.mechanicLabel)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(Theme.Space.s)
        }
        .frame(height: 210)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                isToday ? AnyShapeStyle(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center)) : AnyShapeStyle(.white.opacity(0.12)),
                lineWidth: isToday ? 2 : 1
            )
        }
        .contentShape(shape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(place.title). \(place.summary). \(place.durationLabel)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("All places") {
    NavigationStack { PlacesView() }
        .environment(SessionViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Contact sheet 1–10") { PlaceContactSheet(range: 0..<10) }
#Preview("Contact sheet 11–20") { PlaceContactSheet(range: 10..<20) }
#Preview("Contact sheet 21–29") { PlaceContactSheet(range: 20..<Place.all.count) }
#Preview("Singing Bowl Temple, stages") {
    // Before, midway, and with all seven bowls singing.
    VStack(spacing: 4) {
        ForEach([0.0, 3.6, 7.0], id: \.self) { progress in
            if let temple = Place.place(id: "bowl-temple") {
                PlaceCanvas(place: temple, frame: PlaceFrame(progress: progress, steps: temple.steps, openness: 0.7, time: 6))
                    .frame(height: 260)
                    .clipped()
            }
        }
    }
    .background(.black)
}

/// Every drawing at a glance, for checking art.
private struct PlaceContactSheet: View {
    let range: Range<Int>
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
            ForEach(Place.all[range]) { place in
                PlaceCanvas(place: place, frame: .still(steps: place.steps, at: 0.6))
                    .frame(height: 150)
                    .overlay(alignment: .bottomLeading) {
                        Text(place.title).font(.caption2.bold()).foregroundStyle(.white).shadow(radius: 2).padding(4)
                    }
                    .clipped()
            }
        }
        .background(.black)
        .ignoresSafeArea()
    }
}
