//
//  PlaceSketch.swift
//  Respire
//
//  A small hand-drawn toolkit for Places: grainy paper, night skies, strokes that
//  double back like ink, arches, soft glows, leaves, pines, and gentle rain.
//  Everything is relative to the canvas, so each drawing fills any screen.
//

import SwiftUI

enum Sketch {
    static func hex(_ value: UInt32, _ opacity: Double = 1) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255,
              green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255,
              opacity: opacity)
    }

    // MARK: Grounds

    /// A flat paper color with fine grain, like a sketchbook page.
    static func paper(_ c: inout GraphicsContext, _ s: CGSize, _ color: Color, seed: UInt64 = 7) {
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(color))
        var rng = SeededGenerator(seed: seed)
        for _ in 0..<Int(s.width * s.height / 900) {
            let x = Double.random(in: 0...s.width, using: &rng)
            let y = Double.random(in: 0...s.height, using: &rng)
            let dark = Bool.random(using: &rng)
            c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                   with: .color((dark ? Color.black : .white).opacity(Double.random(in: 0.03...0.09, using: &rng))))
        }
    }

    /// A night sky from `top` to `bottom`, with stars that twinkle.
    static func night(_ c: inout GraphicsContext, _ s: CGSize, top: Color, bottom: Color, stars: Int = 140,
                      starsTo: Double = 1, time: Double, seed: UInt64 = 11) {
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [top, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: s.height)))
        var rng = SeededGenerator(seed: seed)
        for _ in 0..<stars {
            let x = Double.random(in: 0...s.width, using: &rng)
            let y = pow(Double.random(in: 0...1, using: &rng), 1.4) * s.height * starsTo
            let r = Double.random(in: 0.5...1.6, using: &rng)
            let phase = Double.random(in: 0...(2 * .pi), using: &rng)
            let twinkle = 0.55 + 0.45 * sin(time * 1.3 + phase)
            c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                   with: .color(.white.opacity(Double.random(in: 0.25...0.85, using: &rng) * twinkle)))
        }
    }

    // MARK: Marks

    /// A stroke drawn twice, the second a hair off and fainter, like a pen line.
    static func ink(_ c: inout GraphicsContext, _ path: Path, _ color: Color, width: CGFloat = 1.6) {
        c.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        c.stroke(path.applying(CGAffineTransform(translationX: 0.9, y: -0.7)), with: .color(color.opacity(0.45)),
                 style: StrokeStyle(lineWidth: width * 0.6, lineCap: .round, lineJoin: .round))
    }

    /// A rectangle with a semicircular top.
    static func arch(_ r: CGRect) -> Path {
        var p = Path()
        let radius = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }

    static func glow(_ c: inout GraphicsContext, at p: CGPoint, radius: Double, color: Color, opacity: Double) {
        c.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
               with: .radialGradient(Gradient(colors: [color.opacity(opacity), color.opacity(opacity * 0.25), .clear]),
                                     center: p, startRadius: 0, endRadius: radius))
    }

    /// A pointed leaf, `size` long, turned by `angle`.
    static func leaf(at p: CGPoint, size: Double, angle: Double) -> Path {
        var leaf = Path()
        leaf.move(to: .zero)
        leaf.addQuadCurve(to: CGPoint(x: size, y: 0), control: CGPoint(x: size * 0.5, y: -size * 0.45))
        leaf.addQuadCurve(to: .zero, control: CGPoint(x: size * 0.5, y: size * 0.45))
        return leaf.applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: p.x, y: p.y)))
    }

    /// A simple pine: stacked triangles on a short trunk.
    static func pine(base: CGPoint, height: Double) -> Path {
        var p = Path()
        let w = height * 0.42
        for tier in 0..<3 {
            let t = Double(tier)
            let top = base.y - height + t * height * 0.22
            let bottom = base.y - height * 0.25 - (2 - t) * height * 0.12
            let half = w * (0.45 + t * 0.28)
            p.move(to: CGPoint(x: base.x, y: top))
            p.addLine(to: CGPoint(x: base.x + half, y: bottom))
            p.addLine(to: CGPoint(x: base.x - half, y: bottom))
            p.closeSubpath()
        }
        p.addRect(CGRect(x: base.x - w * 0.06, y: base.y - height * 0.25, width: w * 0.12, height: height * 0.25))
        return p
    }

    /// Soft, slanted rain. `density` 0…1; slow enough to stay calming.
    static func rain(_ c: inout GraphicsContext, _ s: CGSize, density: Double, time: Double, seed: UInt64 = 21,
                     color: Color = Color(red: 0.8, green: 0.88, blue: 1), opacity: Double = 0.3, region: CGRect? = nil) {
        let area = region ?? CGRect(origin: .zero, size: s)
        var rng = SeededGenerator(seed: seed)
        for _ in 0..<Int(220 * density) {
            let x0 = Double.random(in: 0...1, using: &rng)
            let offset = Double.random(in: 0...1, using: &rng)
            let speed = Double.random(in: 160...260, using: &rng)
            let length = Double.random(in: 8...16, using: &rng)
            let travel = area.height + 30
            let y = area.minY + (time * speed + offset * travel).truncatingRemainder(dividingBy: travel) - 15
            let x = area.minX + x0 * area.width + (y - area.minY) * 0.08
            var streak = Path()
            streak.move(to: CGPoint(x: x, y: y))
            streak.addLine(to: CGPoint(x: x + length * 0.08, y: y + length))
            c.stroke(streak, with: .color(color.opacity(opacity)), lineWidth: 1)
        }
    }

    /// Slow, drifting flakes or motes.
    static func drift(_ c: inout GraphicsContext, _ s: CGSize, count: Int, time: Double, seed: UInt64,
                      color: Color = .white, speed: ClosedRange<Double> = 10...26, size: ClosedRange<Double> = 1.2...3) {
        var rng = SeededGenerator(seed: seed)
        for _ in 0..<count {
            let x0 = Double.random(in: 0...s.width, using: &rng)
            let y0 = Double.random(in: 0...s.height, using: &rng)
            let v = Double.random(in: speed, using: &rng)
            let r = Double.random(in: size, using: &rng)
            let phase = Double.random(in: 0...(2 * .pi), using: &rng)
            let y = (y0 + time * v).truncatingRemainder(dividingBy: s.height + 10) - 5
            let x = x0 + sin(time * 0.5 + phase) * 8
            c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(color.opacity(0.75)))
        }
    }

    static func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        a.mix(with: b, by: min(max(t, 0), 1))
    }
}
