//
//  PlaceArtHouses.swift
//  Respire
//
//  Places 6–10: The Root Tree, Lighthouse Stairs, Tea House, Night Library,
//  Lantern Bridge.
//

import SwiftUI

extension PlaceArt {
    // MARK: 6 · The Root Tree

    /// A great tree over the night; its roots reach down through bands of rain, one level per breath.
    static func rootTree(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x04050C), bottom: Sketch.hex(0x060814), stars: 150, starsTo: 0.5, time: f.time)

        // The canopy: a swirl of greens, blues, and violet.
        let crown = CGRect(x: -w * 0.1, y: -h * 0.06, width: w * 1.2, height: h * 0.46)
        c.fill(Path(ellipseIn: crown), with: .radialGradient(
            Gradient(colors: [Sketch.hex(0x5A2AA8), Sketch.hex(0x1E5A8A), Sketch.hex(0x1F5A2A), Sketch.hex(0x0A1A0E)]),
            center: CGPoint(x: crown.midX, y: crown.midY), startRadius: 0, endRadius: crown.width / 2))
        var rng = SeededGenerator(seed: 61)
        for i in 0..<70 {
            let a = Double.random(in: 0...(2 * .pi), using: &rng)
            let r = Double.random(in: 0.15...0.48, using: &rng)
            let p = CGPoint(x: crown.midX + cos(a + f.time * 0.02) * crown.width * r, y: crown.midY + sin(a) * crown.height * r)
            let colors = [Sketch.hex(0x4AC07A), Sketch.hex(0x3A8AE0), Sketch.hex(0x2A9A5A)]
            c.fill(Sketch.leaf(at: p, size: Double.random(in: 14...30, using: &rng), angle: a + .pi / 2),
                   with: .color(colors[i % 3].opacity(0.55)))
        }

        // Trunk and roots, warm against the cool night.
        let base = CGPoint(x: w / 2, y: h * 0.42)
        for k in 0..<10 {
            let spread = (Double(k) - 4.5) / 4.5
            var root = Path()
            root.move(to: CGPoint(x: base.x + spread * 8, y: h * 0.3))
            root.addCurve(to: CGPoint(x: w / 2 + spread * w * 0.62, y: h * (0.95 + 0.04 * sin(Double(k)))),
                          control1: CGPoint(x: base.x + spread * w * 0.1, y: h * 0.48),
                          control2: CGPoint(x: w / 2 + spread * w * 0.48, y: h * 0.62))
            Sketch.ink(&c, root, Sketch.hex(0xC0512A, 0.9), width: k % 3 == 0 ? 4 : 2.4)
        }
        // A thin river winding down through the roots.
        var river = Path()
        river.move(to: CGPoint(x: w * 0.55, y: h * 0.32))
        river.addCurve(to: CGPoint(x: w * 0.95, y: h * 0.62), control1: CGPoint(x: w * 0.45, y: h * 0.45), control2: CGPoint(x: w * 0.85, y: h * 0.48))
        Sketch.ink(&c, river, Sketch.hex(0x2AA8C8), width: 3)

        // Bands of rain, the current one bright.
        let names = 5
        for band in 0..<names {
            let top = h * (0.58 + 0.08 * Double(band))
            let rect = CGRect(x: 0, y: top, width: w, height: h * 0.08)
            let isNow = band == f.stage
            c.fill(Path(rect), with: .color(Sketch.hex(0x1E3A8A, isNow ? 0.75 : 0.25 + 0.05 * Double(band))))
            var line = Path()
            line.move(to: CGPoint(x: w * 0.15, y: rect.maxY - 6))
            line.addLine(to: CGPoint(x: w * 0.85, y: rect.maxY - 6))
            c.stroke(line, with: .color(.white.opacity(isNow ? 0.7 : 0.2)), lineWidth: 1)
            if isNow {
                Sketch.rain(&c, s, density: 0.2 + 0.15 * Double(min(band, 2)), time: f.time, seed: UInt64(70 + band), opacity: 0.45, region: rect)
            }
        }
    }

    // MARK: 7 · Lighthouse Stairs

    /// A white tower above a dusk sea; a small light climbs a landing each breath, the lamp turning.
    static func lighthouse(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x1A1840), Sketch.hex(0x6A3A6A), Sketch.hex(0xE8906A)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.72)))
        // Sea and slow waves.
        let sea = h * 0.72
        c.fill(Path(CGRect(x: 0, y: sea, width: w, height: h - sea)), with: .color(Sketch.hex(0x14183A)))
        for row in 0..<6 {
            var wave = Path()
            let y = sea + Double(row) * (h - sea) / 6 + 8
            wave.move(to: CGPoint(x: 0, y: y))
            for x in stride(from: 0.0, through: w, by: 8) {
                wave.addLine(to: CGPoint(x: x, y: y + sin(x / 30 + f.time * 0.6 + Double(row)) * 2.5))
            }
            c.stroke(wave, with: .color(.white.opacity(0.12 + 0.03 * Double(row))), lineWidth: 1)
        }

        // The tower, tapering, with red bands.
        let baseY = sea + 6, topY = h * 0.2
        var tower = Path()
        tower.move(to: CGPoint(x: w * 0.4, y: baseY))
        tower.addLine(to: CGPoint(x: w * 0.45, y: topY))
        tower.addLine(to: CGPoint(x: w * 0.55, y: topY))
        tower.addLine(to: CGPoint(x: w * 0.6, y: baseY))
        tower.closeSubpath()
        c.fill(tower, with: .color(Sketch.hex(0xF2EADF)))
        var bands = c
        bands.clip(to: tower)
        for k in 0..<3 {
            let y = topY + (baseY - topY) * (0.2 + 0.28 * Double(k))
            bands.fill(Path(CGRect(x: 0, y: y, width: w, height: (baseY - topY) * 0.1)), with: .color(Sketch.hex(0xC23A3A)))
        }
        Sketch.ink(&c, tower, Sketch.hex(0x2A1A1A), width: 1.6)

        // Landings: windows that light as the climb passes them.
        for landing in 0..<5 {
            let y = baseY - (baseY - topY) * (0.12 + 0.19 * Double(landing))
            let lit = Double(landing) < f.progress
            c.fill(Path(roundedRect: CGRect(x: w * 0.485, y: y - 8, width: w * 0.03, height: 14), cornerRadius: 3),
                   with: .color(lit ? Sketch.hex(0xFFD27A) : Sketch.hex(0x2A2A3A)))
            if lit { Sketch.glow(&c, at: CGPoint(x: w * 0.5, y: y - 1), radius: 16, color: Sketch.hex(0xFFD27A), opacity: 0.5) }
        }
        // The climber: a small warm light rising with each breath.
        let climbY = baseY - (baseY - topY) * (0.12 + 0.19 * min(f.progress, 4.6))
        Sketch.glow(&c, at: CGPoint(x: w * 0.5, y: climbY), radius: 10, color: .white, opacity: 0.9)

        // Lamp room and its turning beam.
        let lamp = CGPoint(x: w / 2, y: topY - h * 0.03)
        c.fill(Path(CGRect(x: w * 0.44, y: topY - h * 0.06, width: w * 0.12, height: h * 0.06)), with: .color(Sketch.hex(0x2A1A1A)))
        let angle = f.time * 0.5
        let reach = w * 1.2
        var beam = Path()
        beam.move(to: lamp)
        beam.addLine(to: CGPoint(x: lamp.x + cos(angle - 0.12) * reach, y: lamp.y + sin(angle - 0.12) * reach * 0.25))
        beam.addLine(to: CGPoint(x: lamp.x + cos(angle + 0.12) * reach, y: lamp.y + sin(angle + 0.12) * reach * 0.25))
        beam.closeSubpath()
        c.fill(beam, with: .linearGradient(Gradient(colors: [Sketch.hex(0xFFE8A0, 0.25 + 0.4 * f.openness), .clear]),
                                           startPoint: lamp, endPoint: CGPoint(x: lamp.x + cos(angle) * reach, y: lamp.y)))
        Sketch.glow(&c, at: lamp, radius: 24, color: Sketch.hex(0xFFE8A0), opacity: 0.6 + 0.4 * f.openness)
    }

    // MARK: 8 · Tea House

    /// A low table by a paper screen; steam rises on the out-breath and a cup fills each breath.
    static func teaHouse(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.paper(&c, s, Sketch.hex(0xE6D2AE), seed: 8)
        let ink = Sketch.hex(0x3A2A1A)
        // A shoji screen behind.
        let screen = CGRect(x: w * 0.1, y: h * 0.12, width: w * 0.8, height: h * 0.42)
        c.fill(Path(screen), with: .color(Sketch.hex(0xF4EAD4)))
        for k in 1..<4 {
            var v = Path(); v.move(to: CGPoint(x: screen.minX + screen.width * Double(k) / 4, y: screen.minY))
            v.addLine(to: CGPoint(x: screen.minX + screen.width * Double(k) / 4, y: screen.maxY))
            Sketch.ink(&c, v, ink.opacity(0.5), width: 1.2)
        }
        for k in 1..<5 {
            var hz = Path(); hz.move(to: CGPoint(x: screen.minX, y: screen.minY + screen.height * Double(k) / 5))
            hz.addLine(to: CGPoint(x: screen.maxX, y: screen.minY + screen.height * Double(k) / 5))
            Sketch.ink(&c, hz, ink.opacity(0.35), width: 1)
        }
        Sketch.ink(&c, Path(screen), ink, width: 2)
        // Rain shadows on the paper screen.
        Sketch.rain(&c, s, density: 0.3, time: f.time, seed: 81, color: ink, opacity: 0.12, region: screen)

        // The table.
        let table = CGRect(x: w * 0.06, y: h * 0.68, width: w * 0.88, height: h * 0.05)
        c.fill(Path(roundedRect: table, cornerRadius: 4), with: .color(Sketch.hex(0x6A4428)))
        Sketch.ink(&c, Path(roundedRect: table, cornerRadius: 4), ink, width: 1.4)
        // The kettle on the left, its spout turned toward the cups.
        let kettle = CGRect(x: w * 0.08, y: h * 0.56, width: w * 0.2, height: h * 0.12)
        c.fill(Path(ellipseIn: kettle), with: .color(Sketch.hex(0x2E3A34)))
        Sketch.ink(&c, Path(ellipseIn: kettle), ink, width: 1.4)
        var spout = Path()
        spout.move(to: CGPoint(x: kettle.maxX - 4, y: kettle.midY))
        spout.addQuadCurve(to: CGPoint(x: kettle.maxX + w * 0.06, y: kettle.minY + 4), control: CGPoint(x: kettle.maxX + w * 0.04, y: kettle.midY))
        Sketch.ink(&c, spout, Sketch.hex(0x2E3A34), width: 5)
        var handle = Path()
        handle.addArc(center: CGPoint(x: kettle.midX, y: kettle.minY), radius: kettle.width * 0.32, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        Sketch.ink(&c, handle, ink, width: 2)
        // Steam rises as the breath goes out.
        let steam = 1 - f.openness
        for k in 0..<3 {
            var wisp = Path()
            let x0 = kettle.maxX + w * 0.06 + Double(k) * 6
            wisp.move(to: CGPoint(x: x0, y: kettle.minY))
            for step in 1...10 {
                let t = Double(step) / 10
                wisp.addLine(to: CGPoint(x: x0 + sin(t * 6 + f.time + Double(k)) * 8, y: kettle.minY - t * h * 0.16 * (0.4 + steam)))
            }
            c.stroke(wisp, with: .color(.white.opacity(0.6 * steam)), lineWidth: 2)
        }
        // Cups in a row to the right, filled one per breath.
        let count = f.steps
        for i in 0..<count {
            let x = w * (0.44 + 0.48 * Double(i) / Double(max(count - 1, 1)))
            let cup = CGRect(x: x - w * 0.045, y: h * 0.62, width: w * 0.09, height: h * 0.055)
            var bowl = Path()
            bowl.move(to: CGPoint(x: cup.minX, y: cup.minY))
            bowl.addLine(to: CGPoint(x: cup.maxX, y: cup.minY))
            bowl.addQuadCurve(to: CGPoint(x: cup.minX, y: cup.minY), control: CGPoint(x: cup.midX, y: cup.maxY + cup.height * 0.6))
            c.fill(bowl, with: .color(Sketch.hex(0xF0E6D6)))
            Sketch.ink(&c, bowl, ink, width: 1.2)
            let fill = min(max(f.progress - Double(i), 0), 1)
            if fill > 0 {
                c.fill(Path(ellipseIn: CGRect(x: cup.minX + 3, y: cup.minY - 2, width: cup.width - 6, height: 5)),
                       with: .color(Sketch.hex(0x8A9A3A, fill)))
            }
        }
    }

    // MARK: 9 · Night Library

    /// Tall shelves under a moonlit arch; a shelf lights warmly with each breath.
    static func nightLibrary(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(Sketch.hex(0x120C08)))
        // Moon window.
        let window = CGRect(x: w * 0.36, y: h * 0.06, width: w * 0.28, height: h * 0.18)
        c.fill(Sketch.arch(window), with: .color(Sketch.hex(0x1A2448)))
        Sketch.glow(&c, at: CGPoint(x: window.midX, y: window.midY), radius: w * 0.12, color: Sketch.hex(0xD8E0FF), opacity: 0.35)
        c.fill(Path(ellipseIn: CGRect(x: window.midX - 14, y: window.midY - 18, width: 28, height: 28)), with: .color(Sketch.hex(0xF2EEDC)))
        Sketch.ink(&c, Sketch.arch(window), Sketch.hex(0x6A4A2A), width: 3)

        // Six shelves in two cases.
        let ink = Sketch.hex(0x3A2410)
        var rng = SeededGenerator(seed: 91)
        let colors = [0x7A2A2A, 0x2A4A6A, 0x6A5A2A, 0x3A5A3A, 0x5A3A6A, 0x8A6A4A].map { Sketch.hex(UInt32($0)) }
        for index in 0..<6 {
            let col = index % 2, row = index / 2
            let shelf = CGRect(x: w * (0.08 + 0.45 * Double(col)), y: h * (0.3 + 0.18 * Double(row)), width: w * 0.39, height: h * 0.15)
            c.fill(Path(shelf), with: .color(Sketch.hex(0x24160C)))
            var x = shelf.minX + 4
            while x < shelf.maxX - 8 {
                let bw = Double.random(in: 6...13, using: &rng)
                let bh = shelf.height * Double.random(in: 0.6...0.92, using: &rng)
                c.fill(Path(CGRect(x: x, y: shelf.maxY - bh, width: bw, height: bh)),
                       with: .color(colors[Int.random(in: 0..<colors.count, using: &rng)].opacity(0.85)))
                x += bw + 1.5
            }
            Sketch.ink(&c, Path(shelf), ink, width: 2)
            let lit = min(max(f.progress - Double(index), 0), 1)
            if lit > 0 {
                c.fill(Path(shelf), with: .linearGradient(Gradient(colors: [Sketch.hex(0xFFC060, 0.35 * lit), .clear]),
                                                          startPoint: CGPoint(x: shelf.midX, y: shelf.minY), endPoint: CGPoint(x: shelf.midX, y: shelf.maxY)))
                Sketch.glow(&c, at: CGPoint(x: shelf.midX, y: shelf.minY + 6), radius: shelf.width * 0.5, color: Sketch.hex(0xFFB050), opacity: 0.25 * lit)
            }
        }
        // A ladder and a candle.
        var ladder = Path()
        ladder.move(to: CGPoint(x: w * 0.47, y: h * 0.86)); ladder.addLine(to: CGPoint(x: w * 0.5, y: h * 0.3))
        ladder.move(to: CGPoint(x: w * 0.53, y: h * 0.86)); ladder.addLine(to: CGPoint(x: w * 0.56, y: h * 0.3))
        for k in 0..<9 {
            let t = Double(k) / 8
            ladder.move(to: CGPoint(x: w * (0.47 + 0.03 * t), y: h * (0.86 - 0.56 * t)))
            ladder.addLine(to: CGPoint(x: w * (0.53 + 0.03 * t), y: h * (0.86 - 0.56 * t)))
        }
        Sketch.ink(&c, ladder, Sketch.hex(0x8A6A3A), width: 1.6)
        let flame = CGPoint(x: w * 0.82, y: h * 0.88)
        Sketch.glow(&c, at: flame, radius: w * (0.12 + 0.05 * f.openness), color: Sketch.hex(0xFFA040), opacity: 0.5)
        c.fill(Path(roundedRect: CGRect(x: flame.x - 4, y: flame.y, width: 8, height: 18), cornerRadius: 2), with: .color(Sketch.hex(0xF0E0C0)))
        c.fill(Path(ellipseIn: CGRect(x: flame.x - 3, y: flame.y - 9, width: 6, height: 10)), with: .color(Sketch.hex(0xFFD070)))
    }

    // MARK: 10 · Lantern Bridge

    /// An arched bridge over a night river; a lantern lights with each breath, doubled in the water.
    static func lanternBridge(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x070A1E), bottom: Sketch.hex(0x14183A), stars: 160, starsTo: 0.5, time: f.time)
        let water = h * 0.6
        c.fill(Path(CGRect(x: 0, y: water, width: w, height: h - water)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x14183A), Sketch.hex(0x05060E)]), startPoint: CGPoint(x: 0, y: water), endPoint: CGPoint(x: 0, y: h)))

        // The bridge arch.
        let left = CGPoint(x: -w * 0.05, y: water), right = CGPoint(x: w * 1.05, y: water)
        let crest = CGPoint(x: w / 2, y: h * 0.4)
        var deck = Path()
        deck.move(to: left)
        deck.addQuadCurve(to: right, control: CGPoint(x: crest.x, y: crest.y - h * 0.12))
        Sketch.ink(&c, deck, Sketch.hex(0x8A5A3A), width: 8)
        var underside = Path()
        underside.move(to: CGPoint(x: w * 0.12, y: water))
        underside.addQuadCurve(to: CGPoint(x: w * 0.88, y: water), control: CGPoint(x: w / 2, y: h * 0.42))
        Sketch.ink(&c, underside, Sketch.hex(0x5A3A2A), width: 3)

        // Lanterns along the railing, and their reflections.
        let count = f.steps
        for i in 0..<count {
            let t = (Double(i) + 0.5) / Double(count)
            let x = left.x + (right.x - left.x) * t
            // On the deck curve (a quadratic Bézier), lifted onto the railing.
            let y = water + (crest.y - h * 0.12 - water) * 2 * t * (1 - t) - h * 0.05
            var post = Path()
            post.move(to: CGPoint(x: x, y: y + h * 0.05)); post.addLine(to: CGPoint(x: x, y: y + 6))
            c.stroke(post, with: .color(Sketch.hex(0x5A3A2A)), lineWidth: 2)
            let lit = min(max(f.progress - Double(i), 0), 1)
            let lantern = CGRect(x: x - 6, y: y - 8, width: 12, height: 14)
            c.fill(Path(roundedRect: lantern, cornerRadius: 3),
                   with: .color(lit > 0 ? Sketch.hex(0xFFB050, 0.4 + 0.6 * lit) : Sketch.hex(0x3A2A2A)))
            if lit > 0 {
                Sketch.glow(&c, at: CGPoint(x: x, y: y - 1), radius: 26 * (0.7 + 0.3 * f.openness), color: Sketch.hex(0xFFB050), opacity: 0.6 * lit)
                let ry = water + (water - y) * 0.6 + sin(f.time * 1.4 + Double(i)) * 2
                c.fill(Path(ellipseIn: CGRect(x: x - 4, y: ry, width: 8, height: 18)), with: .color(Sketch.hex(0xFFB050, 0.35 * lit)))
            }
        }
        // Ripples across the river.
        for k in 0..<10 {
            let y = water + Double(k + 1) * (h - water) / 11
            var ripple = Path()
            ripple.move(to: CGPoint(x: w * 0.1, y: y))
            ripple.addLine(to: CGPoint(x: w * 0.9, y: y + sin(f.time + Double(k)) * 1.5))
            c.stroke(ripple, with: .color(.white.opacity(0.06)), lineWidth: 1)
        }
    }
}
