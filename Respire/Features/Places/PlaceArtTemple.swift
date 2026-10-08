//
//  PlaceArtTemple.swift
//  Respire
//
//  Place 21: Singing Bowl Temple. Seven bowls on a low altar, low to high. Each
//  breath rings one: rings of sound spread from it, and the water inside it
//  stands up into a small cymatic figure. High in the round window, every bowl
//  rung adds a layer to one great mandala, its rings turning against each other,
//  until all seven sing together and the window fills with light.
//

import SwiftUI

extension PlaceArt {
    // MARK: 21 · Singing Bowl Temple

    static func bowlTemple(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height

        // A dim temple interior, warm wood below and shadow above.
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x0C0812), Sketch.hex(0x1E140E), Sketch.hex(0x2A1A10)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))

        templeWindow(&c, s, f)

        // Lacquered pillars framing the hall.
        for x in [w * 0.06, w * 0.94] {
            let pillar = CGRect(x: x - w * 0.035, y: 0, width: w * 0.07, height: h * 0.76)
            c.fill(Path(pillar), with: .linearGradient(
                Gradient(colors: [Sketch.hex(0x3A120E), Sketch.hex(0x6A2418), Sketch.hex(0x3A120E)]),
                startPoint: CGPoint(x: pillar.minX, y: 0), endPoint: CGPoint(x: pillar.maxX, y: 0)))
            Sketch.ink(&c, Path(pillar), Sketch.hex(0x1A0806, 0.6), width: 1)
        }

        // A plank floor.
        let floor = h * 0.76
        c.fill(Path(CGRect(x: 0, y: floor, width: w, height: h - floor)), with: .color(Sketch.hex(0x2E1C10)))
        for k in 1..<6 {
            var plank = Path()
            let y = floor + (h - floor) * pow(Double(k) / 6, 1.4)
            plank.move(to: CGPoint(x: 0, y: y))
            plank.addLine(to: CGPoint(x: w, y: y))
            c.stroke(plank, with: .color(Sketch.hex(0x1A0E06, 0.7)), lineWidth: 1)
        }

        // Candles at either side, flickering.
        for (k, x) in [w * 0.16, w * 0.84].enumerated() {
            let flame = CGPoint(x: x, y: floor + h * 0.05)
            let flicker = 0.85 + 0.15 * sin(f.time * 7 + Double(k) * 2.3)
            Sketch.glow(&c, at: flame, radius: w * 0.12, color: Sketch.hex(0xFFB060), opacity: 0.35 * flicker)
            c.fill(Path(CGRect(x: x - 4, y: flame.y + 2, width: 8, height: 20)), with: .color(Sketch.hex(0xF0E2C8)))
            c.fill(Path(ellipseIn: CGRect(x: x - 2.5, y: flame.y - 7 * flicker, width: 5, height: 9 * flicker)),
                   with: .color(Sketch.hex(0xFFE0A0)))
        }

        // The altar, and its seven bowls, largest and lowest first.
        let altar = CGRect(x: w * 0.04, y: floor - h * 0.035, width: w * 0.92, height: h * 0.035)
        c.fill(Path(altar), with: .color(Sketch.hex(0x3E2614)))
        Sketch.ink(&c, Path(altar), Sketch.hex(0x1A0E06, 0.7), width: 1)
        let count = f.steps
        for i in 0..<count {
            let t = Double(i) / Double(max(count - 1, 1))
            let width = w * (0.125 - 0.045 * t)
            let rim = CGPoint(x: w * (0.11 + 0.78 * t), y: altar.minY - width * 0.42)
            let rung = min(max(f.progress - Double(i), 0), 1)
            let isRinging = f.completed < f.steps && i == f.stage
            singingBowl(&c, rim: rim, width: width, index: i, rung: rung, isRinging: isRinging, f: f)
        }
    }

    /// The round window high in the hall: the night sky, and the great mandala that
    /// grows one layer for every bowl rung.
    private static func templeWindow(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        // Low enough to clear the arrival words above it, high enough to float over the altar.
        let center = CGPoint(x: w / 2, y: h * 0.47)
        let radius = min(w * 0.4, h * 0.19)
        let window = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

        var sky = c
        sky.clip(to: window)
        Sketch.night(&sky, s, top: Sketch.hex(0x060A20), bottom: Sketch.hex(0x141838), stars: 90, starsTo: 0.6, time: f.time)

        // Each layer turns against its neighbors and breathes with you.
        let breath = 0.94 + 0.06 * f.openness
        for i in 0..<f.steps {
            let amount = min(max(f.progress - Double(i), 0), 1)
            guard amount > 0 else { continue }
            let folds = Double(3 + i)
            let r = radius * (0.16 + 0.11 * Double(i)) * breath
            let turn = f.time * 0.05 * (i.isMultiple(of: 2) ? 1 : -1)
            let petals = rosette(center: center, radius: r, folds: folds * 2, depth: 0.16, squash: 1, turn: turn)
            let color = Theme.prism[i % Theme.prism.count]
            sky.stroke(petals, with: .color(color.opacity(0.75 * amount)), lineWidth: 1.4)
            sky.stroke(petals, with: .color(color.opacity(0.18 * amount)), lineWidth: 6)
        }
        // A heart of light that brightens as the mandala fills, and blooms when it's whole.
        let fill = f.fraction
        Sketch.glow(&sky, at: center, radius: radius * (0.3 + 0.5 * fill), color: Sketch.hex(0xFFF4E0), opacity: 0.12 + 0.3 * fill)
        if f.completed == f.steps {
            Sketch.glow(&sky, at: center, radius: radius, color: Sketch.hex(0xF8F0FF), opacity: 0.25 + 0.08 * sin(f.time * 0.8))
        }

        c.stroke(window, with: .color(Sketch.hex(0x5A3A22)), lineWidth: 7)
        Sketch.ink(&c, window, Sketch.hex(0x1A0E06, 0.7), width: 1)
    }

    /// One brass bowl on its cushion. Once rung it keeps singing: rings of sound spread
    /// from it, and its water holds a slowly turning figure with `index + 3` folds.
    private static func singingBowl(_ c: inout GraphicsContext, rim: CGPoint, width: Double, index: Int,
                                    rung: Double, isRinging: Bool, f: PlaceFrame) {
        let half = width / 2
        let depth = width * 0.5
        let color = Theme.prism[index % Theme.prism.count]

        // The cushion.
        c.fill(Path(ellipseIn: CGRect(x: rim.x - half * 0.85, y: rim.y + depth * 0.82, width: half * 1.7, height: depth * 0.36)),
               with: .color(Sketch.hex(0x7A2A20)))

        // The bowl's body, a deep curve beneath the rim.
        var body = Path()
        body.move(to: CGPoint(x: rim.x - half, y: rim.y))
        body.addCurve(to: CGPoint(x: rim.x + half, y: rim.y),
                      control1: CGPoint(x: rim.x - half, y: rim.y + depth * 1.3),
                      control2: CGPoint(x: rim.x + half, y: rim.y + depth * 1.3))
        body.closeSubpath()
        c.fill(body, with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x8A6228), Sketch.hex(0xD8AA58), Sketch.hex(0x6A4A1E)]),
            startPoint: CGPoint(x: rim.x - half, y: rim.y), endPoint: CGPoint(x: rim.x + half, y: rim.y)))
        Sketch.ink(&c, body, Sketch.hex(0x3A2410, 0.6), width: 1)

        // The rim, and the water inside it.
        let mouth = CGRect(x: rim.x - half, y: rim.y - width * 0.1, width: width, height: width * 0.2)
        c.fill(Path(ellipseIn: mouth), with: .color(Sketch.hex(0x141826)))
        c.stroke(Path(ellipseIn: mouth), with: .color(Sketch.hex(0xF0D08A)), lineWidth: 1.6)

        let singing = isRinging ? rung : (rung >= 1 ? 1 : 0)
        guard singing > 0 else { return }

        // The water stands up into a figure, squashed by the angle we see it from.
        var water = c
        water.clip(to: Path(ellipseIn: mouth.insetBy(dx: 2, dy: 1)))
        let figure = rosette(center: rim, radius: half * 0.8, folds: Double(index + 3) * 2, depth: 0.3,
                             squash: 0.2, turn: f.time * 0.2)
        water.stroke(figure, with: .color(color.opacity(0.85 * singing)), lineWidth: 1)
        Sketch.glow(&water, at: rim, radius: half * 0.6, color: color, opacity: 0.4 * singing)

        // Rings of sound spreading into the hall. The ringing bowl's are strongest.
        let strength = isRinging ? 0.55 * (0.4 + 0.6 * f.openness) : 0.18
        for k in 0..<3 {
            let phase = (f.time * (isRinging ? 0.45 : 0.25) + Double(k) / 3 + Double(index) * 0.13)
                .truncatingRemainder(dividingBy: 1)
            let r = half * (1.1 + 2.4 * phase)
            let ring = Path(ellipseIn: CGRect(x: rim.x - r, y: rim.y - r * 0.32, width: r * 2, height: r * 0.64))
            c.stroke(ring, with: .color(Sketch.mix(color, .white, 0.5).opacity(strength * (1 - phase) * singing)), lineWidth: 1.2)
        }
    }

    /// A closed petal curve: `radius` swelling and narrowing `folds` times around, turned by `turn`.
    /// `squash` flattens it vertically, for figures seen at an angle.
    private static func rosette(center: CGPoint, radius: Double, folds: Double, depth: Double, squash: Double, turn: Double) -> Path {
        var path = Path()
        let segments = 240
        for k in 0...segments {
            let theta = Double(k) / Double(segments) * 2 * .pi
            let r = radius * (1 - depth + depth * cos(folds * theta))
            let point = CGPoint(x: center.x + r * cos(theta + turn), y: center.y + r * sin(theta + turn) * squash)
            if k == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
