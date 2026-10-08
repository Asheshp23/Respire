//
//  PlaceArtSkies.swift
//  Respire
//
//  Places 11–15: Snow Cabin, Deep Sea Elevator, Star Observatory, Cloud Ferry,
//  Greenhouse.
//

import SwiftUI

extension PlaceArt {
    // MARK: 11 · Snow Cabin

    /// Snowfall over a cabin in the pines; the window warms a little more each breath.
    static func snowCabin(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x0A1230), bottom: Sketch.hex(0x2A3A6A), stars: 90, starsTo: 0.45, time: f.time)
        // Snowy hills.
        for (i, y) in [0.62, 0.7].enumerated() {
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: h))
            for x in stride(from: 0.0, through: w, by: 8) {
                hill.addLine(to: CGPoint(x: x, y: h * y - sin(x / w * 3 + Double(i) * 2) * h * 0.04))
            }
            hill.addLine(to: CGPoint(x: w, y: h)); hill.closeSubpath()
            c.fill(hill, with: .color(Sketch.hex(i == 0 ? 0xC8D4EE : 0xEAF0FA)))
        }
        for (x, height) in [(0.12, 0.2), (0.2, 0.15), (0.8, 0.22), (0.88, 0.16), (0.7, 0.13)] {
            c.fill(Sketch.pine(base: CGPoint(x: w * x, y: h * 0.68), height: h * height), with: .color(Sketch.hex(0x14243A)))
        }
        // The cabin.
        let body = CGRect(x: w * 0.34, y: h * 0.56, width: w * 0.32, height: h * 0.13)
        c.fill(Path(body), with: .color(Sketch.hex(0x4A2E1E)))
        var roof = Path()
        roof.move(to: CGPoint(x: body.minX - 12, y: body.minY + 4))
        roof.addLine(to: CGPoint(x: body.midX, y: body.minY - h * 0.07))
        roof.addLine(to: CGPoint(x: body.maxX + 12, y: body.minY + 4))
        roof.closeSubpath()
        c.fill(roof, with: .color(.white))
        Sketch.ink(&c, roof, Sketch.hex(0x8A9AC0), width: 1.2)
        // The window warms as the fire catches (stages 2–3).
        let warmth = min(max((f.progress - 1) / Double(max(f.steps - 1, 1)), 0.15), 1)
        let window = CGRect(x: body.midX - w * 0.05, y: body.minY + h * 0.03, width: w * 0.1, height: h * 0.055)
        Sketch.glow(&c, at: CGPoint(x: window.midX, y: window.midY), radius: w * 0.25 * warmth, color: Sketch.hex(0xFFA850), opacity: 0.5 * warmth)
        c.fill(Path(window), with: .color(Sketch.hex(0xFFC070, 0.35 + 0.65 * warmth)))
        var cross = Path()
        cross.move(to: CGPoint(x: window.midX, y: window.minY)); cross.addLine(to: CGPoint(x: window.midX, y: window.maxY))
        cross.move(to: CGPoint(x: window.minX, y: window.midY)); cross.addLine(to: CGPoint(x: window.maxX, y: window.midY))
        c.stroke(cross, with: .color(Sketch.hex(0x4A2E1E)), lineWidth: 1.5)
        // Chimney smoke, once the fire's going.
        if warmth > 0.3 {
            for k in 0..<4 {
                let t = (f.time * 0.08 + Double(k) / 4).truncatingRemainder(dividingBy: 1)
                let p = CGPoint(x: body.maxX - w * 0.06 + sin(t * 5) * 10 + t * w * 0.08, y: body.minY - h * 0.06 - t * h * 0.18)
                c.fill(Path(ellipseIn: CGRect(x: p.x - 10 - t * 12, y: p.y - 6, width: 20 + t * 24, height: 12 + t * 10)),
                       with: .color(.white.opacity(0.25 * (1 - t) * warmth)))
            }
        }
        // More snow early on, settling to a few flakes.
        let flakes = Int(140 - 25 * Double(f.stage))
        Sketch.drift(&c, s, count: flakes, time: f.time, seed: 111, color: .white, speed: 14...30, size: 1.5...3.5)
    }

    // MARK: 12 · Deep Sea Elevator

    /// A small cage sinking through the sea; each breath takes it deeper, darker, and quieter.
    static func deepSea(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        let depth = f.fraction
        let top = Sketch.mix(Sketch.hex(0x2A9AC8), Sketch.hex(0x020814), depth)
        let bottom = Sketch.mix(Sketch.hex(0x0A3A6A), Sketch.hex(0x000206), depth)
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(Gradient(colors: [top, bottom]),
                                                                          startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        // Sunlight shafts fade with depth.
        for k in 0..<5 {
            var ray = Path()
            let x = w * (0.1 + 0.2 * Double(k)) + sin(f.time * 0.2 + Double(k)) * 10
            ray.move(to: CGPoint(x: x, y: 0))
            ray.addLine(to: CGPoint(x: x + w * 0.08, y: 0))
            ray.addLine(to: CGPoint(x: x + w * 0.2, y: h * 0.8))
            ray.addLine(to: CGPoint(x: x + w * 0.1, y: h * 0.8))
            ray.closeSubpath()
            c.fill(ray, with: .linearGradient(Gradient(colors: [.white.opacity(0.12 * (1 - depth)), .clear]),
                                              startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x, y: h * 0.8)))
        }
        // Rising bubbles.
        var rng = SeededGenerator(seed: 121)
        for _ in 0..<40 {
            let x = Double.random(in: 0...w, using: &rng)
            let v = Double.random(in: 14...30, using: &rng)
            let y = h - (Double.random(in: 0...h, using: &rng) + f.time * v).truncatingRemainder(dividingBy: h + 20)
            let r = Double.random(in: 2...5, using: &rng)
            c.stroke(Path(ellipseIn: CGRect(x: x + sin(f.time + y / 40) * 4, y: y, width: r, height: r)), with: .color(.white.opacity(0.35)), lineWidth: 0.8)
        }
        // Glowing jellies appear in the deep.
        if depth > 0.35 {
            let glow = (depth - 0.35) / 0.65
            for k in 0..<5 {
                let p = CGPoint(x: w * (0.15 + 0.18 * Double(k)), y: h * (0.3 + 0.12 * sin(Double(k) * 2 + f.time * 0.3)))
                Sketch.glow(&c, at: p, radius: 22, color: [Sketch.hex(0x8AF0FF), Sketch.hex(0xC08AFF)][k % 2], opacity: 0.5 * glow)
                var bell = Path()
                bell.addArc(center: p, radius: 9, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                c.stroke(bell, with: .color(.white.opacity(0.6 * glow)), lineWidth: 1.2)
                for t in 0..<3 {
                    var tentacle = Path()
                    tentacle.move(to: CGPoint(x: p.x - 6 + Double(t) * 6, y: p.y))
                    tentacle.addQuadCurve(to: CGPoint(x: p.x - 6 + Double(t) * 6, y: p.y + 22),
                                          control: CGPoint(x: p.x - 6 + Double(t) * 6 + sin(f.time + Double(t)) * 6, y: p.y + 11))
                    c.stroke(tentacle, with: .color(.white.opacity(0.4 * glow)), lineWidth: 0.8)
                }
            }
        }
        // The elevator: a lit cage on a cable, gently swaying.
        let sway = sin(f.time * 0.4) * 4
        let cage = CGRect(x: w / 2 - w * 0.11 + sway, y: h * 0.48, width: w * 0.22, height: h * 0.22)
        var cable = Path()
        cable.move(to: CGPoint(x: w / 2, y: 0)); cable.addLine(to: CGPoint(x: cage.midX, y: cage.minY))
        c.stroke(cable, with: .color(.white.opacity(0.4)), lineWidth: 1.2)
        Sketch.glow(&c, at: CGPoint(x: cage.midX, y: cage.midY), radius: w * 0.3, color: Sketch.hex(0xFFE0A0), opacity: 0.18)
        c.fill(Path(roundedRect: cage, cornerRadius: 8), with: .color(Sketch.hex(0xFFE0A0, 0.12)))
        for k in 0...4 {
            var bar = Path()
            let x = cage.minX + cage.width * Double(k) / 4
            bar.move(to: CGPoint(x: x, y: cage.minY)); bar.addLine(to: CGPoint(x: x, y: cage.maxY))
            c.stroke(bar, with: .color(Sketch.hex(0xD8C8A0, 0.7)), lineWidth: 1.4)
        }
        Sketch.ink(&c, Path(roundedRect: cage, cornerRadius: 8), Sketch.hex(0xD8C8A0), width: 2)
        // The sea floor rises into view at the end.
        if depth > 0.75 {
            var floor = Path()
            floor.move(to: CGPoint(x: 0, y: h))
            for x in stride(from: 0.0, through: w, by: 10) {
                floor.addLine(to: CGPoint(x: x, y: h * (1.02 - 0.12 * (depth - 0.75) * 4) + sin(x / 40) * 6))
            }
            floor.addLine(to: CGPoint(x: w, y: h)); floor.closeSubpath()
            c.fill(floor, with: .color(Sketch.hex(0x0A1A24)))
        }
    }

    // MARK: 13 · Star Observatory

    /// The dome opens to the sky; a constellation draws itself with each breath.
    static func observatory(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x020414), bottom: Sketch.hex(0x0A1030), stars: 200, starsTo: 0.7, time: f.time)
        let constellations: [[CGPoint]] = [
            [CGPoint(x: 0.12, y: 0.12), CGPoint(x: 0.2, y: 0.08), CGPoint(x: 0.28, y: 0.14), CGPoint(x: 0.24, y: 0.22), CGPoint(x: 0.14, y: 0.2)],
            [CGPoint(x: 0.6, y: 0.06), CGPoint(x: 0.68, y: 0.12), CGPoint(x: 0.76, y: 0.1), CGPoint(x: 0.86, y: 0.16)],
            [CGPoint(x: 0.4, y: 0.24), CGPoint(x: 0.46, y: 0.18), CGPoint(x: 0.52, y: 0.26), CGPoint(x: 0.46, y: 0.32), CGPoint(x: 0.4, y: 0.24)],
            [CGPoint(x: 0.08, y: 0.36), CGPoint(x: 0.16, y: 0.32), CGPoint(x: 0.22, y: 0.4), CGPoint(x: 0.3, y: 0.36)],
            [CGPoint(x: 0.66, y: 0.3), CGPoint(x: 0.74, y: 0.26), CGPoint(x: 0.82, y: 0.32), CGPoint(x: 0.78, y: 0.4), CGPoint(x: 0.7, y: 0.38)],
        ]
        for (i, stars) in constellations.enumerated() {
            let shown = min(max(f.progress - Double(i), 0), 1)
            let points = stars.map { CGPoint(x: $0.x * w, y: $0.y * h) }
            if shown > 0 {
                var lines = Path()
                lines.move(to: points[0])
                let segments = Double(points.count - 1) * shown
                for k in 1..<points.count where Double(k) <= segments + 1 {
                    let a = points[k - 1], b = points[k]
                    let t = min(max(segments - Double(k - 1), 0), 1)
                    lines.addLine(to: CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
                }
                c.stroke(lines, with: .color(Sketch.hex(0xA8B8FF, 0.6)), lineWidth: 1)
            }
            for p in points {
                Sketch.glow(&c, at: p, radius: shown > 0 ? 9 : 4, color: .white, opacity: shown > 0 ? 0.9 : 0.35)
            }
        }
        // The dome and its open slit.
        let dome = CGRect(x: w * 0.1, y: h * 0.58, width: w * 0.8, height: h * 0.5)
        var shell = Path()
        shell.addArc(center: CGPoint(x: dome.midX, y: dome.minY + dome.width / 2), radius: dome.width / 2,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        shell.addLine(to: CGPoint(x: dome.maxX, y: h)); shell.addLine(to: CGPoint(x: dome.minX, y: h)); shell.closeSubpath()
        c.fill(shell, with: .linearGradient(Gradient(colors: [Sketch.hex(0x3A3A5A), Sketch.hex(0x14142A)]),
                                            startPoint: CGPoint(x: dome.minX, y: dome.minY), endPoint: CGPoint(x: dome.maxX, y: dome.maxY)))
        let slit = CGRect(x: dome.midX - w * 0.05, y: dome.minY - 2, width: w * 0.1, height: dome.width * 0.32)
        c.fill(Path(slit), with: .color(Sketch.hex(0x060818)))
        // The telescope pointing up through the slit.
        var scope = Path()
        scope.move(to: CGPoint(x: dome.midX - 8, y: dome.minY + dome.width * 0.32))
        scope.addLine(to: CGPoint(x: dome.midX + 18, y: dome.minY + 6))
        c.stroke(scope, with: .color(Sketch.hex(0xC8C8D8)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
        Sketch.ink(&c, shell, Sketch.hex(0x8A8AB0, 0.5), width: 1.2)
    }

    // MARK: 14 · Cloud Ferry

    /// A little ferry on a sea of cloud, gliding to a new island each breath.
    static func cloudFerry(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x8AA8E0), Sketch.hex(0xF0C0C8), Sketch.hex(0xFFE0C0)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        Sketch.glow(&c, at: CGPoint(x: w * 0.75, y: h * 0.2), radius: w * 0.3, color: .white, opacity: 0.6)
        // Islands drift past: the scene slides one island per breath.
        let shift = f.progress * w * 0.55 + f.time * 3
        for k in 0..<7 {
            let x = w * 0.2 + Double(k) * w * 0.55 - shift
            guard x > -w * 0.5, x < w * 1.5 else { continue }
            let island = CGRect(x: x - w * 0.18, y: h * 0.44, width: w * 0.36, height: h * 0.1)
            for b in 0..<5 {
                let r = island.width * (0.18 + 0.05 * Double(b % 3))
                c.fill(Path(ellipseIn: CGRect(x: island.minX + island.width * Double(b) / 5, y: island.midY - r * 0.6, width: r * 1.6, height: r)),
                       with: .color(.white.opacity(0.95)))
            }
            // A tiny house on each island.
            let house = CGRect(x: island.midX - 10, y: island.minY - 4, width: 20, height: 14)
            c.fill(Path(house), with: .color(Sketch.hex(0xE89A8A)))
            var roof = Path()
            roof.move(to: CGPoint(x: house.minX - 3, y: house.minY)); roof.addLine(to: CGPoint(x: house.midX, y: house.minY - 9))
            roof.addLine(to: CGPoint(x: house.maxX + 3, y: house.minY)); roof.closeSubpath()
            c.fill(roof, with: .color(Sketch.hex(0x8A5A7A)))
        }
        // The cloud sea, in soft rolling bands.
        for band in 0..<4 {
            let y = h * (0.6 + 0.1 * Double(band))
            var sea = Path()
            sea.move(to: CGPoint(x: 0, y: h))
            for x in stride(from: 0.0, through: w, by: 10) {
                sea.addLine(to: CGPoint(x: x, y: y + sin(x / 50 + f.time * 0.3 + Double(band)) * 8))
            }
            sea.addLine(to: CGPoint(x: w, y: h)); sea.closeSubpath()
            c.fill(sea, with: .color(.white.opacity(0.55 + 0.1 * Double(band))))
        }
        // The ferry, bobbing with the breath.
        let bob = (f.openness - 0.5) * 8
        let hull = CGRect(x: w * 0.36, y: h * 0.6 + bob, width: w * 0.28, height: h * 0.04)
        var boat = Path()
        boat.move(to: CGPoint(x: hull.minX, y: hull.minY))
        boat.addLine(to: CGPoint(x: hull.maxX, y: hull.minY))
        boat.addLine(to: CGPoint(x: hull.maxX - 14, y: hull.maxY))
        boat.addLine(to: CGPoint(x: hull.minX + 14, y: hull.maxY))
        boat.closeSubpath()
        c.fill(boat, with: .color(Sketch.hex(0x5A6A9A)))
        let cabin = CGRect(x: hull.midX - 22, y: hull.minY - 18, width: 44, height: 18)
        c.fill(Path(roundedRect: cabin, cornerRadius: 4), with: .color(Sketch.hex(0xF8F0E8)))
        var mast = Path()
        mast.move(to: CGPoint(x: hull.midX, y: cabin.minY)); mast.addLine(to: CGPoint(x: hull.midX, y: cabin.minY - 26))
        c.stroke(mast, with: .color(Sketch.hex(0x5A6A9A)), lineWidth: 1.5)
        var flag = Path()
        flag.move(to: CGPoint(x: hull.midX, y: cabin.minY - 26))
        flag.addLine(to: CGPoint(x: hull.midX + 14 + sin(f.time * 3) * 2, y: cabin.minY - 21))
        flag.addLine(to: CGPoint(x: hull.midX, y: cabin.minY - 16)); flag.closeSubpath()
        c.fill(flag, with: .color(Sketch.hex(0xE86A6A)))
    }

    // MARK: 15 · Greenhouse

    /// A glass house in the evening rain; a flower grows and opens with each breath.
    static func greenhouse(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x1A3A34), Sketch.hex(0x2A4A3A), Sketch.hex(0x14241E)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        // The glass house frame.
        let frame = CGRect(x: w * 0.06, y: h * 0.14, width: w * 0.88, height: h * 0.74)
        let ink = Sketch.hex(0xD8E8D0, 0.6)
        Sketch.ink(&c, Sketch.arch(frame), ink, width: 2.4)
        for k in 1..<5 {
            var mullion = Path()
            let x = frame.minX + frame.width * Double(k) / 5
            mullion.move(to: CGPoint(x: x, y: frame.maxY)); mullion.addLine(to: CGPoint(x: x, y: frame.minY + frame.width * 0.15))
            c.stroke(mullion, with: .color(ink.opacity(0.5)), lineWidth: 1.2)
        }
        for k in 1..<4 {
            var rail = Path()
            let y = frame.minY + frame.width * 0.5 + (frame.height - frame.width * 0.5) * Double(k) / 4
            rail.move(to: CGPoint(x: frame.minX, y: y)); rail.addLine(to: CGPoint(x: frame.maxX, y: y))
            c.stroke(rail, with: .color(ink.opacity(0.35)), lineWidth: 1)
        }
        var glass = c
        glass.clip(to: Sketch.arch(frame))
        Sketch.rain(&glass, s, density: 0.35, time: f.time, seed: 151, opacity: 0.25, region: frame)

        // A row of pots; each flower rises, then opens with the in-breath.
        let count = f.steps
        let palette = [0xF2A0B8, 0xF8D070, 0xC8A0F0, 0xF0907A, 0xA0D0F8].map { Sketch.hex(UInt32($0)) }
        for i in 0..<count {
            let x = frame.minX + frame.width * (Double(i) + 0.5) / Double(count)
            let pot = CGRect(x: x - w * 0.05, y: h * 0.78, width: w * 0.1, height: h * 0.07)
            var shape = Path()
            shape.move(to: CGPoint(x: pot.minX, y: pot.minY)); shape.addLine(to: CGPoint(x: pot.maxX, y: pot.minY))
            shape.addLine(to: CGPoint(x: pot.maxX - 6, y: pot.maxY)); shape.addLine(to: CGPoint(x: pot.minX + 6, y: pot.maxY)); shape.closeSubpath()
            c.fill(shape, with: .color(Sketch.hex(0xB0603A)))
            let grow = min(max(f.progress - Double(i), 0), 1)
            guard grow > 0 else { continue }
            let top = CGPoint(x: x + sin(f.time * 0.5 + Double(i)) * 3, y: pot.minY - h * 0.2 * grow)
            var stem = Path()
            stem.move(to: CGPoint(x: x, y: pot.minY))
            stem.addQuadCurve(to: top, control: CGPoint(x: x - 10, y: pot.minY - h * 0.1 * grow))
            c.stroke(stem, with: .color(Sketch.hex(0x6AB06A)), lineWidth: 2)
            c.fill(Sketch.leaf(at: CGPoint(x: x - 2, y: pot.minY - h * 0.07 * grow), size: 18 * grow, angle: -2.4), with: .color(Sketch.hex(0x6AB06A)))
            // Petals open once the stem is grown, wider on the in-breath.
            let bloom = grow * (grow >= 1 ? 0.75 + 0.25 * f.openness : 0.4)
            for petal in 0..<6 {
                let a = Double(petal) / 6 * 2 * .pi + f.time * 0.05
                let center = CGPoint(x: top.x + cos(a) * 9 * bloom, y: top.y + sin(a) * 9 * bloom)
                c.fill(Path(ellipseIn: CGRect(x: center.x - 7 * bloom, y: center.y - 7 * bloom, width: 14 * bloom, height: 14 * bloom)),
                       with: .color(palette[i % palette.count]))
            }
            c.fill(Path(ellipseIn: CGRect(x: top.x - 4, y: top.y - 4, width: 8, height: 8)), with: .color(Sketch.hex(0xFFE8A0)))
        }
    }
}
