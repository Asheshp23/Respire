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

    /// World time starts when the view appears, keeping shader inputs small and precise.
    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            let openness = openness(at: timeline.date, elapsed: elapsed)
            let time = reduceMotion ? 0 : elapsed

            ZStack {
                BreathWorldScene(theme: theme, openness: openness, time: time)
                // Each world's own light, swelling and settling with the breath.
                SceneFocus(theme: theme, openness: openness, time: time)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
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
        }
    }
}

#Preview("Aurora, idle") {
    BreathWorldView(theme: .aurora, engine: BreathEngine(pattern: .box))
        .ignoresSafeArea()
}
