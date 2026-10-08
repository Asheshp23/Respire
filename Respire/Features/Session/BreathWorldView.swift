//
//  BreathWorldView.swift
//  Respire
//
//  The chosen breath world, alive and breathing with the engine. The engine's
//  eased lung volume becomes the world's `openness` (0 empty, 1 full), so the
//  lotus opens, the tide comes in, and the candle flame rises in exact step with
//  the rhythm and the haptics.
//
//  Every world is drawn in code relative to its canvas, so it fills an iPhone or
//  a full-screen iPad without losing detail.
//

import SwiftUI

struct BreathWorldView: View {
    let theme: BreathTheme
    let engine: BreathEngine
    /// The world's own breathing light. Off while the session's circle is the guide,
    /// so there's only one thing growing and shrinking.
    var showsFocusLight = true

    /// World time starts when the view appears, keeping shader inputs small and precise.
    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            let openness = openness(at: timeline.date, elapsed: elapsed)
            let time = reduceMotion ? 0 : elapsed

            ZStack {
                BreathWorldScene(theme: theme, openness: openness, time: time, stillness: stillness(at: timeline.date))
                // Each world's own light, swelling and settling with the breath.
                SceneFocus(theme: theme, openness: openness, time: time)
                    .opacity(showsFocusLight ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: showsFocusLight)
                    .allowsHitTesting(false)
                // During a hold the world dims a little and brightens again, so stillness looks still.
                Color.black
                    .opacity(holdDim(at: timeline.date))
                    .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
    }

    private func holdDim(at date: Date) -> Double {
        // In Cymatics the hold is when the figure settles: the moment to see it, not dim it.
        guard !reduceMotion, theme != .cymatics, engine.state == .running || engine.state == .paused else { return 0 }
        let snapshot = engine.snapshot(at: date)
        guard snapshot.phase == .holdFull || snapshot.phase == .holdEmpty else { return 0 }
        return 0.18 * sin(.pi * snapshot.phaseProgress)
    }

    /// How still the breath is: 1 in holds and at the turns, falling to 0 mid-breath,
    /// where the eased lung volume moves fastest.
    private func stillness(at date: Date) -> Double {
        guard !reduceMotion, engine.state == .running else { return 1 }
        let snapshot = engine.snapshot(at: date)
        switch snapshot.phase {
        case .holdFull, .holdEmpty: return 1
        case .inhale, .exhale: return 1 - sin(.pi * snapshot.phaseProgress)
        }
    }

    private func openness(at date: Date, elapsed: TimeInterval) -> Double {
        // With Reduce Motion the world holds still at a calm half-breath; the words guide.
        if reduceMotion { return 0.6 }
        switch engine.state {
        case .running, .paused:
            return engine.snapshot(at: date).lungVolume
        case .idle, .finished:
            // Before and after a session the world rests, swaying very slowly.
            return 0.3 + 0.1 * sin(elapsed * 0.5)
        }
    }
}

/// One world at a given openness and time. Pure, so previews and thumbnails can use it.
struct BreathWorldScene: View {
    let theme: BreathTheme
    var openness: Double
    var time: Double
    /// 1 when the breath is still (its turns and holds); only Cymatics uses it.
    var stillness: Double = 1

    var body: some View {
        switch theme {
        case .aurora: AuroraLakeScene(openness: openness, time: time)
        case .ocean: OceanTideScene(openness: openness, time: time)
        case .sakura: SakuraMoonScene(openness: openness, time: time)
        case .desert: DesertStarsScene(openness: openness, time: time)
        case .waterfall: WaterfallScene(openness: openness, time: time)
        case .volcano: VolcanoScene(openness: openness, time: time)
        case .rain: RainScene(openness: openness, time: time)
        case .wind: WindScene(openness: openness, time: time)
        case .thunder: ThunderScene(openness: openness, time: time)
        case .cymatics: CymaticsScene(openness: openness, time: time, stillness: stillness)
        }
    }
}

#Preview("Aurora, idle") {
    BreathWorldView(theme: .aurora, engine: BreathEngine(pattern: .box))
        .ignoresSafeArea()
}
