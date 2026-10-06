//
//  OpeningView.swift
//  Respire
//
//  The personalized opening, set over the breathing world. One line at a time in
//  a large serif: each glyph surfaces from a soft blur and settles into place, as
//  if the words were being breathed onto the glass, then the line dissolves
//  before the next arrives. With Reduce Motion, each line simply fades in whole.
//

import Accessibility
import SwiftUI

struct OpeningView: View {
    let player: OpeningPlayer
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            Spacer(minLength: 0)

            Group {
                switch player.stage {
                case .gathering, .composing:
                    PreparingLine(isComposing: player.stage == .composing)
                        .transition(.opacity)
                case .playing, .finished:
                    if let line = player.currentLine {
                        TypewriterLine(
                            text: line,
                            startedAt: player.lineStartedAt,
                            duration: player.currentLineDuration
                        )
                        .id(player.currentIndex)
                    }
                }
            }
            .frame(maxWidth: 640, minHeight: 220)
            .padding(.horizontal, Theme.Space.l)

            Spacer(minLength: 0)

            footer
        }
        .padding(.bottom, Theme.Space.l)
        .animation(.easeInOut(duration: 0.6), value: player.stage)
        .onChange(of: player.currentIndex) { _, _ in announceCurrentLine() }
        .onChange(of: player.stage) { _, stage in
            if stage == .playing { announceCurrentLine() }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Theme.Space.s) {
            HStack(spacing: Theme.Space.m) {
                progressDots
                Button("Skip") { onSkip() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, Theme.Space.l)
                    .frame(minHeight: Theme.minTapTarget)
                    .background { IceGlass(shape: Capsule(), frost: false) }
                    .contentShape(Capsule())
                    .buttonStyle(.plain)
                    .accessibilityHint("Begins breathing now")
            }

            HStack(spacing: Theme.Space.xs) {
                if let source = player.source {
                    Label(
                        source == .onDeviceModel ? "Written on this device with Apple Intelligence" : "Composed on this device",
                        systemImage: source == .onDeviceModel ? "apple.intelligence" : "lock.shield"
                    )
                }
                if let credit = player.weatherCredit {
                    WeatherCreditView(credit: credit)
                }
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(.white.opacity(0.55))
        }
    }

    /// Five quiet marks that fill in the prism's colors as the opening moves along.
    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<OpeningPlayer.expectedLines, id: \.self) { index in
                let isDone = player.stage == .playing && index < player.currentIndex
                let isCurrent = player.stage == .playing && index == player.currentIndex
                Circle()
                    .fill(isDone ? Theme.prism[(index * 2) % Theme.prism.count] : .white.opacity(isCurrent ? 0.85 : 0.2))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Line \(min(player.currentIndex + 1, OpeningPlayer.expectedLines)) of \(OpeningPlayer.expectedLines)")
    }

    private func announceCurrentLine() {
        guard let line = player.currentLine else { return }
        AccessibilityNotification.Announcement(line).post()
    }
}

// MARK: - Lines

/// One line of the opening, revealed glyph by glyph and dissolved at the end of its time.
private struct TypewriterLine: View {
    let text: String
    let startedAt: Date
    let duration: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startedAt)
            let fadeOut = min(max((duration - elapsed) / OpeningPlayer.fadeOutDuration, 0), 1)

            Text(text)
                .font(.system(.title, design: .serif))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .textRenderer(TypewriterRenderer(
                    revealed: reduceMotion ? .infinity : elapsed * OpeningPlayer.typingRate,
                    opacity: reduceMotion ? 1 : fadeOut
                ))
                .shadow(color: .black.opacity(0.6), radius: 14)
        }
        // With Reduce Motion the timeline is paused and the whole line is drawn at once;
        // this transition (animated by the parent) fades each line in and out instead.
        .transition(.opacity)
    }
}

/// While context gathers and the model starts writing: a single, slowly breathing phrase.
private struct PreparingLine: View {
    let isComposing: Bool

    @State private var isBright = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(isComposing ? "Finding the words for this moment" : "Listening to this moment")
            .font(.system(.title3, design: .serif).italic())
            .foregroundStyle(.white.opacity(isBright ? 0.8 : 0.4))
            .shadow(color: .black.opacity(0.5), radius: 10)
            .contentTransition(.opacity)
            .onAppear {
                guard !reduceMotion else { isBright = true; return }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isBright = true
                }
            }
    }
}

/// WeatherKit's required attribution: the Apple Weather mark, linking to its legal page.
private struct WeatherCreditView: View {
    let credit: WeatherCredit

    var body: some View {
        Link(destination: credit.legalURL) {
            AsyncImage(url: credit.markURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Text("Weather")
            }
            .frame(height: 11)
        }
        .accessibilityLabel("Apple Weather, data sources")
    }
}

// MARK: - Renderer

/// Draws text so that glyphs appear one after another: each fades up from a soft
/// blur and rises a few points into place over `softness` glyphs. Layout is computed
/// once for the whole line, so nothing reflows while it types.
struct TypewriterRenderer: TextRenderer {
    /// How many glyphs have been revealed (fractional for smooth motion).
    var revealed: Double
    /// Opacity for the whole line, for fading it out.
    var opacity: Double = 1
    var softness: Double = 6

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var index = 0.0
        for line in layout {
            for run in line {
                for glyph in run {
                    let progress = min(max((revealed - index) / softness, 0), 1)
                    index += 1
                    guard progress > 0 else { continue }

                    var copy = context
                    copy.opacity = progress * opacity
                    if progress < 1 {
                        copy.addFilter(.blur(radius: (1 - progress) * 5))
                        copy.translateBy(x: 0, y: (1 - progress) * 6)
                    }
                    copy.draw(glyph)
                }
            }
        }
    }
}

#Preview("Opening, mid-line") {
    ZStack {
        BreathWorldScene(theme: .rain, openness: 0.3, time: 2)
            .ignoresSafeArea()
        OpeningView(
            player: .preview(lines: [
                "Tuesday evening settles like quiet weight on the bones.",
                "Feel the steady touch of the ground beneath you.",
                "Light rain whispers a cool touch across the skin.",
                "About eighty-four beats move through you, steady and soft.",
                "Breathe in for six, letting breath fold into the belly.",
            ], index: 2, elapsed: 1.4),
            onSkip: {}
        )
    }
    .preferredColorScheme(.dark)
}
