//
//  StoryCardStack.swift
//  Respire
//
//  A day's story told as a small deck of cards: an image, what to notice, the
//  practice. The next cards peek out beneath the top one. Move through them by
//  swiping, tapping the left or right side of the card, or the buttons in the
//  bottom thumb zone. With VoiceOver, swipe up or down; with a keyboard, use the
//  arrow keys. The last card's action begins the day's practice.
//

import SwiftUI

struct StoryCardStack: View {
    let journey: Journey
    let chapter: JourneyChapter
    let state: ChapterState
    var onBeginPractice: () -> Void

    @State private var index = 0
    @State private var dragOffset: CGFloat = 0
    @State private var cardWidth: CGFloat = 360
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cards: [StoryCard] {
        state.isOpen ? chapter.cards : [waitingCard]
    }

    private var isLast: Bool { index >= cards.count - 1 }

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            segments

            ZStack {
                ForEach(visibleIndices.reversed(), id: \.self) { cardIndex in
                    let depth = CGFloat(cardIndex - index)
                    StoryCardView(card: cards[cardIndex], chapter: chapter, journey: journey, showsArt: depth < 2)
                        // Cards behind shrink from the bottom edge and drop a little, so their
                        // lower edges peek out beneath the top card.
                        .scaleEffect(1 - 0.05 * depth, anchor: .bottom)
                        .offset(y: 12 * depth)
                        .offset(x: depth == 0 ? dragOffset : 0)
                        .rotationEffect(.degrees(depth == 0 && !reduceMotion ? Double(dragOffset / 30) : 0), anchor: .bottom)
                        .opacity(depth == 0 ? 1 : 0.75 - 0.25 * Double(depth))
                        .allowsHitTesting(depth == 0)
                }
            }
            .padding(.bottom, 28) // room for the cards peeking beneath
            .contentShape(Rectangle())
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cardWidth = $0 }
            .gesture(swipe)
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    value.location.x < cardWidth * 0.33 ? back() : forward()
                }
            )
            .accessibilityElement(children: .combine)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: forward()
                case .decrement: back()
                @unknown default: break
                }
            }
            .accessibilityHint("Swipe up or down to move between cards")

            controls
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.rightArrow) { forward(); return .handled }
        .onKeyPress(.leftArrow) { back(); return .handled }
        .onChange(of: chapter.id) { _, _ in
            index = 0
            dragOffset = 0
        }
        .sensoryFeedback(.selection, trigger: index)
    }

    private var visibleIndices: [Int] {
        Array(index..<min(index + 3, cards.count))
    }

    // MARK: - Progress

    /// One segment per card, filled up to the current one.
    private var segments: some View {
        HStack(spacing: 4) {
            ForEach(cards.indices, id: \.self) { cardIndex in
                Capsule()
                    .fill(cardIndex <= index ? AnyShapeStyle(hue) : AnyShapeStyle(.white.opacity(0.18)))
                    .frame(height: 3)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: index)
        .accessibilityHidden(true)
    }

    private var hue: Color {
        JourneyPathView.hue(for: journey.chapters.firstIndex(of: chapter) ?? 0, in: journey)
    }

    // MARK: - Controls

    /// In the bottom third, where a thumb rests: back, position, and the next step.
    private var controls: some View {
        HStack(spacing: Theme.Space.s) {
            Button {
                back()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.tool)
            .disabled(index == 0)
            .accessibilityLabel("Previous card")

            Text("\(index + 1) of \(cards.count)")
                .font(Theme.Typography.meta.monospacedDigit())
                .foregroundStyle(Theme.Palette.inkTertiary)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            if !state.isOpen {
                Label(state == .opensTomorrow ? "Opens tomorrow" : "Not yet", systemImage: state == .opensTomorrow ? "sunrise" : "lock")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .frame(minHeight: Theme.minTapTarget)
            } else if isLast {
                Button(action: onBeginPractice) {
                    Label(state.isCompleted ? "Practice again" : "Begin practice", systemImage: "play.fill")
                }
                .buttonStyle(.pill)
                .spectralEdge()
            } else {
                Button("Next") { forward() }
                    .buttonStyle(.pill)
            }
        }
    }

    // MARK: - Navigation

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Resist at the ends of the deck.
                let atEdge = (value.translation.width < 0 && isLast) || (value.translation.width > 0 && index == 0)
                dragOffset = atEdge ? value.translation.width * 0.25 : value.translation.width
            }
            .onEnded { value in
                let travel = value.predictedEndTranslation.width
                if travel < -cardWidth * 0.35, !isLast {
                    forward()
                } else if travel > cardWidth * 0.35, index > 0 {
                    back()
                } else {
                    withAnimation(.spring(duration: 0.35, bounce: 0.3)) { dragOffset = 0 }
                }
            }
    }

    private func forward() {
        guard !isLast else { return }
        guard !reduceMotion else {
            withAnimation(.easeInOut(duration: 0.25)) { index += 1; dragOffset = 0 }
            return
        }
        // Throw the top card off to the left, then reveal the next one already in place.
        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = -cardWidth * 1.3
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                index += 1
                dragOffset = 0
            }
        }
    }

    private func back() {
        guard index > 0 else { return }
        guard !reduceMotion else {
            withAnimation(.easeInOut(duration: 0.25)) { index -= 1; dragOffset = 0 }
            return
        }
        // Bring the previous card back in from the left.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            index -= 1
            dragOffset = -cardWidth * 1.3
        }
        withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
            dragOffset = 0
        }
    }

    // MARK: - Waiting

    private var waitingCard: StoryCard {
        let index = journey.chapters.firstIndex(of: chapter) ?? 0
        let previous = index > 0 ? journey.chapters[index - 1].day : chapter.day - 1
        if state == .opensTomorrow {
            return StoryCard(
                kind: .image,
                eyebrow: "Day \(chapter.day)",
                title: "Let today settle",
                body: "You walked day \(previous) today. Give it the rest of the day to settle; this gate opens tomorrow. Any day you've already walked is open to practice again, as often as you like.",
                openness: 0.15
            )
        }
        return StoryCard(
            kind: .image,
            eyebrow: "Day \(chapter.day)",
            title: "Waiting for you",
            body: "This gate opens after you've completed day \(previous). There's no hurry and no streak to keep. The path will be here whenever you return.",
            openness: 0.05
        )
    }
}

// MARK: - Card

/// One card: the chapter's world as art, then the words.
struct StoryCardView: View {
    let card: StoryCard
    let chapter: JourneyChapter
    let journey: Journey
    var showsArt = true

    private var hue: Color {
        JourneyPathView.hue(for: journey.chapters.firstIndex(of: chapter) ?? 0, in: journey)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)

        VStack(alignment: .leading, spacing: 0) {
            art
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .clipped()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text(card.eyebrow)
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(hue)
                    Text(card.title)
                        .font(.system(.title, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(card.body)
                        .font(Theme.Typography.note)
                        .lineSpacing(Theme.Typography.noteLineSpacing)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let cue = card.cue {
                        HStack(spacing: Theme.Space.s) {
                            Rectangle()
                                .fill(hue)
                                .frame(width: 2)
                            Text(cue)
                                .font(.system(.title3, design: .serif).italic())
                                .foregroundStyle(Theme.Palette.ink)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Space.xs)
                        .accessibilityLabel("Cue: \(cue)")
                    }

                    if card.kind == .practice {
                        practiceSummary
                    }
                }
                .padding(Theme.Space.l)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: 560)
        .background { IceGlass(shape: shape, frost: false) }
        .clipShape(shape)
        .overlay { shape.strokeBorder(.white.opacity(0.12), lineWidth: 1) }
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }

    @ViewBuilder
    private var art: some View {
        if showsArt {
            BreathWorldScene(theme: chapter.theme, openness: card.openness ?? 0.5, time: 3)
                .allowsHitTesting(false)
                .overlay(alignment: .bottom) {
                    // Melt the picture into the glass below.
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                }
                .accessibilityHidden(true)
        } else {
            Color.black.opacity(0.3)
        }
    }

    private var practiceSummary: some View {
        let pattern = chapter.pattern(in: journey)
        return VStack(alignment: .leading, spacing: Theme.Space.xs) {
            BreathShape(pattern: pattern, isLive: true)
                .frame(height: 52)
            HStack(spacing: Theme.Space.m) {
                Label(pattern.rhythmLabel, systemImage: "waveform.path")
                Label("\(chapter.practice.minutes.formatted()) min", systemImage: "clock")
                Label(chapter.theme.title, systemImage: chapter.theme.symbol)
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Palette.inkSecondary)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.top, Theme.Space.xs)
    }
}

extension JourneyChapter {
    /// The breath world this day is set in.
    var theme: BreathTheme { BreathTheme(rawValue: world) ?? .aurora }
}

#Preview("Story cards") {
    if let journey = JourneyLibrary().journeys.first(where: { $0.id == "the-unprompted-mind" }) {
        StoryCardStack(journey: journey, chapter: journey.chapters[3], state: .available, onBeginPractice: {})
            .padding()
            .paperBackground()
            .preferredColorScheme(.dark)
    }
}
