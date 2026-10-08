//
//  PlaceArtStations.swift
//  Respire
//
//  Places 1–5: Dream State Station, Rain Station, Waterfall House,
//  The Sound of the Waterfall, Moth Garden.
//

import SwiftUI

enum PlaceArt {
    /// Draws `place` for one frame.
    static func draw(_ id: String, _ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        switch id {
        case "dream-station": dreamStation(&c, s, f)
        case "rain-station": rainStation(&c, s, f)
        case "waterfall-house": waterfallHouse(&c, s, f)
        case "cabin-falls": cabinFalls(&c, s, f)
        case "moth-garden": mothGarden(&c, s, f)
        case "root-tree": rootTree(&c, s, f)
        case "lighthouse": lighthouse(&c, s, f)
        case "tea-house": teaHouse(&c, s, f)
        case "night-library": nightLibrary(&c, s, f)
        case "lantern-bridge": lanternBridge(&c, s, f)
        case "snow-cabin": snowCabin(&c, s, f)
        case "deep-sea": deepSea(&c, s, f)
        case "observatory": observatory(&c, s, f)
        case "cloud-ferry": cloudFerry(&c, s, f)
        case "greenhouse": greenhouse(&c, s, f)
        case "paper-boats": paperBoats(&c, s, f)
        case "hut-window": hutWindow(&c, s, f)
        case "firefly-meadow": fireflyMeadow(&c, s, f)
        case "moon-gates": moonGates(&c, s, f)
        case "ocean-postbox": oceanPostbox(&c, s, f)
        case "bowl-temple": bowlTemple(&c, s, f)
        default: c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(.black))
        }
    }

    // MARK: 1 · Dream State Station

    /// A night train window: forest and fireflies slide past, one stop per breath.
    static func dreamStation(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(Sketch.hex(0x060707)))
        Sketch.drift(&c, s, count: 60, time: f.time, seed: 1, color: .white.opacity(0.6), speed: 4...10)

        let frame = CGRect(x: w * 0.16, y: h * 0.22, width: w * 0.68, height: h * 0.5)
        let outer = Path(roundedRect: frame, cornerRadius: w * 0.07)
        c.fill(outer, with: .color(Sketch.hex(0xB8641E)))
        Sketch.ink(&c, outer, Sketch.hex(0x2A1606), width: 3)
        let inner = frame.insetBy(dx: w * 0.06, dy: w * 0.07)
        let window = Path(roundedRect: inner, cornerRadius: w * 0.02)
        c.fill(window, with: .color(Sketch.hex(0x0A120B)))

        var view = c
        view.clip(to: window)
        // The forest slides by as the train moves, a little further each breath.
        let shift = f.progress * inner.width * 0.6 + f.time * 6
        var rng = SeededGenerator(seed: 2)
        for _ in 0..<36 {
            let x0 = Double.random(in: 0...(inner.width * 3), using: &rng)
            let span = inner.width * 3
            let x = inner.minX - inner.width + ((x0 - shift).truncatingRemainder(dividingBy: span) + span).truncatingRemainder(dividingBy: span)
            let y = inner.minY + Double.random(in: 0...inner.height, using: &rng)
            let size = Double.random(in: 18...46, using: &rng)
            view.fill(Sketch.leaf(at: CGPoint(x: x, y: y), size: size, angle: Double.random(in: 0...6, using: &rng)),
                      with: .color(Sketch.hex(0x3E5E22, Double.random(in: 0.35...0.8, using: &rng))))
        }
        // Fireflies, brighter on the in-breath.
        for i in 0..<70 {
            let x = inner.minX + Double.random(in: 0...inner.width, using: &rng)
            let y = inner.minY + Double.random(in: 0...inner.height, using: &rng) + sin(f.time + Double(i)) * 4
            let tw = 0.4 + 0.6 * abs(sin(f.time * 0.9 + Double(i)))
            view.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.4, height: 2.4)),
                      with: .color(Sketch.hex(0xD8F06A, (0.25 + 0.75 * f.openness) * tw)))
        }
        // Hanging strings of light.
        for k in 0..<6 {
            let x = inner.minX + inner.width * (0.1 + 0.16 * Double(k))
            var string = Path()
            string.move(to: CGPoint(x: x, y: inner.minY))
            string.addLine(to: CGPoint(x: x + 2, y: inner.maxY))
            view.stroke(string, with: .color(.white.opacity(0.35)), lineWidth: 0.8)
            for b in stride(from: inner.minY + 12, to: inner.maxY, by: 22) {
                view.fill(Path(ellipseIn: CGRect(x: x - 2, y: b, width: 4, height: 4)), with: .color(.white.opacity(0.8)))
            }
        }

        // A soft green bush in the foreground.
        var bush = Path()
        bush.addEllipse(in: CGRect(x: -w * 0.2, y: h * 0.62, width: w * 0.62, height: h * 0.5))
        c.fill(bush, with: .color(Sketch.hex(0x26341A, 0.95)))
        Sketch.ink(&c, bush, Sketch.hex(0x52692E, 0.6), width: 1.2)
    }

    // MARK: 2 · Rain Station

    /// Three platforms of arches; the train arrives at a new one each breath while the rain deepens.
    static func rainStation(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x05050A), bottom: Sketch.hex(0x0A0A12), stars: 180, starsTo: 0.4, time: f.time)

        // Trees with painted canopies.
        for k in 0..<3 {
            let cx = w * (0.17 + 0.33 * Double(k))
            var trunk = Path()
            trunk.move(to: CGPoint(x: cx, y: h * 0.4))
            trunk.addQuadCurve(to: CGPoint(x: cx + w * 0.02, y: h * 0.16), control: CGPoint(x: cx - w * 0.05, y: h * 0.28))
            Sketch.ink(&c, trunk, Sketch.hex(0xC0391F), width: 5)
            let crown = CGRect(x: cx - w * 0.17, y: h * 0.02, width: w * 0.34, height: h * 0.19)
            c.fill(Path(ellipseIn: crown), with: .color(Sketch.hex(0x2A0E1E)))
            var rng = SeededGenerator(seed: UInt64(30 + k))
            for _ in 0..<26 {
                let p = CGPoint(x: crown.minX + Double.random(in: 0.1...0.9, using: &rng) * crown.width,
                                y: crown.minY + Double.random(in: 0.1...0.9, using: &rng) * crown.height)
                c.fill(Sketch.leaf(at: p, size: 10, angle: Double.random(in: 0...6, using: &rng)),
                       with: .color(Bool.random(using: &rng) ? Sketch.hex(0xE0973A) : Sketch.hex(0xC23A78)))
            }
        }

        let facade = [Sketch.hex(0xB08A5A), Sketch.hex(0xC0582E), Sketch.hex(0x8A6A44)]
        let tierHeight = h * 0.17
        let activeTier = f.stage % 3
        for tier in 0..<3 {
            let top = h * 0.36 + Double(tier) * tierHeight
            c.fill(Path(CGRect(x: 0, y: top, width: w, height: tierHeight)), with: .color(facade[tier]))
            Sketch.ink(&c, Path(CGRect(x: 0, y: top, width: w, height: tierHeight)), Sketch.hex(0x2A1A0A, 0.6), width: 1)
            for k in 0..<3 {
                let arch = CGRect(x: w * (0.06 + 0.31 * Double(k)), y: top + tierHeight * 0.18, width: w * 0.26, height: tierHeight * 0.76)
                c.fill(Sketch.arch(arch), with: .color(Sketch.hex(0x050505)))
                Sketch.ink(&c, Sketch.arch(arch), Sketch.hex(0x3A220E), width: 2)
                Sketch.glow(&c, at: CGPoint(x: arch.midX, y: top + tierHeight * 0.08), radius: 10, color: Sketch.hex(0xFFD27A), opacity: 0.9)
            }
            if tier == activeTier {
                // The train glides through this platform's arches.
                var train = c
                train.clip(to: Path(CGRect(x: 0, y: top + tierHeight * 0.45, width: w, height: tierHeight * 0.5)))
                let x = (f.time * 40).truncatingRemainder(dividingBy: w * 1.6) - w * 0.4
                let body = CGRect(x: x, y: top + tierHeight * 0.55, width: w * 0.9, height: tierHeight * 0.3)
                train.fill(Path(roundedRect: body, cornerRadius: 6), with: .color(Sketch.hex(0x7A5BA8)))
                for wi in 0..<6 {
                    let win = CGRect(x: body.minX + body.width * (0.06 + 0.15 * Double(wi)), y: body.minY + body.height * 0.2,
                                     width: body.width * 0.09, height: body.height * 0.45)
                    train.fill(Path(roundedRect: win, cornerRadius: 2), with: .color(Sketch.hex(0xF07A3A)))
                }
            }
        }
        // Rain grows heavier through the first three platforms, then eases.
        let heaviness = [0.25, 0.5, 0.85, 0.45, 0.15][min(f.stage, 4)]
        Sketch.rain(&c, s, density: heaviness, time: f.time, seed: 22, opacity: 0.35)
        // A puddle of reflected color.
        let pool = CGRect(x: w * 0.05, y: h * 0.88, width: w * 0.9, height: h * 0.2)
        c.fill(Path(ellipseIn: pool), with: .radialGradient(Gradient(colors: [Sketch.hex(0xC23A78, 0.5), Sketch.hex(0x1A0A14)]),
                                                           center: CGPoint(x: pool.midX, y: pool.midY), startRadius: 0, endRadius: pool.width / 2))
    }

    // MARK: 3 · Waterfall House

    /// A sepia house of arched rooms; teal water pours in and fills one more floor each breath.
    static func waterfallHouse(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.paper(&c, s, Sketch.hex(0xE8C3A0), seed: 3)
        // Brick marks.
        var rng = SeededGenerator(seed: 4)
        for _ in 0..<90 {
            let x = Double.random(in: 0...w, using: &rng), y = Double.random(in: 0...h, using: &rng)
            c.fill(Path(roundedRect: CGRect(x: x, y: y, width: 26, height: 7), cornerRadius: 3), with: .color(Sketch.hex(0xB98864, 0.35)))
        }
        let ink = Sketch.hex(0x4A3020)
        var archway = Path()
        archway.addArc(center: CGPoint(x: w / 2, y: h * 0.3), radius: w * 0.62, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        Sketch.ink(&c, archway, ink, width: 2)

        let house = CGRect(x: w * 0.14, y: h * 0.2, width: w * 0.72, height: h * 0.6)
        Sketch.ink(&c, Path(house), ink, width: 2.2)
        let rows = 3, cols = 2
        for r in 0..<rows {
            for col in 0..<cols {
                let room = CGRect(x: house.minX + house.width * (0.05 + 0.48 * Double(col)),
                                  y: house.minY + house.height * (0.04 + 0.32 * Double(r)),
                                  width: house.width * 0.42, height: house.height * 0.28)
                c.fill(Sketch.arch(room), with: .color(Sketch.hex(0xF4D9BC)))
                Sketch.ink(&c, Sketch.arch(room), ink, width: 1.4)
                // A potted plant in each room.
                let pot = CGRect(x: room.midX - 10, y: room.maxY - 18, width: 20, height: 16)
                Sketch.ink(&c, Path(roundedRect: pot, cornerRadius: 3), ink, width: 1.1)
                for leaf in 0..<4 {
                    Sketch.ink(&c, Sketch.leaf(at: CGPoint(x: pot.midX, y: pot.minY), size: 16, angle: -.pi / 2 + Double(leaf - 2) * 0.45), ink, width: 0.9)
                }
            }
        }

        // The water: in from the left, then down the middle, a floor further each breath.
        let teal = Sketch.hex(0x5FA898)
        let reach = house.minY + house.height * (0.2 + 0.8 * f.fraction)
        var stream = Path()
        stream.move(to: CGPoint(x: 0, y: house.minY + house.height * 0.24))
        stream.addQuadCurve(to: CGPoint(x: w * 0.5, y: house.minY + house.height * 0.3), control: CGPoint(x: w * 0.3, y: house.minY + house.height * 0.22))
        stream.addLine(to: CGPoint(x: w * 0.5 + 6, y: reach))
        c.stroke(stream, with: .color(teal), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round, lineJoin: .round))
        // Speckles glinting in the water.
        for i in 0..<40 {
            let t = (Double(i) / 40 + f.time * 0.08).truncatingRemainder(dividingBy: 1)
            let y = house.minY + house.height * 0.3 + t * (reach - house.minY - house.height * 0.3)
            c.fill(Path(ellipseIn: CGRect(x: w * 0.5 + Double(i % 5) * 3 - 6, y: y, width: 2, height: 2)), with: .color(.white.opacity(0.7)))
        }
        // The pool grows as the house fills.
        let pool = CGRect(x: w * (0.5 - 0.45 * f.fraction), y: house.maxY - 6, width: w * 0.9 * f.fraction, height: h * 0.1)
        c.fill(Path(ellipseIn: pool), with: .color(teal))
    }

    // MARK: 4 · The Sound of the Waterfall

    /// A sketched cliff and cabin on tan paper, the falls moving in slow scallops.
    static func cabinFalls(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.paper(&c, s, Sketch.hex(0xC48A5E), seed: 5)
        let ink = Sketch.hex(0x1E140C)
        // Cliffs.
        for side in [-1.0, 1.0] {
            var cliff = Path()
            let x0 = w / 2 + side * w * 0.12
            cliff.move(to: CGPoint(x: x0, y: h * 0.18))
            for k in 1...8 {
                cliff.addLine(to: CGPoint(x: x0 + side * Double(k) * w * 0.05, y: h * (0.18 + Double(k % 2) * 0.03 + Double(k) * 0.02)))
            }
            Sketch.ink(&c, cliff, ink, width: 1.4)
        }
        // The falls: a teal sheet with scallops sliding down.
        let falls = CGRect(x: w * 0.42, y: h * 0.17, width: w * 0.18, height: h * 0.4)
        var sheet = Path()
        sheet.move(to: CGPoint(x: falls.minX, y: falls.minY))
        sheet.addLine(to: CGPoint(x: falls.maxX, y: falls.minY))
        sheet.addLine(to: CGPoint(x: falls.maxX + w * 0.06, y: falls.maxY))
        sheet.addLine(to: CGPoint(x: falls.minX - w * 0.04, y: falls.maxY))
        sheet.closeSubpath()
        c.fill(sheet, with: .color(Sketch.hex(0x5E9C8A)))
        var water = c
        water.clip(to: sheet)
        for k in 0..<14 {
            let y = falls.minY + (Double(k) * 28 + f.time * 22).truncatingRemainder(dividingBy: falls.height + 28) - 14
            for col in 0..<4 {
                let x = falls.minX - w * 0.02 + Double(col) * falls.width * 0.33
                var scallop = Path()
                scallop.addArc(center: CGPoint(x: x, y: y), radius: 12, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                water.stroke(scallop, with: .color(Sketch.hex(0x8CC4B2, 0.7)), lineWidth: 2)
            }
        }
        Sketch.ink(&c, sheet, ink, width: 1.2)
        // Pines and the cabin.
        for (x, height) in [(0.2, 0.2), (0.27, 0.15), (0.74, 0.22), (0.8, 0.17)] {
            c.fill(Sketch.pine(base: CGPoint(x: w * x, y: h * 0.58), height: h * height), with: .color(ink.opacity(0.85)))
        }
        let cabin = CGRect(x: w * 0.25, y: h * 0.49, width: w * 0.2, height: h * 0.07)
        Sketch.ink(&c, Path(cabin), ink, width: 1.4)
        var roof = Path()
        roof.move(to: CGPoint(x: cabin.minX - 6, y: cabin.minY))
        roof.addLine(to: CGPoint(x: cabin.midX, y: cabin.minY - h * 0.04))
        roof.addLine(to: CGPoint(x: cabin.maxX + 6, y: cabin.minY))
        Sketch.ink(&c, roof, ink, width: 1.6)
        // The pool, with rings spreading from the foot of the falls.
        let pool = CGRect(x: w * 0.12, y: h * 0.56, width: w * 0.66, height: h * 0.07)
        c.fill(Path(ellipseIn: pool), with: .color(Sketch.hex(0x5E9C8A)))
        for ring in 0..<3 {
            let t = (f.time / 4 + Double(ring) / 3).truncatingRemainder(dividingBy: 1)
            let r = 10 + t * w * 0.2
            c.stroke(Path(ellipseIn: CGRect(x: w * 0.5 - r, y: pool.midY - r * 0.12, width: r * 2, height: r * 0.24)),
                     with: .color(.white.opacity(0.4 * (1 - t))), lineWidth: 1)
        }
    }

    // MARK: 5 · Moth Garden

    /// Dark leaves and garden wires; a moth settles on each wire, one breath at a time.
    static func mothGarden(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(Sketch.hex(0x040704)))
        var rng = SeededGenerator(seed: 6)
        for i in 0..<110 {
            let p = CGPoint(x: Double.random(in: -20...(w + 20), using: &rng), y: Double.random(in: 0...h, using: &rng))
            let sway = sin(f.time * 0.4 + Double(i)) * 0.08
            let leaf = Sketch.leaf(at: p, size: Double.random(in: 30...60, using: &rng), angle: Double.random(in: 0...6, using: &rng) + sway)
            c.fill(leaf, with: .color(Sketch.hex(0x163A12, Double.random(in: 0.35...0.8, using: &rng))))
            c.stroke(leaf, with: .color(Sketch.hex(0x3E7A30, 0.35)), lineWidth: 0.8)
        }
        Sketch.drift(&c, s, count: 80, time: f.time, seed: 7, color: .white.opacity(0.5), speed: 2...6, size: 0.8...1.6)

        let wires = [0.24, 0.42, 0.6, 0.78]
        for (i, y) in wires.enumerated() {
            var wire = Path()
            wire.move(to: CGPoint(x: 0, y: h * y))
            wire.addQuadCurve(to: CGPoint(x: w, y: h * y + 4), control: CGPoint(x: w / 2, y: h * y + 10))
            c.stroke(wire, with: .color(.white.opacity(0.35)), lineWidth: 1)
            guard f.progress > Double(i) else { continue }
            // Each moth lands as its breath begins and is fully there by the out-breath.
            let arrival = min(max(f.progress - Double(i), 0), 1)
            let x = w * [0.28, 0.66, 0.4, 0.72][i]
            moth(&c, at: CGPoint(x: x, y: h * y + 4), size: w * 0.12, flap: f.openness, alpha: arrival)
        }
    }

    static func moth(_ c: inout GraphicsContext, at p: CGPoint, size: Double, flap: Double, alpha: Double) {
        var m = c
        m.opacity = alpha
        m.translateBy(x: p.x, y: p.y)
        m.scaleBy(x: 0.75 + 0.25 * flap, y: 1)
        for side in [-1.0, 1.0] {
            let upper = CGRect(x: side < 0 ? -size : 0, y: -size * 0.55, width: size, height: size * 0.7)
            m.fill(Path(ellipseIn: upper), with: .color(Sketch.hex(0xE8A830)))
            let lower = CGRect(x: side < 0 ? -size * 0.75 : 0, y: -size * 0.05, width: size * 0.75, height: size * 0.55)
            m.fill(Path(ellipseIn: lower), with: .color(Sketch.hex(0xD48A22)))
            let eye = CGPoint(x: side * size * 0.38, y: size * 0.12)
            m.fill(Path(ellipseIn: CGRect(x: eye.x - size * 0.1, y: eye.y - size * 0.1, width: size * 0.2, height: size * 0.2)),
                   with: .color(Sketch.hex(0x3A2A1A)))
            m.fill(Path(ellipseIn: CGRect(x: eye.x - size * 0.05, y: eye.y - size * 0.05, width: size * 0.1, height: size * 0.1)),
                   with: .color(Sketch.hex(0x8A8A8A)))
        }
        m.fill(Path(ellipseIn: CGRect(x: -size * 0.1, y: -size * 0.45, width: size * 0.2, height: size * 0.75)), with: .color(Sketch.hex(0xC07A28)))
    }
}
