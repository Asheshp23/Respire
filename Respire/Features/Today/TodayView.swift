//
//  TodayView.swift
//  Respire
//
//  The home, made for someone who's stressed: two zones and nothing else.
//
//  1. The primary card. One session chosen for this hour and whoever's breathing,
//     its scene gently breathing. The whole card is the button: one tap, and the
//     session begins.
//  2. The relief bar. Calm, Sleep, Focus: one word each, one tap each, straight into
//     the right session.
//
//  Courses, rhythms, places, and the library live in the Library tab.
//

import SwiftUI

struct TodayView: View {
    @Environment(PatternLibrary.self) private var library
    @Environment(SessionViewModel.self) private var session
    @AppStorage(Persona.storageKey) private var persona: Persona = .adults

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            ScrollView {
                VStack(spacing: Theme.Space.l) {
                    // Zone 1: one unmissable session for right now.
                    if let practice = Practice.suggestion(at: timeline.date, persona: persona) {
                        PrimaryCard(practice: practice, moment: Self.salutation(at: timeline.date)) {
                            library.start(.practice(practice.id), in: session)
                        }
                        .containerRelativeFrame(.vertical) { height, _ in height * 0.66 }
                    }

                    // Zone 2: instant relief, by how you feel.
                    ReliefBar(persona: persona) { practice in
                        library.start(.practice(practice.id), in: session)
                    }
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.vertical, Theme.Space.m)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .paperBackground()
        .toolbar(.hidden, for: .navigationBar)
        .respireDestinations()
    }

    static func salutation(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "A quiet night"
        }
    }
}

// MARK: - Zone 1

/// The one session to begin with. Its scene breathes slowly while it waits; the whole
/// card is a single button.
private struct PrimaryCard: View {
    let practice: Practice
    let moment: String
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)

        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // The scene, breathing at an easy resting pace while it waits.
                TimelineView(.animation(paused: reduceMotion)) { timeline in
                    let t = timeline.date.timeIntervalSince(start)
                    PracticeCanvas(practice: practice, frame: PlaceFrame(
                        progress: 2.4, steps: practice.breaths,
                        openness: reduceMotion ? 0.6 : 0.5 + 0.3 * sin(t * 2 * .pi / 10),
                        time: reduceMotion ? 3 : t))
                }
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)

                HStack(alignment: .bottom, spacing: Theme.Space.m) {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Text("\(moment) · \(practice.lengthLabel)")
                            .font(Theme.Typography.eyebrow)
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(practice.title)
                            .font(.system(.largeTitle, design: .serif))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Palette.onInk)
                        .frame(width: 64, height: 64)
                        .background(Theme.Palette.ink, in: Circle())
                        .spectralEdge()
                }
                .padding(Theme.Space.l)
            }
            .clipShape(shape)
            .overlay { shape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(practice.title), \(practice.lengthLabel)")
        .accessibilityHint("Begins right away. \(practice.summary)")
        .accessibilityAddTraits(.isButton)
    }
}

/// A soft press: the card sinks a little under the finger.
private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Zone 2

/// Calm, Sleep, Focus: three equal buttons, one word each, each starting the right
/// session for whoever's breathing.
private struct ReliefBar: View {
    let persona: Persona
    var start: (Practice) -> Void

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            ForEach(Need.relief) { need in
                if let practice = Practice.recommended(for: need, persona: persona) {
                    ReliefButton(need: need) { start(practice) }
                        .accessibilityHint("Begins \(practice.title)")
                }
            }
        }
    }
}

private struct ReliefButton: View {
    let need: Need
    var action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        Button(action: action) {
            VStack(spacing: Theme.Space.xs) {
                // A fixed box, so every word sits on the same line whatever the icon's shape.
                Image(systemName: need.symbol)
                    .font(.title3)
                    .frame(height: 28)
                Text(need.word)
                    .font(Theme.Typography.label)
            }
            .foregroundStyle(Theme.Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background { IceGlass(shape: shape, frost: false) }
            .contentShape(shape)
        }
        .buttonStyle(PressableCardStyle())
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environment(PatternLibrary())
    .environment(JourneyLibrary())
    .environment(JourneyProgressStore())
    .environment(DharanaLibrary())
    .environment(SessionViewModel())
    .preferredColorScheme(.dark)
}
