//
//  BreatheView.swift
//  Respire
//
//  The Breathe tab: the breathing rhythms, each with a picture of one breath, and
//  the one-minute Places as quick breaks.
//

import SwiftUI

struct BreatheView: View {
    @Environment(PatternLibrary.self) private var library

    var body: some View {
        List {
            Section {
                ForEach(library.allPatterns) { pattern in
                    NavigationLink(value: BreatheRoute.rhythm(pattern.id)) {
                        RhythmRow(pattern: pattern)
                    }
                }
            } header: {
                Text("Breathing")
            } footer: {
                Text("Each session begins with a short spoken settling-in, then a soft breath sound guides you. Both can be turned off in Settings.")
            }

            Section {
                NavigationLink(value: BreatheRoute.places) {
                    PlacesRow()
                }
            } header: {
                Text("Quick breaks")
            } footer: {
                Text("About a minute each. Every breath moves you one step through a small illustrated place.")
            }
        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle("Breathe")
        .navigationDestination(for: BreatheRoute.self) { route in
            switch route {
            case .rhythm(let id):
                SessionView(rhythm: library.pattern(id: id))
            case .places:
                PlacesView()
            }
        }
    }
}

/// A rhythm: a picture of one breath, its name and counts, and what it's for.
private struct RhythmRow: View {
    let pattern: BreathPattern

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            BreathShape(pattern: pattern)
                .frame(width: 64, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Text(pattern.summary)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                RhythmTiming(pattern: pattern)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pattern.name). \(pattern.summary). \(pattern.timingLabel)")
    }
}

/// The rhythm in plain timings, with a dot breathing at its pace.
struct RhythmTiming: View {
    let pattern: BreathPattern

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            BreathPulse(pattern: pattern, size: 12)
            Text(pattern.timingLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
    }
}

private struct PlacesRow: View {
    var body: some View {
        let today = Place.placeOfTheDay()
        HStack(spacing: Theme.Space.m) {
            PlaceCanvas(place: today, frame: .still(steps: today.steps, at: 0.6))
                .frame(width: 64, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Places")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Text("\(Place.all.count) short visits · today, \(today.title)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { BreatheView() }
        .environment(PatternLibrary())
        .environment(SessionViewModel())
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
