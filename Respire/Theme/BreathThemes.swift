//
//  BreathThemes.swift
//  Respire
//
//  Places to breathe. Each theme is a whole world drawn in code, with one thing
//  in it that breathes with you:
//
//  - Aurora Lake   Canadian Rockies under the northern lights; a lotus opens.
//                  (Drawn in AuroraLake.swift, where the lotus lives.)
//  - Ocean Tide    a dusk sea; the tide washes up the beach as you breathe in
//                  and draws back as you breathe out.
//  - Sakura Moon   a full moon over Mount Fuji; cherry blossoms open, petals
//                  drift onto a moonlit pond.
//  - Desert Stars  the Milky Way over moonlit dunes; a candle flame rises with
//                  the in-breath and settles with the out-breath.
//
//  Five more live in NatureThemes.swift: Hidden Falls, Ember Peak, Rain Pond,
//  Prairie Wind, and Distant Storm. Cymatics, sound made visible on water,
//  lives in CymaticsScene.swift.
//
//  The chosen theme is remembered, and the app's quiet background takes on a
//  still version of the same world (`ThemeBackdrop`). In Respire, `openness` is
//  the breath engine's lung volume, so every world follows the chosen rhythm.
//

import SwiftUI

// MARK: - Theme

enum BreathTheme: String, CaseIterable, Identifiable {
    case aurora, ocean, sakura, desert, waterfall, volcano, rain, wind, thunder, cymatics
    // Daylight, drawn from the bright Places.
    case meadow, alpine, seaside, garden, forest, lake

    static let storageKey = "breath.theme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: "Aurora Lake"
        case .ocean: "Ocean Tide"
        case .sakura: "Sakura Moon"
        case .desert: "Desert Stars"
        case .waterfall: "Hidden Falls"
        case .volcano: "Ember Peak"
        case .rain: "Rain Pond"
        case .wind: "Prairie Wind"
        case .thunder: "Distant Storm"
        case .cymatics: "Cymatics"
        case .meadow: "Kite Meadow"
        case .alpine: "Alpine Lake"
        case .seaside: "Seaside"
        case .garden: "Garden Morning"
        case .forest: "Sunlit Forest"
        case .lake: "Morning Lake"
        }
    }

    var symbol: String {
        switch self {
        case .aurora: "sparkles"
        case .ocean: "water.waves"
        case .sakura: "camera.macro"
        case .desert: "flame"
        case .waterfall: "drop.fill"
        case .volcano: "mountain.2.fill"
        case .rain: "cloud.rain"
        case .wind: "wind"
        case .thunder: "cloud.bolt.rain"
        case .cymatics: "circle.hexagongrid"
        case .meadow: "wind"
        case .alpine: "mountain.2"
        case .seaside: "sun.max"
        case .garden: "bird"
        case .forest: "tree"
        case .lake: "sun.horizon"
        }
    }

    /// The guiding line under each phase, in this world's own images.
    /// `nil` is the quiet moment before the first breath.
    func detail(for phase: BreathPhase?) -> String {
        switch (self, phase) {
        case (.aurora, nil): "The lotus waits for your first breath."
        case (.aurora, .inhale): "Slowly, and let the lotus open."
        case (.aurora, .holdFull): "Notice the stillness at the top."
        case (.aurora, .exhale): "Long and easy, as it folds closed."
        case (.aurora, .holdEmpty): "Rest in the quiet before the next breath."
        case (.ocean, nil): "Breathe with the tide."
        case (.ocean, .inhale): "Breathe in as the wave comes in."
        case (.ocean, .holdFull): "Hold softly, like water at the turn."
        case (.ocean, .exhale): "Let it slide back out to sea."
        case (.ocean, .holdEmpty): "Rest in the hush between waves."
        case (.sakura, nil): "Breathe under the moon."
        case (.sakura, .inhale): "Breathe in, and let the blossoms open."
        case (.sakura, .holdFull): "Still, like moonlight on the pond."
        case (.sakura, .exhale): "Breathe out as the petals drift."
        case (.sakura, .holdEmpty): "Rest in the quiet of the garden."
        case (.desert, nil): "Breathe beneath the stars."
        case (.desert, .inhale): "Breathe in, and let the flame rise."
        case (.desert, .holdFull): "Steady, like the stars."
        case (.desert, .exhale): "Breathe out as it settles low."
        case (.desert, .holdEmpty): "Rest in the desert's silence."
        case (.waterfall, nil): "Breathe by the falls."
        case (.waterfall, .inhale): "Breathe in, and let a rainbow form in the mist."
        case (.waterfall, .holdFull): "Rest in the roar of falling water."
        case (.waterfall, .exhale): "Breathe out with the water, all the way down."
        case (.waterfall, .holdEmpty): "Let the spray settle."
        case (.volcano, nil): "Breathe at the mountain's heart."
        case (.volcano, .inhale): "Breathe in, and gather the warmth."
        case (.volcano, .holdFull): "Hold it, glowing."
        case (.volcano, .exhale): "Breathe out, and let it all go."
        case (.volcano, .holdEmpty): "Rest as the embers drift."
        case (.rain, nil): "Breathe with the rain."
        case (.rain, .inhale): "Breathe in, and let the stillness widen."
        case (.rain, .holdFull): "Listen to the rain."
        case (.rain, .exhale): "Breathe out as the rain softens."
        case (.rain, .holdEmpty): "Rest, dry and quiet, inside the sound."
        case (.wind, nil): "Breathe in the open grass."
        case (.wind, .inhale): "Breathe in as the wind gathers."
        case (.wind, .holdFull): "Feel it lean through you."
        case (.wind, .exhale): "Breathe out, and let it carry the seeds away."
        case (.wind, .holdEmpty): "Rest as the grass stands again."
        case (.thunder, nil): "Breathe while the storm passes."
        case (.thunder, .inhale): "Breathe in, warm and safe inside."
        case (.thunder, .holdFull): "Let the thunder roll far away."
        case (.thunder, .exhale): "Breathe out, and let the storm pass."
        case (.thunder, .holdEmpty): "Rest in the shelter of your breath."
        case (.cymatics, nil): "Sound, made visible. Watch the water."
        case (.cymatics, .inhale): "Breathe in, and let the pattern unfold."
        case (.cymatics, .holdFull): "Be still, and watch it settle into form."
        case (.cymatics, .exhale): "Breathe out as it gathers to the center."
        case (.cymatics, .holdEmpty): "Rest in the hum beneath everything."
        case (.meadow, nil): "Breathe on the open hill."
        case (.meadow, .inhale): "Breathe in, and let the kites lift."
        case (.meadow, .holdFull): "Hang there, light, on the wind."
        case (.meadow, .exhale): "Breathe out as they drift down."
        case (.meadow, .holdEmpty): "Rest in the warm grass."
        case (.alpine, nil): "Breathe by the still water."
        case (.alpine, .inhale): "Breathe in the cool mountain air."
        case (.alpine, .holdFull): "Still, like the peaks in the lake."
        case (.alpine, .exhale): "Breathe out, and let the water settle."
        case (.alpine, .holdEmpty): "Rest in the high, clear quiet."
        case (.seaside, nil): "Breathe the sea air."
        case (.seaside, .inhale): "Breathe in as the sails fill."
        case (.seaside, .holdFull): "Pause, like a gull on the wind."
        case (.seaside, .exhale): "Breathe out with the waves."
        case (.seaside, .holdEmpty): "Rest in the sound of the sea."
        case (.garden, nil): "Breathe in the morning garden."
        case (.garden, .inhale): "Breathe in the scent of the flowers."
        case (.garden, .holdFull): "Still, so the birds stay."
        case (.garden, .exhale): "Breathe out, soft as birdsong."
        case (.garden, .holdEmpty): "Rest in the sun on the bench."
        case (.forest, nil): "Breathe among the pines."
        case (.forest, .inhale): "Breathe in the green, sunlit air."
        case (.forest, .holdFull): "Stand still, like the trees."
        case (.forest, .exhale): "Breathe out along the trail."
        case (.forest, .holdEmpty): "Rest in the dappled light."
        case (.lake, nil): "Breathe with the morning lake."
        case (.lake, .inhale): "Breathe in the cool morning."
        case (.lake, .holdFull): "Still, like the water at dawn."
        case (.lake, .exhale): "Breathe out as the mist lifts."
        case (.lake, .holdEmpty): "Rest at the end of the dock."
        }
    }
}

// MARK: - Ocean Tide

/// A dusk sea: the sun on the horizon laying a path of light across the water,
/// waves rolling in, and the tide washing up the sand with each in-breath.
struct OceanTideScene: View {
    var openness: Double
    var time: Double

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let horizon = h * 0.56
            ZStack(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.13, green: 0.11, blue: 0.32), location: 0),
                        .init(color: Color(red: 0.5, green: 0.25, blue: 0.47), location: 0.55),
                        .init(color: Color(red: 0.97, green: 0.55, blue: 0.38), location: 0.88),
                        .init(color: Color(red: 1, green: 0.76, blue: 0.5), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: horizon)
                Stars()
                    .frame(height: horizon * 0.4)
                    .opacity(0.5)
                Canvas { context, size in
                    OceanDrawing.draw(in: &context, size: size, horizon: horizon, openness: openness, time: time, animated: true)
                }
            }
        }
    }
}

enum OceanDrawing {
    static func draw(in context: inout GraphicsContext, size: CGSize, horizon: Double, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let sunRadius = w * 0.13
        let sun = CGPoint(x: w / 2, y: horizon)

        // Soft dusk clouds.
        context.drawLayer { clouds in
            clouds.addFilter(.blur(radius: 14))
            for (x, y, cw, ch) in [(0.2, 0.32, 0.5, 0.03), (0.75, 0.24, 0.45, 0.025), (0.55, 0.44, 0.6, 0.02)] {
                let drift = animated ? sin(time * 0.02 + x * 10) * 12 : 0
                clouds.fill(Path(ellipseIn: CGRect(x: w * x - w * cw / 2 + drift, y: horizon * y, width: w * cw, height: h * ch)),
                                        with: .color(Color(red: 1, green: 0.72, blue: 0.7).opacity(0.35)))
            }
        }

        // The sun, half set, glowing more as you breathe in.
        let glow = 0.7 + 0.3 * openness
        context.fill(Path(ellipseIn: CGRect(x: sun.x - sunRadius * 3, y: sun.y - sunRadius * 3, width: sunRadius * 6, height: sunRadius * 6)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.8, blue: 0.5).opacity(0.55 * glow), .clear]),
                                                                              center: sun, startRadius: 0, endRadius: sunRadius * 3))
        var sky = context
        sky.clip(to: Path(CGRect(x: 0, y: 0, width: w, height: horizon)))
        sky.fill(Path(ellipseIn: CGRect(x: sun.x - sunRadius, y: sun.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2)),
                          with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.93, blue: 0.7), Color(red: 1, green: 0.62, blue: 0.4)]),
                                                                      startPoint: CGPoint(x: sun.x, y: sun.y - sunRadius), endPoint: sun))

        // Gulls, far off.
        if animated {
            for i in 0..<3 {
                let t = (time * 0.012 + Double(i) * 0.31).truncatingRemainder(dividingBy: 1)
                let x = -40 + t * (w + 80)
                let y = horizon * (0.3 + 0.08 * Double(i)) + sin(time * 0.5 + Double(i)) * 6
                let flap = 3 + sin(time * 4 + Double(i)) * 2
                var gull = Path()
                gull.move(to: CGPoint(x: x - 7, y: y - flap))
                gull.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 3, y: y - flap - 2))
                gull.addQuadCurve(to: CGPoint(x: x + 7, y: y - flap), control: CGPoint(x: x + 3, y: y - flap - 2))
                context.stroke(gull, with: .color(Color(red: 0.2, green: 0.12, blue: 0.25).opacity(0.7)), lineWidth: 1.2)
            }
        }

        // The sea.
        let sea = CGRect(x: 0, y: horizon, width: w, height: h - horizon)
        context.fill(Path(sea), with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(red: 0.55, green: 0.33, blue: 0.47), location: 0),
                .init(color: Color(red: 0.14, green: 0.14, blue: 0.32), location: 0.35),
                .init(color: Color(red: 0.04, green: 0.06, blue: 0.15), location: 1),
            ]),
            startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h)
        ))

        // The sun's path of light on the water, widening toward you.
        var rng = SeededGenerator(seed: 909)
        for _ in 0..<90 {
            let depth = pow(Double.random(in: 0...1, using: &rng), 1.3)
            let y = horizon + depth * (h - horizon) * 0.8
            let spread = sunRadius * 0.4 + depth * w * 0.22
            let x = sun.x + Double.random(in: -1...1, using: &rng) * spread
            let phase = Double.random(in: 0...(2 * .pi), using: &rng)
            let twinkle = animated ? 0.5 + 0.5 * sin(time * Double.random(in: 1...2.2, using: &rng) + phase) : 0.7
            let length = 4 + depth * 26
            var streak = Path()
            streak.move(to: CGPoint(x: x - length / 2, y: y))
            streak.addLine(to: CGPoint(x: x + length / 2, y: y))
            context.stroke(streak, with: .color(Color(red: 1, green: 0.82, blue: 0.6).opacity(0.5 * twinkle * (1 - depth * 0.4))), lineWidth: 1 + depth)
        }

        // Waves rolling in, far to near.
        let rows: [Double] = [0.1, 0.26, 0.44, 0.62]
        for (i, row) in rows.enumerated() {
            let base = horizon + (h - horizon) * row
            let amplitude = 1.5 + Double(i) * 3 + (i == rows.count - 1 ? openness * 6 : 0)
            let wavelength = w * (0.25 + 0.12 * Double(i))
            let speed = animated ? time * (0.4 + 0.15 * Double(i)) : 0
            let wave = wavePath(width: w, base: base, amplitude: amplitude, wavelength: wavelength, phase: speed + Double(i), bottom: h)
            context.fill(wave, with: .color(Color(red: 0.05, green: 0.08, blue: 0.2).opacity(0.35 + 0.1 * Double(i))))
            context.stroke(crestPath(width: w, base: base, amplitude: amplitude, wavelength: wavelength, phase: speed + Double(i)),
                                          with: .color(.white.opacity(0.18 + 0.08 * Double(i))), lineWidth: 0.8 + Double(i) * 0.5)
        }

        // The beach, and the tide washing up it: in as you breathe in, out as you breathe out.
        let sandTop = h * 0.84
        context.fill(Path(CGRect(x: 0, y: sandTop, width: w, height: h - sandTop)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.42, green: 0.3, blue: 0.32), Color(red: 0.25, green: 0.17, blue: 0.2)]),
            startPoint: CGPoint(x: 0, y: sandTop), endPoint: CGPoint(x: 0, y: h)
        ))
        let reach = sandTop + (h - sandTop) * (0.12 + 0.7 * openness)
        let washPhase = animated ? time * 0.3 : 0
        var wash = Path()
        wash.move(to: CGPoint(x: 0, y: sandTop - 4))
        wash.addLine(to: CGPoint(x: w, y: sandTop - 4))
        var edge: [CGPoint] = []
        for step in stride(from: w, through: 0, by: -8) {
            let y = reach + sin(step / w * 7 + washPhase) * 5 + sin(step / w * 17 - washPhase * 1.3) * 2.5
            edge.append(CGPoint(x: step, y: y))
            wash.addLine(to: CGPoint(x: step, y: y))
        }
        wash.closeSubpath()
        context.fill(wash, with: .linearGradient(
            Gradient(colors: [Color(red: 0.2, green: 0.25, blue: 0.4).opacity(0.85), Color(red: 0.55, green: 0.6, blue: 0.7).opacity(0.5)]),
            startPoint: CGPoint(x: 0, y: sandTop), endPoint: CGPoint(x: 0, y: reach)
        ))
        var foam = Path()
        foam.addLines(edge)
        context.stroke(foam, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
    }

    private static func wavePath(width: Double, base: Double, amplitude: Double, wavelength: Double, phase: Double, bottom: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: bottom))
        for x in stride(from: 0, through: width, by: 6) {
            path.addLine(to: CGPoint(x: x, y: base + sin(x / wavelength * 2 * .pi + phase) * amplitude))
        }
        path.addLine(to: CGPoint(x: width, y: bottom))
        path.closeSubpath()
        return path
    }

    private static func crestPath(width: Double, base: Double, amplitude: Double, wavelength: Double, phase: Double) -> Path {
        var path = Path()
        for x in stride(from: 0, through: width, by: 6) {
            let point = CGPoint(x: x, y: base + sin(x / wavelength * 2 * .pi + phase) * amplitude)
            if x == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Sakura Moon

/// A full moon over Mount Fuji; a cherry branch whose blossoms open as you
/// breathe in; petals drifting down to rest on a moonlit pond.
struct SakuraMoonScene: View {
    var openness: Double
    var time: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.06, green: 0.05, blue: 0.18), location: 0),
                        .init(color: Color(red: 0.17, green: 0.13, blue: 0.34), location: 0.6),
                        .init(color: Color(red: 0.34, green: 0.26, blue: 0.46), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: geo.size.height * SakuraDrawing.pondLine)
                Stars()
                    .frame(height: geo.size.height * 0.5)
                    .opacity(0.7)
                Canvas { context, size in
                    SakuraDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true)
                }
                FallingLeaves(count: 22, landing: (SakuraDrawing.pondLine + 0.02)...0.96, kind: .sakura)
            }
        }
    }
}

enum SakuraDrawing {
    static let pondLine = 0.7

    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let pond = h * pondLine

        // The moon, its halo breathing.
        let moon = CGPoint(x: w * 0.72, y: h * 0.2)
        let moonRadius = w * 0.12
        context.fill(Path(ellipseIn: CGRect(x: moon.x - moonRadius * 3.5, y: moon.y - moonRadius * 3.5, width: moonRadius * 7, height: moonRadius * 7)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.95, blue: 0.85).opacity(0.25 + 0.12 * openness), .clear]),
                                                                              center: moon, startRadius: moonRadius, endRadius: moonRadius * 3.5))
        context.fill(Path(ellipseIn: CGRect(x: moon.x - moonRadius, y: moon.y - moonRadius, width: moonRadius * 2, height: moonRadius * 2)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.98, blue: 0.9), Color(red: 0.95, green: 0.9, blue: 0.78)]),
                                                                              center: CGPoint(x: moon.x - moonRadius * 0.3, y: moon.y - moonRadius * 0.3), startRadius: 0, endRadius: moonRadius * 1.3))
        for (dx, dy, r) in [(-0.3, -0.1, 0.18), (0.25, 0.2, 0.13), (0.05, -0.35, 0.1), (0.35, -0.25, 0.08)] {
            context.fill(Path(ellipseIn: CGRect(x: moon.x + moonRadius * dx - moonRadius * r, y: moon.y + moonRadius * dy - moonRadius * r,
                                                                                    width: moonRadius * r * 2, height: moonRadius * r * 2)),
                                      with: .color(Color(red: 0.75, green: 0.7, blue: 0.62).opacity(0.25)))
        }

        // Mount Fuji, with its snowcap, and mist at its foot.
        let fuji = fujiPath(width: w, base: pond, height: h * 0.26)
        context.fill(fuji, with: .linearGradient(
            Gradient(colors: [Color(red: 0.22, green: 0.19, blue: 0.38), Color(red: 0.1, green: 0.08, blue: 0.2)]),
            startPoint: CGPoint(x: 0, y: pond - h * 0.26), endPoint: CGPoint(x: 0, y: pond)
        ))
        context.fill(snowcap(width: w, base: pond, height: h * 0.26), with: .linearGradient(
            Gradient(colors: [.white.opacity(0.9), Color(red: 0.8, green: 0.8, blue: 0.95).opacity(0.7)]),
            startPoint: CGPoint(x: 0, y: pond - h * 0.26), endPoint: CGPoint(x: 0, y: pond - h * 0.15)
        ))
        context.drawLayer { mist in
            mist.addFilter(.blur(radius: 18))
            mist.fill(Path(ellipseIn: CGRect(x: -w * 0.2, y: pond - h * 0.05, width: w * 1.4, height: h * 0.07)),
                                with: .color(Color(red: 0.85, green: 0.8, blue: 1).opacity(0.18)))
        }

        // The pond, holding the moon and the mountain.
        context.fill(Path(CGRect(x: 0, y: pond, width: w, height: h - pond)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.16, green: 0.13, blue: 0.3), Color(red: 0.04, green: 0.04, blue: 0.1)]),
            startPoint: CGPoint(x: 0, y: pond), endPoint: CGPoint(x: 0, y: h)
        ))
        context.drawLayer { reflection in
            reflection.clip(to: Path(CGRect(x: 0, y: pond, width: w, height: h - pond)))
            reflection.opacity = 0.3
            reflection.addFilter(.blur(radius: 2))
            reflection.translateBy(x: 0, y: pond)
            reflection.scaleBy(x: 1, y: -0.6)
            reflection.translateBy(x: 0, y: -pond)
            reflection.fill(fuji, with: .color(Color(red: 0.25, green: 0.22, blue: 0.42)))
        }
        var rng = SeededGenerator(seed: 61)
        for _ in 0..<40 {
            let depth = Double.random(in: 0...1, using: &rng)
            let y = pond + depth * (h - pond) * 0.7
            let x = moon.x + Double.random(in: -1...1, using: &rng) * moonRadius * (0.6 + depth * 1.2)
            let phase = Double.random(in: 0...(2 * .pi), using: &rng)
            let twinkle = animated ? 0.5 + 0.5 * sin(time * 1.3 + phase) : 0.7
            var streak = Path()
            streak.move(to: CGPoint(x: x - 6 - depth * 10, y: y))
            streak.addLine(to: CGPoint(x: x + 6 + depth * 10, y: y))
            context.stroke(streak, with: .color(Color(red: 1, green: 0.96, blue: 0.85).opacity(0.4 * twinkle)), lineWidth: 1)
        }

        // The cherry branch, reaching in from the upper left.
        drawBranch(in: &context, width: w, height: h, openness: openness, time: time, animated: animated)
    }

    static func fujiPath(width w: Double, base: Double, height: Double) -> Path {
        var path = Path()
        let peakLeft = CGPoint(x: w * 0.36, y: base - height)
        let peakRight = CGPoint(x: w * 0.46, y: base - height)
        path.move(to: CGPoint(x: -w * 0.1, y: base))
        path.addQuadCurve(to: peakLeft, control: CGPoint(x: w * 0.25, y: base - height * 0.25))
        path.addLine(to: CGPoint(x: w * 0.39, y: base - height * 1.02))
        path.addLine(to: CGPoint(x: w * 0.43, y: base - height * 0.99))
        path.addLine(to: peakRight)
        path.addQuadCurve(to: CGPoint(x: w * 1.1, y: base), control: CGPoint(x: w * 0.58, y: base - height * 0.25))
        path.closeSubpath()
        return path
    }

    private static func snowcap(width w: Double, base: Double, height: Double) -> Path {
        var path = Path()
        let top = base - height
        path.move(to: CGPoint(x: w * 0.36, y: top))
        path.addLine(to: CGPoint(x: w * 0.39, y: base - height * 1.02))
        path.addLine(to: CGPoint(x: w * 0.43, y: base - height * 0.99))
        path.addLine(to: CGPoint(x: w * 0.46, y: top))
        path.addLine(to: CGPoint(x: w * 0.5, y: top + height * 0.3))
        path.addLine(to: CGPoint(x: w * 0.47, y: top + height * 0.24))
        path.addLine(to: CGPoint(x: w * 0.44, y: top + height * 0.36))
        path.addLine(to: CGPoint(x: w * 0.41, y: top + height * 0.26))
        path.addLine(to: CGPoint(x: w * 0.37, y: top + height * 0.38))
        path.addLine(to: CGPoint(x: w * 0.34, y: top + height * 0.27))
        path.addLine(to: CGPoint(x: w * 0.31, y: top + height * 0.32))
        path.closeSubpath()
        return path
    }

    /// A dark branch with smaller twigs, and five-petal blossoms along it that
    /// open with the breath (buds when closed).
    static func drawBranch(in context: inout GraphicsContext, width w: Double, height h: Double, openness: Double, time: Double, animated: Bool) {
        let bark = Color(red: 0.13, green: 0.08, blue: 0.1)
        let sway = animated ? sin(time * 0.4) * 3 : 0
        let limbs: [[CGPoint]] = [
            [CGPoint(x: -w * 0.05, y: h * 0.08), CGPoint(x: w * 0.2, y: h * 0.14), CGPoint(x: w * 0.42, y: h * 0.17 + sway), CGPoint(x: w * 0.62, y: h * 0.27 + sway)],
            [CGPoint(x: w * 0.2, y: h * 0.14), CGPoint(x: w * 0.28, y: h * 0.25), CGPoint(x: w * 0.3, y: h * 0.34 + sway)],
            [CGPoint(x: w * 0.4, y: h * 0.17 + sway), CGPoint(x: w * 0.47, y: h * 0.1), CGPoint(x: w * 0.56, y: h * 0.07)],
            [CGPoint(x: w * 0.08, y: h * 0.11), CGPoint(x: w * 0.12, y: h * 0.21), CGPoint(x: w * 0.1, y: h * 0.3)],
        ]
        for (index, limb) in limbs.enumerated() {
            var path = Path()
            path.move(to: limb[0])
            for i in 1..<limb.count {
                let a = limb[i - 1], b = limb[i]
                path.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: min(a.y, b.y) - 6))
            }
            context.stroke(path, with: .color(bark), style: StrokeStyle(lineWidth: index == 0 ? 7 : 3.5, lineCap: .round, lineJoin: .round))
        }

        let blossoms: [(CGPoint, Double)] = [
            (CGPoint(x: w * 0.6, y: h * 0.27 + sway), 1.0), (CGPoint(x: w * 0.5, y: h * 0.21 + sway), 0.8),
            (CGPoint(x: w * 0.3, y: h * 0.33 + sway), 0.85), (CGPoint(x: w * 0.27, y: h * 0.24), 0.65),
            (CGPoint(x: w * 0.55, y: h * 0.075), 0.75), (CGPoint(x: w * 0.46, y: h * 0.11), 0.6),
            (CGPoint(x: w * 0.1, y: h * 0.29), 0.7), (CGPoint(x: w * 0.13, y: h * 0.19), 0.55),
            (CGPoint(x: w * 0.36, y: h * 0.165 + sway), 0.7), (CGPoint(x: w * 0.22, y: h * 0.13), 0.6),
        ]
        let unit = w * 0.07
        for (i, (center, scale)) in blossoms.enumerated() {
            drawBlossom(in: &context, center: center, size: unit * scale, openness: openness, turn: Double(i) * 0.7)
        }
    }

    /// A cherry blossom: five notched petals around a ring of stamens.
    static func drawBlossom(in context: inout GraphicsContext, center: CGPoint, size: Double, openness: Double, turn: Double) {
        let open = 0.25 + 0.75 * openness
        let petalLength = size * 0.55 * open
        for i in 0..<5 {
            let angle = turn + Double(i) * 2 * .pi / 5
            var petal = Path()
            let width = petalLength * 0.62
            petal.move(to: .zero)
            petal.addCurve(to: CGPoint(x: width * 0.25, y: -petalLength), control1: CGPoint(x: width, y: -petalLength * 0.2), control2: CGPoint(x: width * 0.9, y: -petalLength * 0.95))
            petal.addLine(to: CGPoint(x: 0, y: -petalLength * 0.86))
            petal.addLine(to: CGPoint(x: -width * 0.25, y: -petalLength))
            petal.addCurve(to: .zero, control1: CGPoint(x: -width * 0.9, y: -petalLength * 0.95), control2: CGPoint(x: -width, y: -petalLength * 0.2))
            petal.closeSubpath()
            let shape = petal.applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: center.x, y: center.y)))
            context.fill(shape, with: .radialGradient(
                Gradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.65), Color(red: 1, green: 0.85, blue: 0.9)]),
                center: center, startRadius: 0, endRadius: petalLength
            ))
            context.stroke(shape, with: .color(Color(red: 0.9, green: 0.55, blue: 0.68).opacity(0.5)), lineWidth: 0.5)
        }
        for i in 0..<8 {
            let a = Double(i) / 8 * 2 * .pi
            let tip = CGPoint(x: center.x + cos(a) * petalLength * 0.35, y: center.y + sin(a) * petalLength * 0.35)
            context.fill(Path(ellipseIn: CGRect(x: tip.x - 0.9, y: tip.y - 0.9, width: 1.8, height: 1.8)),
                                      with: .color(Color(red: 1, green: 0.85, blue: 0.4)))
        }
    }
}

// MARK: - Desert Stars

/// The Milky Way arching over moonlit dunes; a candle on the sand whose flame
/// rises as you breathe in and settles as you breathe out; now and then a
/// shooting star.
struct DesertStarsScene: View {
    var openness: Double
    var time: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.02, green: 0.03, blue: 0.1), location: 0),
                        .init(color: Color(red: 0.07, green: 0.08, blue: 0.2), location: 0.6),
                        .init(color: Color(red: 0.24, green: 0.14, blue: 0.22), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: geo.size.height * DesertDrawing.horizon)
                Canvas { context, size in
                    DesertDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true)
                }
            }
        }
    }
}

enum DesertDrawing {
    static let horizon = 0.66

    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let skyline = h * horizon

        drawMilkyWay(in: &context, width: w, height: skyline)

        // A shooting star every so often.
        if animated {
            let cycle = 9.0
            let local = time.truncatingRemainder(dividingBy: cycle)
            if local < 1.1 {
                let t = local / 1.1
                let start = CGPoint(x: w * 0.85, y: skyline * 0.12)
                let end = CGPoint(x: w * 0.35, y: skyline * 0.42)
                let head = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
                let tail = CGPoint(x: head.x + (start.x - end.x) * 0.18, y: head.y + (start.y - end.y) * 0.18)
                var streak = Path()
                streak.move(to: tail)
                streak.addLine(to: head)
                context.stroke(streak, with: .linearGradient(Gradient(colors: [.clear, .white.opacity(0.9 * (1 - t))]), startPoint: tail, endPoint: head),
                                              style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        }

        // Sand under everything, so no sky shows between the dunes.
        context.fill(Path(CGRect(x: 0, y: skyline - h * 0.02, width: w, height: h - skyline + h * 0.02)),
                                  with: .color(Color(red: 0.3, green: 0.19, blue: 0.24)))

        // Dunes, far to near, edged with moonlight.
        let dunes: [(base: Double, height: Double, color: Color, phase: Double)] = [
            (skyline, h * 0.06, Color(red: 0.3, green: 0.19, blue: 0.24), 0.3),
            (skyline + h * 0.08, h * 0.08, Color(red: 0.2, green: 0.12, blue: 0.16), 1.7),
            (skyline + h * 0.18, h * 0.1, Color(red: 0.11, green: 0.07, blue: 0.09), 3.1),
        ]
        for dune in dunes {
            var crest: [CGPoint] = []
            for x in stride(from: 0.0, through: w, by: 5) {
                let u = x / w
                let y = dune.base - dune.height * (0.55 + 0.3 * sin(u * 5.2 + dune.phase) + 0.15 * sin(u * 11 + dune.phase * 2))
                crest.append(CGPoint(x: x, y: y))
            }
            // One continuous outline: up from the bottom-left, along the crest, down.
            var body = Path()
            body.move(to: CGPoint(x: 0, y: h))
            for point in crest { body.addLine(to: point) }
            body.addLine(to: CGPoint(x: w, y: h))
            body.closeSubpath()
            context.fill(body, with: .color(dune.color))
            var rim = Path()
            rim.addLines(crest)
            context.stroke(rim, with: .color(Color(red: 0.95, green: 0.75, blue: 0.6).opacity(0.22)), lineWidth: 1)
        }

        drawCandle(in: &context, at: CGPoint(x: w / 2, y: h * 0.86), width: w, openness: openness, time: time, animated: animated)
    }

    static func drawMilkyWay(in context: inout GraphicsContext, width w: Double, height skyline: Double) {
        let a = CGPoint(x: -w * 0.1, y: skyline * 0.95)
        let b = CGPoint(x: w * 1.1, y: skyline * 0.05)
        let dx = b.x - a.x, dy = b.y - a.y
        let length = (dx * dx + dy * dy).squareRoot()
        let normal = CGPoint(x: -dy / length, y: dx / length)

        // Glowing clouds of the galaxy's core.
        context.drawLayer { glow in
            glow.blendMode = .plusLighter
            glow.addFilter(.blur(radius: 26))
            let colors: [Color] = [Color(red: 0.6, green: 0.45, blue: 0.9), Color(red: 1, green: 0.7, blue: 0.5), Color(red: 0.5, green: 0.6, blue: 1)]
            for i in 0..<9 {
                let t = Double(i) / 8
                let center = CGPoint(x: a.x + dx * t, y: a.y + dy * t)
                let r = w * (0.12 + 0.06 * sin(Double(i) * 1.7))
                glow.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.55, width: r * 2, height: r * 1.1)),
                                    with: .color(colors[i % colors.count].opacity(0.26)))
            }
        }

        // Dense stars along the band, scattered stars everywhere.
        var rng = SeededGenerator(seed: 2718)
        for _ in 0..<520 {
            let t = Double.random(in: 0...1, using: &rng)
            let spread = (Double.random(in: -1...1, using: &rng) + Double.random(in: -1...1, using: &rng)) * w * 0.09
            let x = a.x + dx * t + normal.x * spread
            let y = a.y + dy * t + normal.y * spread
            guard y < skyline else { continue }
            let r = Double.random(in: 0.3...1.3, using: &rng)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                      with: .color(.white.opacity(Double.random(in: 0.2...0.85, using: &rng))))
        }
        for _ in 0..<140 {
            let x = Double.random(in: 0...w, using: &rng)
            let y = Double.random(in: 0...skyline, using: &rng)
            let r = Double.random(in: 0.4...1.6, using: &rng)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                      with: .color(.white.opacity(Double.random(in: 0.15...0.7, using: &rng))))
        }
    }

    /// A small candle on the sand. The flame's height follows the breath, with a
    /// gentle flicker; its warm light pools on the dune around it.
    static func drawCandle(in context: inout GraphicsContext, at base: CGPoint, width w: Double, openness: Double, time: Double, animated: Bool) {
        let flicker = animated ? sin(time * 11) * 0.04 + sin(time * 17) * 0.03 : 0
        let rise = 0.55 + 0.75 * openness
        let flameHeight = w * 0.07 * (rise + flicker)
        let flameWidth = w * 0.026
        let candleHeight = w * 0.07
        let candleWidth = w * 0.035
        let wick = CGPoint(x: base.x, y: base.y - candleHeight)

        // Warm light on the sand.
        let pool = w * (0.22 + 0.16 * openness)
        context.fill(Path(ellipseIn: CGRect(x: base.x - pool, y: base.y - pool * 0.4, width: pool * 2, height: pool * 0.8)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.62, blue: 0.3).opacity(0.35), .clear]),
                                                                              center: base, startRadius: 0, endRadius: pool))
        // Halo around the flame.
        let halo = flameHeight * 2.4
        context.fill(Path(ellipseIn: CGRect(x: wick.x - halo, y: wick.y - flameHeight * 0.6 - halo, width: halo * 2, height: halo * 2)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.75, blue: 0.4).opacity(0.45), .clear]),
                                                                              center: CGPoint(x: wick.x, y: wick.y - flameHeight * 0.6), startRadius: 0, endRadius: halo))

        // The candle.
        let body = CGRect(x: base.x - candleWidth / 2, y: wick.y, width: candleWidth, height: candleHeight)
        context.fill(Path(roundedRect: body, cornerRadius: 2), with: .linearGradient(
            Gradient(colors: [Color(red: 0.98, green: 0.92, blue: 0.82), Color(red: 0.75, green: 0.62, blue: 0.5)]),
            startPoint: CGPoint(x: body.minX, y: body.midY), endPoint: CGPoint(x: body.maxX, y: body.midY)
        ))
        context.fill(Path(ellipseIn: CGRect(x: body.minX, y: body.minY - 2, width: candleWidth, height: 4)),
                                  with: .color(Color(red: 1, green: 0.95, blue: 0.85)))

        // The flame: a teardrop with a pale core.
        let lean = animated ? sin(time * 1.7) * flameWidth * 0.2 : 0
        func flame(height: Double, width: Double) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: wick.x, y: wick.y))
            path.addCurve(to: CGPoint(x: wick.x + lean, y: wick.y - height),
                                        control1: CGPoint(x: wick.x + width, y: wick.y - height * 0.15),
                                        control2: CGPoint(x: wick.x + width * 0.4 + lean, y: wick.y - height * 0.7))
            path.addCurve(to: CGPoint(x: wick.x, y: wick.y),
                                        control1: CGPoint(x: wick.x - width * 0.4 + lean, y: wick.y - height * 0.7),
                                        control2: CGPoint(x: wick.x - width, y: wick.y - height * 0.15))
            path.closeSubpath()
            return path
        }
        context.fill(flame(height: flameHeight, width: flameWidth), with: .linearGradient(
            Gradient(colors: [Color(red: 1, green: 0.5, blue: 0.15), Color(red: 1, green: 0.85, blue: 0.4), Color(red: 1, green: 0.95, blue: 0.75)]),
            startPoint: CGPoint(x: wick.x, y: wick.y - flameHeight), endPoint: wick
        ))
        context.fill(flame(height: flameHeight * 0.45, width: flameWidth * 0.45),
                                  with: .color(Color(red: 0.85, green: 0.92, blue: 1).opacity(0.85)))
    }
}

// MARK: - Backdrops

/// A still, dimmed version of the chosen world, behind every screen. No motion,
/// so it costs nothing to keep on screen.
struct ThemeBackdrop: View {
    let theme: BreathTheme

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            switch theme {
            case .aurora:
                ZStack(alignment: .bottom) {
                    AuroraSky(isFlowing: false, strength: 0.45)
                        .frame(height: size.height * 0.6)
                        .frame(maxHeight: .infinity, alignment: .top)
                    RockyMountains()
                        .frame(height: size.height * 0.26)
                        .opacity(0.85)
                    RestingLeaves(count: 4)
                        .frame(height: size.height * 0.26)
                }
            case .ocean:
                Canvas { context, canvasSize in
                    OceanDrawing.draw(in: &context, size: canvasSize, horizon: canvasSize.height * 0.74, openness: 0.3, time: 0, animated: false)
                }
                .mask(LinearGradient(colors: [.clear, .black.opacity(0.4), .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            case .sakura:
                Canvas { context, canvasSize in
                    SakuraDrawing.draw(in: &context, size: canvasSize, openness: 0.8, time: 0, animated: false)
                }
                .opacity(0.55)
            case .desert:
                Canvas { context, canvasSize in
                    DesertDrawing.draw(in: &context, size: canvasSize, openness: 0.4, time: 0, animated: false)
                }
                .opacity(0.65)
            case .waterfall:
                Canvas { context, canvasSize in
                    WaterfallDrawing.draw(in: &context, size: canvasSize, openness: 0.3, time: 0, animated: false)
                }
                .opacity(0.45)
            case .volcano:
                Canvas { context, canvasSize in
                    VolcanoDrawing.draw(in: &context, size: canvasSize, openness: 0.2, time: 0, animated: false)
                }
                .opacity(0.5)
            case .rain:
                Canvas { context, canvasSize in
                    RainDrawing.draw(in: &context, size: canvasSize, openness: 0.3, time: 0, animated: false)
                }
                .opacity(0.55)
            case .wind:
                Canvas { context, canvasSize in
                    WindDrawing.draw(in: &context, size: canvasSize, openness: 0.2, time: 0, animated: false)
                }
                .opacity(0.35)
            case .thunder:
                Canvas { context, canvasSize in
                    ThunderDrawing.draw(in: &context, size: canvasSize, openness: 0.3, time: 0, animated: false, flashes: false)
                }
                .opacity(0.6)
            case .cymatics:
                CymaticsScene(openness: 0.4, time: 0)
                    .opacity(0.5)
            case .meadow, .alpine, .seaside, .garden, .forest, .lake:
                // Behind screens of text: the quiet start of the scene (no kites or birds
                // crossing the words), under enough shade for light text to read.
                DaylightScene(theme: theme, openness: 0.5, time: 3, arrived: 0)
                    .overlay {
                        LinearGradient(colors: [.black.opacity(0.5), .black.opacity(0.3), .black.opacity(0.5)],
                                       startPoint: .top, endPoint: .bottom)
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Ocean Tide") {
    OceanTideScene(openness: 0.7, time: 3).ignoresSafeArea()
}

#Preview("Sakura Moon") {
    SakuraMoonScene(openness: 0.8, time: 3).ignoresSafeArea()
}

#Preview("Desert Stars") {
    DesertStarsScene(openness: 0.7, time: 3).ignoresSafeArea()
}
