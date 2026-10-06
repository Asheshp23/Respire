//
//  NatureThemes.swift
//  Respire
//
//  Five more places to breathe, each with one thing that moves with the breath:
//
//  - Hidden Falls   a waterfall between mossy cliffs; a rainbow appears in the
//                   mist as you breathe in (light through water: the prism again).
//  - Ember Peak     a volcano at night; heat gathers in the crater on the
//                   in-breath, and the out-breath lets it go in a soft eruption.
//  - Rain Pond      rain on a forest pond; a circle of stillness widens with each
//                   breath, and the rain softens as you breathe out.
//  - Prairie Wind   golden grass; the wind gathers as you breathe in, bending it,
//                   and carries dandelion seeds away.
//  - Distant Storm  thunderheads and far lightning; a cabin window glows warmer
//                   as you breathe in. Flashes are rare and soft (one every 11 s,
//                   far below photosensitivity limits) and off with Reduce Motion.
//
//  Each world is a drawing enum (`draw(in:size:openness:time:animated:)`) so
//  the same code paints the living scene and the still app backdrop.
//

import SwiftUI

// MARK: - Shared

private func seeded(_ seed: UInt64) -> SeededGenerator { SeededGenerator(seed: seed) }

private func fillSky(_ context: inout GraphicsContext, width w: Double, to bottom: Double, colors: [Color]) {
    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: bottom)), with: .linearGradient(
        Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: 0, y: bottom)
    ))
}

private func drawStars(_ context: inout GraphicsContext, width w: Double, to bottom: Double, count: Int, seed: UInt64) {
    var rng = seeded(seed)
    for _ in 0..<count {
        let x = Double.random(in: 0...w, using: &rng)
        let y = pow(Double.random(in: 0...1, using: &rng), 1.5) * bottom
        let r = Double.random(in: 0.4...1.5, using: &rng)
        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                  with: .color(.white.opacity(Double.random(in: 0.15...0.7, using: &rng))))
    }
}

/// A row of pine silhouettes along a baseline.
private func drawPines(_ context: inout GraphicsContext, width w: Double, base: Double, height: ClosedRange<Double>, color: Color, seed: UInt64) {
    var rng = seeded(seed)
    var x = -10.0
    var body = Path()
    body.move(to: CGPoint(x: 0, y: base + 40))
    while x < w + 20 {
        let tall = Double.random(in: height, using: &rng)
        let wide = tall * 0.38
        body.addLine(to: CGPoint(x: x - wide / 2, y: base))
        body.addLine(to: CGPoint(x: x, y: base - tall))
        body.addLine(to: CGPoint(x: x + wide / 2, y: base))
        x += Double.random(in: wide * 0.5...wide * 0.9, using: &rng)
    }
    body.addLine(to: CGPoint(x: w, y: base + 40))
    body.closeSubpath()
    context.fill(body, with: .color(color))
}

/// Slanted rain streaks, `density` 0...1.
private func drawRain(_ context: inout GraphicsContext, size: CGSize, density: Double, time: Double, animated: Bool, seed: UInt64, alpha: Double = 0.28) {
    var rng = seeded(seed)
    let count = Int(260 * density)
    for _ in 0..<count {
        let x0 = Double.random(in: -0.1...1.1, using: &rng) * size.width
        let offset = Double.random(in: 0...1, using: &rng)
        let speed = Double.random(in: 700...1000, using: &rng)
        let length = Double.random(in: 10...20, using: &rng)
        let travel = size.height + 40
        let y = animated ? (time * speed + offset * travel).truncatingRemainder(dividingBy: travel) - 20 : offset * travel - 20
        let x = x0 + y * 0.12
        var streak = Path()
        streak.move(to: CGPoint(x: x, y: y))
        streak.addLine(to: CGPoint(x: x + length * 0.12, y: y + length))
        context.stroke(streak, with: .color(Color(red: 0.8, green: 0.88, blue: 1).opacity(alpha)), lineWidth: 1)
    }
}

// MARK: - Hidden Falls

struct WaterfallScene: View {
    var openness: Double
    var time: Double
    var body: some View {
        Canvas { context, size in
            WaterfallDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true)
        }
    }
}

enum WaterfallDrawing {
    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let top = h * 0.22, pool = h * 0.68
        let left = w * 0.39, right = w * 0.61

        fillSky(&context, width: w, to: h * 0.6, colors: [
            Color(red: 0.08, green: 0.14, blue: 0.24), Color(red: 0.2, green: 0.34, blue: 0.4), Color(red: 0.36, green: 0.5, blue: 0.5),
        ])
        drawStars(&context, width: w, to: h * 0.25, count: 60, seed: 11)
        drawPines(&context, width: w, base: h * 0.3, height: (h * 0.04)...(h * 0.09), color: Color(red: 0.1, green: 0.2, blue: 0.2), seed: 12)

        // The falls: a bright sheet with streaks rushing down it.
        let sheet = CGRect(x: left, y: top, width: right - left, height: pool - top)
        context.fill(Path(roundedRect: sheet, cornerRadius: 6), with: .linearGradient(
            Gradient(colors: [Color(red: 0.85, green: 0.95, blue: 1).opacity(0.9), Color(red: 0.6, green: 0.8, blue: 0.9).opacity(0.75)]),
            startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: pool)
        ))
        var rng = seeded(13)
        for _ in 0..<60 {
            let x = Double.random(in: left...right, using: &rng)
            let length = Double.random(in: 20...70, using: &rng)
            let speed = Double.random(in: 220...380, using: &rng)
            let offset = Double.random(in: 0...1, using: &rng)
            let span = pool - top
            let y = top + (animated ? (time * speed + offset * span).truncatingRemainder(dividingBy: span) : offset * span)
            var streak = Path()
            streak.move(to: CGPoint(x: x, y: y))
            streak.addLine(to: CGPoint(x: x, y: min(y + length, pool)))
            context.stroke(streak, with: .color(.white.opacity(Double.random(in: 0.3...0.8, using: &rng))), lineWidth: Double.random(in: 0.8...2, using: &rng))
        }

        // Mossy cliffs framing the falls.
        let rock = Gradient(colors: [Color(red: 0.13, green: 0.16, blue: 0.16), Color(red: 0.05, green: 0.07, blue: 0.07)])
        var cliffLeft = Path()
        cliffLeft.move(to: CGPoint(x: 0, y: h * 0.14))
        cliffLeft.addQuadCurve(to: CGPoint(x: left + 4, y: top), control: CGPoint(x: w * 0.22, y: h * 0.16))
        cliffLeft.addLine(to: CGPoint(x: left + 2, y: top + (pool - top) * 0.5))
        cliffLeft.addLine(to: CGPoint(x: left + 8, y: pool + 4))
        cliffLeft.addLine(to: CGPoint(x: 0, y: pool + h * 0.06))
        cliffLeft.closeSubpath()
        var cliffRight = Path()
        cliffRight.move(to: CGPoint(x: w, y: h * 0.12))
        cliffRight.addQuadCurve(to: CGPoint(x: right - 4, y: top), control: CGPoint(x: w * 0.8, y: h * 0.15))
        cliffRight.addLine(to: CGPoint(x: right - 1, y: top + (pool - top) * 0.55))
        cliffRight.addLine(to: CGPoint(x: right - 8, y: pool + 4))
        cliffRight.addLine(to: CGPoint(x: w, y: pool + h * 0.05))
        cliffRight.closeSubpath()
        for cliff in [cliffLeft, cliffRight] {
            context.fill(cliff, with: .linearGradient(rock, startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: pool)))
            context.stroke(cliff, with: .color(Color(red: 0.25, green: 0.45, blue: 0.3).opacity(0.5)), lineWidth: 2)
        }

        // The pool.
        context.fill(Path(CGRect(x: 0, y: pool, width: w, height: h - pool)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.12, green: 0.36, blue: 0.4), Color(red: 0.03, green: 0.1, blue: 0.13)]),
            startPoint: CGPoint(x: 0, y: pool), endPoint: CGPoint(x: 0, y: h)
        ))
        let foot = CGPoint(x: w / 2, y: pool + 6)
        for i in 0..<5 {
            let phase = animated ? (time / 3 + Double(i) / 5).truncatingRemainder(dividingBy: 1) : Double(i) / 5
            let r = w * 0.1 + phase * w * 0.5
            context.stroke(Path(ellipseIn: CGRect(x: foot.x - r, y: foot.y - r * 0.12, width: r * 2, height: r * 0.24)),
                                          with: .color(.white.opacity(0.22 * (1 - phase))), lineWidth: 1)
        }

        // Mist at the foot of the falls.
        context.drawLayer { mist in
            mist.addFilter(.blur(radius: 22))
            for i in 0..<5 {
                let drift = animated ? sin(time * 0.6 + Double(i)) * 14 : 0
                let r = w * (0.14 + 0.03 * Double(i))
                mist.fill(Path(ellipseIn: CGRect(x: foot.x - r + drift + (Double(i) - 2) * w * 0.06, y: pool - r * 0.5, width: r * 2, height: r)),
                                    with: .color(.white.opacity(0.22)))
            }
        }

        // The rainbow in the spray, appearing as you breathe in.
        context.drawLayer { bow in
            bow.blendMode = .plusLighter
            bow.addFilter(.blur(radius: 2.5))
            let center = CGPoint(x: w / 2, y: pool + h * 0.06)
            for (i, color) in Theme.prism.enumerated() {
                let r = w * 0.34 + Double(i) * 5
                var arc = Path()
                arc.addArc(center: center, radius: r, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                bow.stroke(arc, with: .color(color.opacity(0.1 + 0.5 * openness)), lineWidth: 5)
            }
        }
    }
}

// MARK: - Ember Peak

struct VolcanoScene: View {
    var openness: Double
    var time: Double
    var body: some View {
        Canvas { context, size in
            VolcanoDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true)
        }
    }
}

enum VolcanoDrawing {
    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let crater = CGPoint(x: w / 2, y: h * 0.4)
        let base = h * 0.76
        let heat = 0.35 + 0.65 * openness

        fillSky(&context, width: w, to: base, colors: [
            Color(red: 0.05, green: 0.03, blue: 0.1), Color(red: 0.18, green: 0.06, blue: 0.12), Color(red: 0.42, green: 0.12, blue: 0.1),
        ])
        drawStars(&context, width: w, to: h * 0.3, count: 90, seed: 21)

        // Smoke rising and leaning with the wind.
        context.drawLayer { smoke in
            smoke.addFilter(.blur(radius: 18))
            var rng = seeded(22)
            for _ in 0..<10 {
                let offset = Double.random(in: 0...1, using: &rng)
                let rise = animated ? (time * 0.05 + offset).truncatingRemainder(dividingBy: 1) : offset
                let y = crater.y - rise * h * 0.38
                let x = crater.x + rise * w * 0.18 + sin(time * 0.3 + offset * 6) * 10
                let r = w * (0.06 + rise * 0.14)
                smoke.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.7, width: r * 2, height: r * 1.4)),
                                      with: .color(Color(red: 0.32, green: 0.25, blue: 0.28).opacity(0.45 * (1 - rise))))
            }
        }

        // The cone.
        var cone = Path()
        cone.move(to: CGPoint(x: -w * 0.05, y: base))
        cone.addQuadCurve(to: CGPoint(x: crater.x - w * 0.07, y: crater.y), control: CGPoint(x: w * 0.3, y: base - h * 0.08))
        cone.addLine(to: CGPoint(x: crater.x + w * 0.07, y: crater.y))
        cone.addQuadCurve(to: CGPoint(x: w * 1.05, y: base), control: CGPoint(x: w * 0.7, y: base - h * 0.08))
        cone.closeSubpath()
        context.fill(cone, with: .linearGradient(
            Gradient(colors: [Color(red: 0.12, green: 0.06, blue: 0.07), Color(red: 0.04, green: 0.02, blue: 0.03)]),
            startPoint: CGPoint(x: 0, y: crater.y), endPoint: CGPoint(x: 0, y: base)
        ))

        // Lava threading down the slopes, glowing with the heat.
        let rivers: [[CGPoint]] = [
            [crater, CGPoint(x: w * 0.47, y: h * 0.48), CGPoint(x: w * 0.42, y: h * 0.58), CGPoint(x: w * 0.36, y: h * 0.7)],
            [crater, CGPoint(x: w * 0.53, y: h * 0.47), CGPoint(x: w * 0.58, y: h * 0.56), CGPoint(x: w * 0.6, y: h * 0.66), CGPoint(x: w * 0.66, y: h * 0.74)],
            [CGPoint(x: w * 0.5, y: h * 0.42), CGPoint(x: w * 0.5, y: h * 0.52), CGPoint(x: w * 0.52, y: h * 0.62)],
        ]
        for river in rivers {
            var path = Path()
            path.move(to: river[0])
            for i in 1..<river.count {
                let a = river[i - 1], b = river[i]
                path.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2 + 8, y: (a.y + b.y) / 2))
            }
            context.drawLayer { glow in
                glow.blendMode = .plusLighter
                glow.addFilter(.blur(radius: 6))
                glow.stroke(path, with: .color(Color(red: 1, green: 0.35, blue: 0.1).opacity(0.7 * heat)), lineWidth: 8)
            }
            context.stroke(path, with: .linearGradient(
                Gradient(colors: [Color(red: 1, green: 0.85, blue: 0.4), Color(red: 1, green: 0.3, blue: 0.08)]),
                startPoint: crater, endPoint: CGPoint(x: crater.x, y: base)
            ), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }

        // Crater glow.
        let glowRadius = w * (0.18 + 0.2 * openness)
        context.fill(Path(ellipseIn: CGRect(x: crater.x - glowRadius, y: crater.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.55, blue: 0.2).opacity(0.75 * heat), .clear]),
                                                                              center: crater, startRadius: 0, endRadius: glowRadius))

        // The eruption: a fountain of lava and embers, strongest at the top of the breath.
        if animated {
            var rng = seeded(23)
            let strength = max(0, (openness - 0.25) / 0.75)
            for _ in 0..<Int(40 * strength) {
                let offset = Double.random(in: 0...1, using: &rng)
                let vx = Double.random(in: -1...1, using: &rng)
                let vy = Double.random(in: 0.7...1.3, using: &rng)
                let t = (time * 0.7 + offset).truncatingRemainder(dividingBy: 1) * 1.6
                let x = crater.x + vx * t * w * 0.12
                let y = crater.y - (vy * t - 0.55 * t * t) * h * 0.16
                guard y < crater.y + 4 else { continue }
                let r = Double.random(in: 1.2...2.6, using: &rng)
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                                          with: .color(Color(red: 1, green: Double.random(in: 0.4...0.85, using: &rng), blue: 0.2).opacity(0.9)))
            }
        }

        // Embers drifting up into the dark.
        var rng = seeded(24)
        for _ in 0..<30 {
            let offset = Double.random(in: 0...1, using: &rng)
            let rise = animated ? (time * 0.04 + offset).truncatingRemainder(dividingBy: 1) : offset
            let x = crater.x + Double.random(in: -1...1, using: &rng) * w * 0.25 + sin(time + offset * 10) * 8
            let y = crater.y - rise * h * 0.35
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.8, height: 1.8)),
                                      with: .color(Color(red: 1, green: 0.6, blue: 0.25).opacity(0.8 * (1 - rise) * heat)))
        }

        // A cooled lava field in the foreground, cracked with glowing seams.
        context.fill(Path(CGRect(x: 0, y: base, width: w, height: h - base)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.07, green: 0.04, blue: 0.05), Color(red: 0.02, green: 0.01, blue: 0.02)]),
            startPoint: CGPoint(x: 0, y: base), endPoint: CGPoint(x: 0, y: h)
        ))
        var cracks = seeded(25)
        for _ in 0..<9 {
            var crack = Path()
            var point = CGPoint(x: Double.random(in: 0...w, using: &cracks), y: base + Double.random(in: 10...(h - base - 10), using: &cracks))
            crack.move(to: point)
            for _ in 0..<5 {
                point = CGPoint(x: point.x + Double.random(in: -30...30, using: &cracks), y: point.y + Double.random(in: -8...8, using: &cracks))
                crack.addLine(to: point)
            }
            context.stroke(crack, with: .color(Color(red: 1, green: 0.4, blue: 0.1).opacity(0.25 + 0.35 * heat)), lineWidth: 1.2)
        }
    }
}

// MARK: - Rain Pond

struct RainScene: View {
    var openness: Double
    var time: Double
    var body: some View {
        Canvas { context, size in
            RainDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true)
        }
    }
}

enum RainDrawing {
    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let shore = h * 0.6

        fillSky(&context, width: w, to: shore, colors: [
            Color(red: 0.1, green: 0.12, blue: 0.18), Color(red: 0.2, green: 0.24, blue: 0.3), Color(red: 0.3, green: 0.34, blue: 0.38),
        ])
        // Low clouds.
        context.drawLayer { clouds in
            clouds.addFilter(.blur(radius: 24))
            for i in 0..<6 {
                let drift = animated ? (time * 4 + Double(i) * 90).truncatingRemainder(dividingBy: w + 200) - 100 : Double(i) * w / 6
                clouds.fill(Path(ellipseIn: CGRect(x: drift - w * 0.2, y: h * (0.04 + 0.05 * Double(i % 3)), width: w * 0.5, height: h * 0.08)),
                                        with: .color(Color(red: 0.08, green: 0.1, blue: 0.14).opacity(0.7)))
            }
        }
        drawPines(&context, width: w, base: shore - h * 0.02, height: (h * 0.05)...(h * 0.1), color: Color(red: 0.12, green: 0.16, blue: 0.18), seed: 31)
        drawPines(&context, width: w, base: shore, height: (h * 0.07)...(h * 0.14), color: Color(red: 0.05, green: 0.08, blue: 0.09), seed: 32)

        // The pond.
        context.fill(Path(CGRect(x: 0, y: shore, width: w, height: h - shore)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.16, green: 0.2, blue: 0.24), Color(red: 0.04, green: 0.06, blue: 0.08)]),
            startPoint: CGPoint(x: 0, y: shore), endPoint: CGPoint(x: 0, y: h)
        ))

        // Raindrops ringing the surface.
        var rng = seeded(33)
        for _ in 0..<38 {
            let x = Double.random(in: 0...w, using: &rng)
            let depth = Double.random(in: 0...1, using: &rng)
            let y = shore + 8 + depth * (h - shore - 16)
            let offset = Double.random(in: 0...1, using: &rng)
            let phase = animated ? (time * 1.1 + offset).truncatingRemainder(dividingBy: 1) : offset
            let r = (3 + depth * 12) * (0.3 + phase)
            context.stroke(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.25, width: r * 2, height: r * 0.5)),
                                          with: .color(.white.opacity(0.3 * (1 - phase))), lineWidth: 0.8)
        }

        // A circle of stillness at the center, widening with each breath.
        let center = CGPoint(x: w / 2, y: shore + (h - shore) * 0.35)
        for i in 0..<4 {
            let r = w * (0.06 + 0.32 * openness) * (1 + Double(i) * 0.22)
            context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.22, width: r * 2, height: r * 0.44)),
                                          with: .color(Color(red: 0.75, green: 0.88, blue: 1).opacity(0.45 - Double(i) * 0.1)), lineWidth: 1.4 - Double(i) * 0.25)
        }

        // Rain, softening as you breathe out.
        drawRain(&context, size: size, density: 0.4 + 0.6 * openness, time: time, animated: animated, seed: 34)
    }
}

// MARK: - Prairie Wind

struct WindScene: View {
    var openness: Double
    var time: Double
    var body: some View {
        Canvas { context, size in
            WindDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true)
        }
    }
}

enum WindDrawing {
    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool) {
        let w = size.width, h = size.height
        let horizon = h * 0.58

        fillSky(&context, width: w, to: horizon, colors: [
            Color(red: 0.3, green: 0.4, blue: 0.66), Color(red: 0.78, green: 0.62, blue: 0.62), Color(red: 1, green: 0.78, blue: 0.52),
        ])
        // The low sun.
        let sun = CGPoint(x: w * 0.78, y: horizon - h * 0.04)
        context.fill(Path(ellipseIn: CGRect(x: sun.x - w * 0.35, y: sun.y - w * 0.35, width: w * 0.7, height: w * 0.7)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.9, blue: 0.6).opacity(0.7), .clear]),
                                                                              center: sun, startRadius: 0, endRadius: w * 0.35))
        context.fill(Path(ellipseIn: CGRect(x: sun.x - w * 0.06, y: sun.y - w * 0.06, width: w * 0.12, height: w * 0.12)),
                                  with: .color(Color(red: 1, green: 0.95, blue: 0.8)))
        // Clouds streaming with the wind.
        context.drawLayer { clouds in
            clouds.addFilter(.blur(radius: 12))
            for i in 0..<5 {
                let speed = 6 + openness * 14
                let x = animated ? (time * speed + Double(i) * w * 0.3).truncatingRemainder(dividingBy: w * 1.4) - w * 0.2 : Double(i) * w * 0.25
                clouds.fill(Path(ellipseIn: CGRect(x: x, y: h * (0.08 + 0.07 * Double(i % 3)), width: w * 0.35, height: h * 0.03)),
                                        with: .color(.white.opacity(0.4)))
            }
        }
        // Rolling hills.
        for (i, color) in [Color(red: 0.55, green: 0.45, blue: 0.38), Color(red: 0.42, green: 0.34, blue: 0.24)].enumerated() {
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: h))
            for x in stride(from: 0.0, through: w, by: 6) {
                hill.addLine(to: CGPoint(x: x, y: horizon - h * 0.04 + Double(i) * h * 0.04 - sin(x / w * 3 + Double(i) * 2) * h * 0.025))
            }
            hill.addLine(to: CGPoint(x: w, y: h))
            hill.closeSubpath()
            context.fill(hill, with: .color(color))
        }

        // The field.
        let field = horizon + h * 0.04
        context.fill(Path(CGRect(x: 0, y: field, width: w, height: h - field)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.55, green: 0.45, blue: 0.22), Color(red: 0.2, green: 0.16, blue: 0.07)]),
            startPoint: CGPoint(x: 0, y: field), endPoint: CGPoint(x: 0, y: h)
        ))

        // Grass, bending as the wind gathers on the in-breath.
        var rng = seeded(41)
        var blades: [(CGPoint, Double, Double, Color)] = []
        for _ in 0..<240 {
            let depth = pow(Double.random(in: 0...1, using: &rng), 0.8)
            let base = CGPoint(x: Double.random(in: -10...(w + 10), using: &rng), y: field + depth * (h - field) + 4)
            let height = 14 + depth * 80
            let hue = Double.random(in: 0...1, using: &rng)
            let color = Color(red: 0.75 + 0.2 * hue, green: 0.6 + 0.15 * hue, blue: 0.25).opacity(0.55 + 0.4 * depth)
            blades.append((base, height, depth, color))
        }
        for (base, height, depth, color) in blades.sorted(by: { $0.0.y < $1.0.y }) {
            let ripple = animated ? sin(time * 1.6 - base.x * 0.02) * 0.12 : 0
            let bend = (ripple + 0.08 + openness * 0.5) * height
            var blade = Path()
            blade.move(to: CGPoint(x: base.x - 1.2, y: base.y))
            blade.addQuadCurve(to: CGPoint(x: base.x + bend, y: base.y - height * (1 - openness * 0.15)),
                                                  control: CGPoint(x: base.x + bend * 0.2, y: base.y - height * 0.6))
            blade.addQuadCurve(to: CGPoint(x: base.x + 1.2, y: base.y),
                                                  control: CGPoint(x: base.x + bend * 0.25, y: base.y - height * 0.55))
            context.fill(blade, with: .color(color))
            _ = depth
        }

        // Dandelion seeds carried off on the wind.
        if animated {
            var seeds = seeded(42)
            for _ in 0..<26 {
                let offset = Double.random(in: 0...1, using: &seeds)
                let speed = 0.03 + 0.07 * openness
                let t = (time * speed + offset).truncatingRemainder(dividingBy: 1)
                let x = -20 + t * (w + 40)
                let y = h * Double.random(in: 0.3...0.8, using: &seeds) - t * h * 0.15 + sin(time * 1.3 + offset * 9) * 10
                for k in 0..<6 {
                    let a = Double(k) / 6 * 2 * .pi
                    var filament = Path()
                    filament.move(to: CGPoint(x: x, y: y))
                    filament.addLine(to: CGPoint(x: x + cos(a) * 4, y: y + sin(a) * 4))
                    context.stroke(filament, with: .color(.white.opacity(0.75)), lineWidth: 0.5)
                }
                var stem = Path()
                stem.move(to: CGPoint(x: x, y: y))
                stem.addLine(to: CGPoint(x: x - 2, y: y + 6))
                context.stroke(stem, with: .color(.white.opacity(0.6)), lineWidth: 0.6)
            }
        }
    }
}

// MARK: - Distant Storm

struct ThunderScene: View {
    var openness: Double
    var time: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Canvas { context, size in
            ThunderDrawing.draw(in: &context, size: size, openness: openness, time: time, animated: true, flashes: !reduceMotion)
        }
    }
}

enum ThunderDrawing {
    static func draw(in context: inout GraphicsContext, size: CGSize, openness: Double, time: Double, animated: Bool, flashes: Bool) {
        let w = size.width, h = size.height
        let horizon = h * 0.62

        fillSky(&context, width: w, to: horizon, colors: [
            Color(red: 0.05, green: 0.06, blue: 0.1), Color(red: 0.12, green: 0.13, blue: 0.2), Color(red: 0.2, green: 0.21, blue: 0.28),
        ])

        // Lightning: one soft, far-off strike every 11 seconds, never rapid.
        let cycle = 11.0
        let local = animated ? time.truncatingRemainder(dividingBy: cycle) : 99
        let strikeIndex = animated ? Int(time / cycle) : 0
        let flash = flashes && local < 0.7 ? exp(-local * 5) : 0
        if flash > 0.01 {
            context.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon)), with: .color(Color(red: 0.75, green: 0.8, blue: 1).opacity(0.18 * flash)))
            var rng = seeded(UInt64(500 + strikeIndex))
            var point = CGPoint(x: w * Double.random(in: 0.2...0.8, using: &rng), y: h * 0.18)
            var bolt = Path()
            bolt.move(to: point)
            while point.y < horizon - h * 0.03 {
                point = CGPoint(x: point.x + Double.random(in: -18...18, using: &rng), y: point.y + Double.random(in: 14...30, using: &rng))
                bolt.addLine(to: point)
            }
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 6))
                glow.stroke(bolt, with: .color(Color(red: 0.7, green: 0.8, blue: 1).opacity(0.8 * flash)), lineWidth: 6)
            }
            context.stroke(bolt, with: .color(.white.opacity(flash)), lineWidth: 1.6)
        }

        // Heavy, rolling thunderheads.
        context.drawLayer { clouds in
            clouds.addFilter(.blur(radius: 20))
            var rng = seeded(51)
            for _ in 0..<12 {
                let x0 = Double.random(in: -0.2...1.0, using: &rng) * w
                let y = h * Double.random(in: 0.0...0.3, using: &rng)
                let drift = animated ? sin(time * 0.05 + x0) * 20 : 0
                let r = w * Double.random(in: 0.18...0.32, using: &rng)
                clouds.fill(Path(ellipseIn: CGRect(x: x0 + drift, y: y, width: r * 2, height: r)),
                                        with: .color(Color(red: 0.08 + 0.1 * flash, green: 0.09 + 0.1 * flash, blue: 0.13 + 0.12 * flash).opacity(0.85)))
            }
        }

        // Dark hills, and a small cabin whose window glows warmer as you breathe in.
        var hill = Path()
        hill.move(to: CGPoint(x: 0, y: h))
        for x in stride(from: 0.0, through: w, by: 6) {
            hill.addLine(to: CGPoint(x: x, y: horizon - sin(x / w * 2.4 + 0.6) * h * 0.05))
        }
        hill.addLine(to: CGPoint(x: w, y: h))
        hill.closeSubpath()
        context.fill(hill, with: .linearGradient(
            Gradient(colors: [Color(red: 0.07, green: 0.09, blue: 0.1), Color(red: 0.02, green: 0.03, blue: 0.04)]),
            startPoint: CGPoint(x: 0, y: horizon - h * 0.05), endPoint: CGPoint(x: 0, y: h)
        ))
        drawPines(&context, width: w, base: horizon + h * 0.03, height: (h * 0.04)...(h * 0.09), color: Color(red: 0.03, green: 0.05, blue: 0.05), seed: 52)

        let cabin = CGPoint(x: w * 0.5, y: horizon + h * 0.06)
        let cw = w * 0.16, ch = w * 0.1
        let warmth = 0.45 + 0.55 * openness
        context.fill(Path(ellipseIn: CGRect(x: cabin.x - cw * 2, y: cabin.y - ch * 1.6, width: cw * 4, height: ch * 3)),
                                  with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.7, blue: 0.35).opacity(0.35 * warmth), .clear]),
                                                                              center: cabin, startRadius: 0, endRadius: cw * 2))
        var house = Path()
        house.move(to: CGPoint(x: cabin.x - cw / 2, y: cabin.y + ch / 2))
        house.addLine(to: CGPoint(x: cabin.x - cw / 2, y: cabin.y - ch / 4))
        house.addLine(to: CGPoint(x: cabin.x, y: cabin.y - ch * 0.8))
        house.addLine(to: CGPoint(x: cabin.x + cw / 2, y: cabin.y - ch / 4))
        house.addLine(to: CGPoint(x: cabin.x + cw / 2, y: cabin.y + ch / 2))
        house.closeSubpath()
        context.fill(house, with: .color(Color(red: 0.06, green: 0.05, blue: 0.05)))
        let window = CGRect(x: cabin.x - cw * 0.16, y: cabin.y - ch * 0.05, width: cw * 0.32, height: ch * 0.3)
        context.fill(Path(roundedRect: window, cornerRadius: 1.5), with: .color(Color(red: 1, green: 0.78, blue: 0.42).opacity(0.5 + 0.5 * warmth)))
        var cross = Path()
        cross.move(to: CGPoint(x: window.midX, y: window.minY)); cross.addLine(to: CGPoint(x: window.midX, y: window.maxY))
        cross.move(to: CGPoint(x: window.minX, y: window.midY)); cross.addLine(to: CGPoint(x: window.maxX, y: window.midY))
        context.stroke(cross, with: .color(Color(red: 0.06, green: 0.05, blue: 0.05)), lineWidth: 1)

        // Rain sweeping across.
        drawRain(&context, size: size, density: 0.7, time: time, animated: animated, seed: 53, alpha: 0.22)
    }
}

#Preview("Hidden Falls") { WaterfallScene(openness: 0.8, time: 2).ignoresSafeArea() }
#Preview("Ember Peak") { VolcanoScene(openness: 0.85, time: 2).ignoresSafeArea() }
#Preview("Rain Pond") { RainScene(openness: 0.6, time: 2).ignoresSafeArea() }
#Preview("Prairie Wind") { WindScene(openness: 0.7, time: 2).ignoresSafeArea() }
#Preview("Distant Storm") { ThunderScene(openness: 0.7, time: 0.1).ignoresSafeArea() }
