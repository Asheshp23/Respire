//
//  TodayView.swift
//  Respire
//
//  The home, made for someone who's stressed: two zones and nothing else.
//
//  1. The anchor. A minute pointed away from the screen, at something every person
//     shares: the sky, old starlight, the ground, a heartbeat. Chosen for the hour,
//     set in the hour's own scene. The whole card is the button.
//  2. The relief bar. Calm, Sleep, Focus: one word each, one tap each, straight into
//     the right session. The order follows the hour (Focus first in the morning, Sleep
//     at night), and the sessions behind them, and their scenes, change from day to day.
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
                    // Zone 1: a minute away from the screen, with something every person shares.
                    let anchor = Anchor.ofTheMoment(at: timeline.date)
                    AnchorHero(anchor: anchor, date: timeline.date, persona: persona,
                               moment: Self.salutation(at: timeline.date)) {
                        library.visit(.anchor(anchor.id))
                    }
                    .containerRelativeFrame(.vertical) { height, _ in height * 0.62 }

                    // Zone 2: instant relief, by how you feel, in the order this hour calls for.
                    ReliefBar(persona: persona, date: timeline.date) { practice in
                        library.start(.practice(practice.id), in: session)
                    }

                    // The quickest way in: one minute, no settling-in, breathing at once.
                    OneMinuteButton {
                        library.start(.oneMinute, in: session)
                    }
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.vertical, Theme.Space.m)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // The card shows the scene; behind it, only its colors.
        .paperBackground(softened: true)
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

/// The anchor for this moment: the hour's own scene, what to notice, and one tap to begin.
/// It asks you to look away from the screen, so the card is calm and says so.
private struct AnchorHero: View {
    let anchor: Anchor
    let date: Date
    let persona: Persona
    let moment: String
    var action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)

        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // The scene itself, on a solid ground: the screen's own backdrop is see-through,
                // and showed a second moon and mountain behind the card.
                Color.black
                SceneThumbnail(theme: .current(at: date, persona: persona))
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)

                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("\(moment) · About a minute")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(anchor.title)
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(anchor.invitation)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: Theme.Space.xs) {
                        Image(systemName: "eye")
                        Text("Then look up from the screen")
                    }
                    .font(Theme.Typography.label)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Space.m)
                    .frame(minHeight: Theme.minTapTarget)
                    .background(.white.opacity(0.16), in: Capsule())
                    .padding(.top, Theme.Space.xs)
                }
                .shadow(color: .black.opacity(0.4), radius: 6)
                .padding(Theme.Space.l)
            }
            .clipShape(shape)
            .overlay { shape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(anchor.title). \(anchor.invitation)")
        .accessibilityHint("About a minute, with the screen dimmed")
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

/// Calm, Sleep, Focus: three equal cards, one word each, each starting the right
/// session for whoever's breathing. The hour orders them; the day picks the sessions.
private struct ReliefBar: View {
    let persona: Persona
    let date: Date
    var start: (Practice) -> Void

    /// One session per need, each different from the others when there are enough to go round.
    private var choices: [(need: Need, practice: Practice)] {
        let order = Need.relief(at: date)
        // The need with the fewest sessions chooses first, so it isn't left with a repeat.
        var used = Set<Practice.ID>()
        var picked: [Need: Practice] = [:]
        for need in order.sorted(by: { Practice.candidates(for: $0, persona: persona).count < Practice.candidates(for: $1, persona: persona).count }) {
            guard let practice = Practice.recommended(for: need, persona: persona, on: date, excluding: used) else { continue }
            used.insert(practice.id)
            picked[need] = practice
        }
        return order.compactMap { need in picked[need].map { (need, $0) } }
    }

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            ForEach(choices, id: \.need) { choice in
                ReliefButton(need: choice.need, practice: choice.practice) { start(choice.practice) }
                    .accessibilityHint("Begins \(choice.practice.title)")
            }
        }
        .animation(.easeInOut(duration: 0.4), value: Need.relief(at: date))
    }
}

/// A small, still window onto the session's scene, with its one word.
private struct ReliefButton: View {
    let need: Need
    let practice: Practice
    var action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        Button(action: action) {
            ZStack(alignment: .bottom) {
                PracticeCanvas(practice: practice, frame: PlaceFrame(
                    progress: 2.4, steps: practice.breaths, openness: 0.55, time: 3))
                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                // Low on the card, so the scene's own subject (a balloon, a moon) shows above it.
                HStack(spacing: Theme.Space.xxs) {
                    Image(systemName: need.symbol)
                        .font(.subheadline.weight(.semibold))
                    Text(need.word)
                        .font(Theme.Typography.label)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4)
                .padding(.bottom, Theme.Space.s)
            }
            .frame(maxWidth: .infinity, minHeight: 104, maxHeight: 104)
            .clipShape(shape)
            .overlay { shape.strokeBorder(.white.opacity(0.14), lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(need.word)
    }
}

/// One minute of breathing, for when there's no time for anything else.
private struct OneMinuteButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Just one minute", systemImage: "timer")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.ink)
                .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget + 4)
                .background { IceGlass(shape: Capsule(), frost: false) }
                .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint("Begins one minute of calm breathing right away")
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
