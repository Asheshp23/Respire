//
//  PlaceArtDaylight.swift
//  Respire
//
//  Bright, daytime Places: a kite hill and a rainbow pond for children, a rooftop
//  sunrise and a forest trail for teens, a morning dock and an alpine lake for adults,
//  and a garden bench and a seaside promenade for the Wise.
//

import SwiftUI

extension PlaceArt {
    // MARK: Kite Hill

    /// A grassy hill under a blue sky; a kite climbs into the wind each breath, bobbing
    /// higher as you breathe in.
    static func kiteHill(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        daySky(&c, s, top: 0x6FB8EC, bottom: 0xD4EEFF)
        Sketch.glow(&c, at: CGPoint(x: w * 0.82, y: h * 0.12), radius: w * 0.32, color: Sketch.hex(0xFFF6D0), opacity: 0.9)
        for k in 0..<4 {
            let x = (Double(k) * w * 0.38 + f.time * 4).truncatingRemainder(dividingBy: w * 1.4) - w * 0.2
            puff(&c, center: CGPoint(x: x, y: h * (0.1 + 0.08 * Double(k % 3))), width: w * 0.3, opacity: 0.85)
        }
        hill(&c, s, y: h * 0.7, amplitude: h * 0.03, period: w * 0.5, phase: 1, color: Sketch.hex(0xA9DB8C))
        hill(&c, s, y: h * 0.8, amplitude: h * 0.04, period: w * 0.9, phase: 0, color: Sketch.hex(0x7CC25A))
        meadowFlowers(&c, s, from: h * 0.84, seed: 41)

        // A small flyer on the hilltop, holding every string.
        let hand = CGPoint(x: w * 0.5, y: h * 0.765)
        c.fill(Path(ellipseIn: CGRect(x: hand.x - 6, y: hand.y - 24, width: 12, height: 12)), with: .color(Sketch.hex(0x5A3A2A)))
        c.fill(Path(roundedRect: CGRect(x: hand.x - 7, y: hand.y - 12, width: 14, height: 20), cornerRadius: 5),
               with: .color(Sketch.hex(0xE8574A)))

        let colors: [UInt32] = [0xE8574A, 0xF2B33D, 0x4AA0D8, 0x7AC74F, 0xB06AC8]
        let size = w * 0.075
        for k in 0..<5 {
            let rise = ease(f.progress - Double(k))
            guard rise > 0 else { continue }
            let target = CGPoint(x: w * (0.14 + 0.18 * Double(k)), y: h * (0.2 + 0.06 * Double((k * 3) % 5)))
            let lift = (f.openness - 0.5) * 16 + sin(f.time * 0.9 + Double(k)) * 4
            let kite = CGPoint(x: hand.x + (target.x - hand.x) * rise,
                               y: hand.y + (target.y - hand.y) * rise - lift * rise)
            var string = Path()
            string.move(to: hand)
            string.addQuadCurve(to: kite, control: CGPoint(x: (hand.x + kite.x) / 2, y: max(hand.y, kite.y) - h * 0.02))
            c.stroke(string, with: .color(.white.opacity(0.7)), lineWidth: 0.8)

            var tail = Path()
            tail.move(to: CGPoint(x: kite.x, y: kite.y + size * 0.6))
            for step in 1...8 {
                let t = Double(step)
                tail.addLine(to: CGPoint(x: kite.x + sin(t * 1.3 + f.time * 3 + Double(k)) * 6 - t * 2,
                                         y: kite.y + size * 0.6 + t * size * 0.16))
            }
            c.stroke(tail, with: .color(Sketch.hex(colors[k]).opacity(0.8)), lineWidth: 1.4)

            var diamond = Path()
            diamond.move(to: CGPoint(x: kite.x, y: kite.y - size * 0.6))
            diamond.addLine(to: CGPoint(x: kite.x + size * 0.4, y: kite.y))
            diamond.addLine(to: CGPoint(x: kite.x, y: kite.y + size * 0.6))
            diamond.addLine(to: CGPoint(x: kite.x - size * 0.4, y: kite.y))
            diamond.closeSubpath()
            c.fill(diamond, with: .color(Sketch.hex(colors[k]).opacity(rise)))
            var spars = Path()
            spars.move(to: CGPoint(x: kite.x, y: kite.y - size * 0.6)); spars.addLine(to: CGPoint(x: kite.x, y: kite.y + size * 0.6))
            spars.move(to: CGPoint(x: kite.x - size * 0.4, y: kite.y)); spars.addLine(to: CGPoint(x: kite.x + size * 0.4, y: kite.y))
            c.stroke(spars, with: .color(.white.opacity(0.6 * rise)), lineWidth: 0.8)
        }
    }

    // MARK: Rainbow Pond

    /// A pond just after rain; the rainbow fills in one color each breath, mirrored in the water.
    static func rainbowPond(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        daySky(&c, s, top: 0x86C6EE, bottom: 0xEEF8FF)
        puff(&c, center: CGPoint(x: w * 0.2, y: h * 0.14), width: w * 0.34, opacity: 0.9)
        puff(&c, center: CGPoint(x: w * 0.82, y: h * 0.22), width: w * 0.3, opacity: 0.8)

        let center = CGPoint(x: w * 0.5, y: h * 0.6)
        rainbow(&c, center: center, radius: w * 0.62, band: w * 0.034, progress: f.progress, flipped: false, opacity: 0.6)

        // Trees on the far bank, then the grass.
        var rng = SeededGenerator(seed: 52)
        for k in 0..<14 {
            let x = Double(k) / 13 * w
            let r = w * Double.random(in: 0.05...0.08, using: &rng)
            c.fill(Path(ellipseIn: CGRect(x: x - r, y: h * 0.58 - r * 1.2, width: r * 2, height: r * 1.8)),
                   with: .color(Sketch.hex(0x6FAF5A)))
        }
        c.fill(Path(CGRect(x: 0, y: h * 0.58, width: w, height: h * 0.42)), with: .color(Sketch.hex(0x9BD67A)))

        // The pond, with the rainbow's reflection.
        let pond = Path(ellipseIn: CGRect(x: w * 0.04, y: h * 0.64, width: w * 0.92, height: h * 0.24))
        c.fill(pond, with: .linearGradient(Gradient(colors: [Sketch.hex(0x8CCBEE), Sketch.hex(0x5FA8D6)]),
                                           startPoint: CGPoint(x: 0, y: h * 0.64), endPoint: CGPoint(x: 0, y: h * 0.88)))
        c.drawLayer { layer in
            layer.clip(to: pond)
            rainbow(&layer, center: CGPoint(x: center.x, y: h * 0.64), radius: w * 0.62, band: w * 0.034,
                    progress: f.progress, flipped: true, opacity: 0.25)
            for k in 0..<3 {
                let grow = (f.time * 0.25 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                let ring = CGRect(x: w * 0.62 - grow * w * 0.12, y: h * 0.76 - grow * h * 0.02,
                                  width: grow * w * 0.24, height: grow * h * 0.04)
                layer.stroke(Path(ellipseIn: ring), with: .color(.white.opacity(0.5 * (1 - grow))), lineWidth: 1)
            }
        }
        // Lily pads riding the breath.
        let bob = (f.openness - 0.5) * 3
        for (x, y, r) in [(0.24, 0.74, 0.05), (0.36, 0.82, 0.04), (0.74, 0.71, 0.045), (0.8, 0.8, 0.035)] {
            var pad = Path()
            let p = CGPoint(x: w * x, y: h * y + bob)
            pad.addArc(center: p, radius: w * r, startAngle: .degrees(20), endAngle: .degrees(340), clockwise: false)
            pad.addLine(to: p); pad.closeSubpath()
            // Squashed about its own center, so it lies flat on the water.
            let flat = CGAffineTransform(translationX: 0, y: -p.y)
                .concatenating(CGAffineTransform(scaleX: 1, y: 0.45))
                .concatenating(CGAffineTransform(translationX: 0, y: p.y))
            c.fill(pad.applying(flat), with: .color(Sketch.hex(0x4E9A48)))
        }
        c.fill(Path(ellipseIn: CGRect(x: w * 0.735, y: h * 0.698 + bob, width: 9, height: 9)), with: .color(Sketch.hex(0xF4A6C0)))
        meadowFlowers(&c, s, from: h * 0.9, seed: 53)
    }

    // MARK: Rooftop Sunrise

    /// A city rooftop at dawn; the sun climbs and the windows go out as the city wakes.
    static func rooftopSunrise(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        let day = f.fraction
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.mix(Sketch.hex(0x3A4A80), Sketch.hex(0x7FB6E8), day),
                              Sketch.mix(Sketch.hex(0xE89A88), Sketch.hex(0xFFE2B0), day)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.72)))
        // Just clear of the tallest rooftops from the start, climbing as the city wakes.
        let sun = CGPoint(x: w * 0.62, y: h * (0.34 - 0.18 * day))
        Sketch.glow(&c, at: sun, radius: w * 0.5, color: Sketch.hex(0xFFD08A), opacity: 0.7)
        c.fill(Path(ellipseIn: CGRect(x: sun.x - w * 0.07, y: sun.y - w * 0.07, width: w * 0.14, height: w * 0.14)),
               with: .color(Sketch.hex(0xFFF2D0)))

        // The skyline: windows lit at dawn, going out one by one.
        var rng = SeededGenerator(seed: 61)
        let base = h * 0.72
        var x = -w * 0.05
        while x < w {
            let width = w * Double.random(in: 0.09...0.16, using: &rng)
            let height = h * Double.random(in: 0.1...0.3, using: &rng)
            let block = CGRect(x: x, y: base - height, width: width, height: height)
            c.fill(Path(block), with: .color(Sketch.mix(Sketch.hex(0x2C2F4A), Sketch.hex(0x8A90A8), day)))
            for wy in stride(from: block.minY + 8, to: block.maxY - 6, by: 12) {
                for wx in stride(from: block.minX + 5, to: block.maxX - 6, by: 9) {
                    let wakes = Double.random(in: 0...1, using: &rng)
                    guard wakes > day else { continue }
                    c.fill(Path(CGRect(x: wx, y: wy, width: 4, height: 6)),
                           with: .color(Sketch.hex(0xFFD58A).opacity(0.85 * min((wakes - day) * 4, 1))))
                }
            }
            x += width + w * 0.01
        }
        // Birds out once it's light.
        if day > 0.4 {
            for k in 0..<4 {
                let bx = (w * 0.2 + Double(k) * 26 + f.time * 12).truncatingRemainder(dividingBy: w * 1.2) - w * 0.1
                let by = h * (0.2 + 0.03 * Double(k % 2)) + sin(f.time + Double(k)) * 3
                var bird = Path()
                bird.move(to: CGPoint(x: bx - 5, y: by - 2)); bird.addQuadCurve(to: CGPoint(x: bx, y: by), control: CGPoint(x: bx - 2, y: by - 4))
                bird.addQuadCurve(to: CGPoint(x: bx + 5, y: by - 2), control: CGPoint(x: bx + 2, y: by - 4))
                c.stroke(bird, with: .color(Sketch.hex(0x3A3A50).opacity(min((day - 0.4) * 4, 1))), lineWidth: 1.2)
            }
        }
        // Your rooftop: the parapet, a water tower, and a plant.
        let roof = Sketch.mix(Sketch.hex(0x3A2E36), Sketch.hex(0x8A6E64), day)
        c.fill(Path(CGRect(x: 0, y: h * 0.8, width: w, height: h * 0.2)), with: .color(roof))
        c.fill(Path(CGRect(x: 0, y: h * 0.78, width: w, height: h * 0.025)), with: .color(Sketch.mix(roof, .white, 0.15)))
        let tower = CGRect(x: w * 0.08, y: h * 0.62, width: w * 0.16, height: h * 0.1)
        c.fill(Path(roundedRect: tower, cornerRadius: 3), with: .color(Sketch.mix(roof, .black, 0.2)))
        var cone = Path()
        cone.move(to: CGPoint(x: tower.minX - 4, y: tower.minY)); cone.addLine(to: CGPoint(x: tower.midX, y: tower.minY - h * 0.03))
        cone.addLine(to: CGPoint(x: tower.maxX + 4, y: tower.minY)); cone.closeSubpath()
        c.fill(cone, with: .color(Sketch.mix(roof, .black, 0.3)))
        for leg in [tower.minX + 4, tower.maxX - 6] {
            c.fill(Path(CGRect(x: leg, y: tower.maxY, width: 2, height: h * 0.06)), with: .color(Sketch.mix(roof, .black, 0.3)))
        }
        let pot = CGRect(x: w * 0.78, y: h * 0.75, width: w * 0.08, height: h * 0.035)
        c.fill(Path(roundedRect: pot, cornerRadius: 2), with: .color(Sketch.hex(0xB8684A)))
        for k in 0..<5 {
            c.fill(Sketch.leaf(at: CGPoint(x: pot.midX, y: pot.minY), size: w * 0.06,
                               angle: -.pi / 2 + Double(k - 2) * 0.4 + sin(f.time * 0.8) * 0.04),
                   with: .color(Sketch.mix(Sketch.hex(0x2E5A3A), Sketch.hex(0x5E9E58), day)))
        }
    }

    // MARK: Forest Trail

    /// A sunlit pine trail; the trees part a little each breath until the far view opens.
    static func forestTrail(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        daySky(&c, s, top: 0xBFE0F0, bottom: 0xF6F0D6)
        // The view at the end: blue ridges.
        hill(&c, s, y: h * 0.5, amplitude: h * 0.05, period: w * 0.7, phase: 2, color: Sketch.hex(0xA8C4D8))
        hill(&c, s, y: h * 0.56, amplitude: h * 0.03, period: w * 0.5, phase: 0.5, color: Sketch.hex(0x8EB4B8))
        c.fill(Path(CGRect(x: 0, y: h * 0.6, width: w, height: h * 0.4)), with: .color(Sketch.hex(0x9CC47E)))

        // The trail, winding toward the view.
        var trail = Path()
        trail.move(to: CGPoint(x: w * 0.28, y: h))
        trail.addCurve(to: CGPoint(x: w * 0.49, y: h * 0.6), control1: CGPoint(x: w * 0.4, y: h * 0.8), control2: CGPoint(x: w * 0.6, y: h * 0.7))
        trail.addLine(to: CGPoint(x: w * 0.51, y: h * 0.6))
        trail.addCurve(to: CGPoint(x: w * 0.78, y: h), control1: CGPoint(x: w * 0.66, y: h * 0.7), control2: CGPoint(x: w * 0.56, y: h * 0.8))
        trail.closeSubpath()
        c.fill(trail, with: .color(Sketch.hex(0xDCC89E)))

        // Sun dapples on the path, shifting with the breeze.
        for k in 0..<7 {
            let t = Double(k) / 6
            let p = CGPoint(x: w * (0.5 + 0.12 * sin(t * 3 + 1)) + sin(f.time * 0.6 + Double(k)) * 3, y: h * (0.66 + 0.3 * t))
            let r = 6 + t * 16
            c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r * 0.3, width: r * 2, height: r * 0.6)),
                   with: .color(Sketch.hex(0xFFF4C8).opacity(0.5)))
        }

        // Pines in four depths, nearer ones darker; they part as you walk on.
        let part = f.fraction * w * 0.22
        var rng = SeededGenerator(seed: 71)
        for depth in 0..<4 {
            let d = Double(depth)
            let color = Sketch.mix(Sketch.hex(0xA9C8A4), Sketch.hex(0x2F5A3A), d / 3)
            let baseY = h * (0.6 + 0.09 * d)
            let height = h * (0.16 + 0.1 * d)
            for _ in 0..<(7 - depth) {
                let side = Bool.random(using: &rng) ? 1.0 : -1.0
                let offset = Double.random(in: 0.08...0.5, using: &rng) * w
                let x = w * 0.5 + side * (offset + part * (0.4 + d * 0.3))
                c.fill(Sketch.pine(base: CGPoint(x: x, y: baseY), height: height * Double.random(in: 0.85...1.15, using: &rng)),
                       with: .color(color))
            }
        }
    }

    // MARK: Morning Dock

    /// A wooden dock on a lake at morning; the mist lifts as you breathe.
    static func morningDock(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        daySky(&c, s, top: 0xBFD9EE, bottom: 0xFAEAD2)
        let sun = CGPoint(x: w * 0.32, y: h * 0.36)
        Sketch.glow(&c, at: sun, radius: w * 0.42, color: Sketch.hex(0xFFE8B8), opacity: 0.9)
        hill(&c, s, y: h * 0.44, amplitude: h * 0.03, period: w * 0.8, phase: 1.5, color: Sketch.hex(0xA8BCCB))
        hill(&c, s, y: h * 0.49, amplitude: h * 0.012, period: w * 0.2, phase: 0, color: Sketch.hex(0x7F9E8E))

        // The lake, and the sun's path across it.
        c.fill(Path(CGRect(x: 0, y: h * 0.5, width: w, height: h * 0.5)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0xD6E4EC), Sketch.hex(0x8FB4CC)]),
            startPoint: CGPoint(x: 0, y: h * 0.5), endPoint: CGPoint(x: 0, y: h)))
        for k in 0..<14 {
            let y = h * (0.52 + 0.025 * Double(k))
            let half = w * (0.02 + 0.006 * Double(k)) * (0.8 + 0.2 * sin(f.time * 1.5 + Double(k)))
            c.fill(Path(CGRect(x: sun.x - half, y: y, width: half * 2, height: 1.5)), with: .color(.white.opacity(0.6)))
        }
        // Morning mist, lifting.
        let mist = 1 - f.fraction
        for k in 0..<4 {
            let y = h * (0.42 + 0.04 * Double(k)) - f.fraction * h * 0.05
            let x = sin(f.time * 0.1 + Double(k)) * w * 0.1
            c.fill(Path(ellipseIn: CGRect(x: x - w * 0.2, y: y, width: w * 1.4, height: h * 0.05)),
                   with: .color(.white.opacity(0.45 * mist)))
        }
        // The dock, in perspective, with ripples round its posts.
        var deck = Path()
        deck.move(to: CGPoint(x: w * 0.44, y: h * 0.66)); deck.addLine(to: CGPoint(x: w * 0.56, y: h * 0.66))
        deck.addLine(to: CGPoint(x: w * 0.82, y: h)); deck.addLine(to: CGPoint(x: w * 0.18, y: h)); deck.closeSubpath()
        c.fill(deck, with: .color(Sketch.hex(0xB08A60)))
        for k in 1..<12 {
            let t = pow(Double(k) / 12, 1.6)
            let y = h * 0.66 + t * h * 0.34
            let half = w * (0.06 + 0.26 * t)
            var plank = Path()
            plank.move(to: CGPoint(x: w * 0.5 - half, y: y)); plank.addLine(to: CGPoint(x: w * 0.5 + half, y: y))
            c.stroke(plank, with: .color(Sketch.hex(0x7A5A3A).opacity(0.6)), lineWidth: 0.8 + t)
        }
        let ripple = 1 - f.openness
        for x in [w * 0.43, w * 0.57] {
            c.fill(Path(CGRect(x: x - 2, y: h * 0.64, width: 4, height: h * 0.04)), with: .color(Sketch.hex(0x6A4A30)))
            c.stroke(Path(ellipseIn: CGRect(x: x - 8 - ripple * 6, y: h * 0.675, width: 16 + ripple * 12, height: 4)),
                     with: .color(.white.opacity(0.5)), lineWidth: 0.8)
        }
    }

    // MARK: Alpine Lake

    /// Snow peaks mirrored in a still mountain lake, a meadow at your feet.
    static func alpineLake(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        let shore = h * 0.54
        daySky(&c, s, top: 0x78B6E6, bottom: 0xE2F2FB)
        puff(&c, center: CGPoint(x: w * 0.25 + f.time * 2, y: h * 0.12), width: w * 0.3, opacity: 0.85)
        mountains(&c, s, shore: shore)
        c.fill(Path(CGRect(x: 0, y: shore - h * 0.012, width: w, height: h * 0.02)), with: .color(Sketch.hex(0x8CC46E)))
        for k in 0..<16 {
            let x = Double(k) / 15 * w + sin(Double(k) * 3) * 8
            c.fill(Sketch.pine(base: CGPoint(x: x, y: shore + 2), height: h * (0.04 + 0.015 * Double(k % 3))),
                   with: .color(Sketch.hex(0x3E6A50)))
        }

        // The lake mirrors everything above it; a breath out sends a faint shiver across.
        let lake = Path(CGRect(x: 0, y: shore + 2, width: w, height: h * 0.32))
        c.fill(lake, with: .color(Sketch.hex(0x6FA8CC)))
        c.drawLayer { layer in
            layer.clip(to: lake)
            layer.opacity = 0.5
            layer.translateBy(x: 0, y: shore * 2 + 4)
            layer.scaleBy(x: 1, y: -1)
            mountains(&layer, s, shore: shore)
        }
        let shiver = 1 - f.openness
        for k in 0..<10 {
            let y = shore + h * (0.03 + 0.028 * Double(k))
            let x = (Double(k * 37 % 100) / 100) * w
            c.fill(Path(CGRect(x: x - 20 - shiver * 10, y: y, width: 40 + shiver * 20, height: 1)), with: .color(.white.opacity(0.35)))
        }
        // The meadow at your feet.
        hill(&c, s, y: h * 0.86, amplitude: h * 0.015, period: w * 0.6, phase: 0, color: Sketch.hex(0x86C066))
        meadowFlowers(&c, s, from: h * 0.88, seed: 81)
    }

    // MARK: Garden Bench

    /// A sunny cottage garden; a bird comes to visit with every breath.
    static func gardenBench(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        daySky(&c, s, top: 0xB8DDF4, bottom: 0xF4F8EA)
        Sketch.glow(&c, at: CGPoint(x: w * 0.8, y: h * 0.1), radius: w * 0.35, color: Sketch.hex(0xFFF4CC), opacity: 0.9)
        // The hedge, its flowers, and the lawn.
        for k in 0..<9 {
            let r = w * 0.11
            c.fill(Path(ellipseIn: CGRect(x: Double(k) / 8 * w - r, y: h * 0.48, width: r * 2, height: r * 1.6)),
                   with: .color(Sketch.hex(k % 2 == 0 ? 0x6E9E58 : 0x78A862)))
        }
        c.fill(Path(CGRect(x: 0, y: h * 0.58, width: w, height: h * 0.42)), with: .color(Sketch.hex(0xA6D27E)))
        var rng = SeededGenerator(seed: 91)
        let blooms: [UInt32] = [0xF4A6C0, 0xFFFFFF, 0xF6D06A, 0xC8A2E8, 0xF08A6A]
        for _ in 0..<40 {
            let p = CGPoint(x: Double.random(in: 0...w, using: &rng), y: h * Double.random(in: 0.5...0.6, using: &rng))
            c.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 6, height: 6)),
                   with: .color(Sketch.hex(blooms.randomElement(using: &rng) ?? 0xFFFFFF)))
        }
        // A branch over the top corner.
        var branch = Path()
        branch.move(to: CGPoint(x: -10, y: h * 0.06)); branch.addQuadCurve(to: CGPoint(x: w * 0.45, y: h * 0.1), control: CGPoint(x: w * 0.2, y: h * 0.14))
        c.stroke(branch, with: .color(Sketch.hex(0x6A4A34)), lineWidth: 4)
        for k in 0..<12 {
            let t = Double(k) / 11
            let p = CGPoint(x: -10 + t * (w * 0.45 + 10), y: h * (0.06 + 0.06 * sin(t * .pi)))
            c.fill(Sketch.leaf(at: p, size: w * 0.05, angle: (k % 2 == 0 ? 0.6 : 2.4) + sin(f.time * 0.7 + t * 4) * 0.08),
                   with: .color(Sketch.hex(k % 3 == 0 ? 0x5E9448 : 0x78B05A)))
        }
        // The bench.
        let wood = Sketch.hex(0x9A6A44)
        for k in 0..<3 {
            c.fill(Path(roundedRect: CGRect(x: w * 0.18, y: h * (0.62 + 0.025 * Double(k)), width: w * 0.5, height: h * 0.014), cornerRadius: 2),
                   with: .color(wood))
        }
        c.fill(Path(roundedRect: CGRect(x: w * 0.16, y: h * 0.71, width: w * 0.54, height: h * 0.018), cornerRadius: 2), with: .color(wood))
        for x in [w * 0.2, w * 0.64] {
            c.fill(Path(CGRect(x: x, y: h * 0.6, width: 5, height: h * 0.18)), with: .color(Sketch.hex(0x6A4A30)))
        }
        // The feeder.
        c.fill(Path(CGRect(x: w * 0.83, y: h * 0.5, width: 4, height: h * 0.3)), with: .color(Sketch.hex(0x6A4A30)))
        c.fill(Path(roundedRect: CGRect(x: w * 0.78, y: h * 0.47, width: w * 0.11, height: h * 0.035), cornerRadius: 3),
               with: .color(Sketch.hex(0xC88A5A)))

        // Birds flying in to their places: feeder, bench back, lawn.
        let perches = [CGPoint(x: 0.8, y: 0.465), CGPoint(x: 0.88, y: 0.465), CGPoint(x: 0.3, y: 0.615),
                       CGPoint(x: 0.55, y: 0.615), CGPoint(x: 0.42, y: 0.84)]
        let plumage: [(UInt32, UInt32)] = [(0x8A5A3A, 0xF08A4A), (0x4A78C8, 0xF6E06A), (0x6A6A5A, 0xE8D8B8),
                                           (0xC83A3A, 0xE86A5A), (0x5A4A3A, 0xD8B890)]
        for k in 0..<5 {
            let arrive = ease(f.progress - Double(k))
            guard arrive > 0 else { continue }
            let perch = CGPoint(x: w * perches[k].x, y: h * perches[k].y)
            let from = CGPoint(x: w * 1.1, y: h * 0.15)
            let hop = arrive >= 1 ? abs(sin(f.time * 2 + Double(k) * 1.7)) * 2 : sin(arrive * .pi) * h * 0.06
            let p = CGPoint(x: from.x + (perch.x - from.x) * arrive, y: from.y + (perch.y - from.y) * arrive - hop)
            bird(&c, at: p, size: w * 0.035, body: plumage[k].0, breast: plumage[k].1, facesLeft: k % 2 == 0)
        }
    }

    // MARK: Seaside Promenade

    /// A bright promenade by a blue sea; a sailboat drifts into view with every breath.
    static func seasidePromenade(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        daySky(&c, s, top: 0x86C4EE, bottom: 0xE8F5FC)
        Sketch.glow(&c, at: CGPoint(x: w * 0.72, y: h * 0.12), radius: w * 0.3, color: .white, opacity: 0.9)
        puff(&c, center: CGPoint(x: w * 0.25, y: h * 0.2), width: w * 0.3, opacity: 0.8)
        for k in 0..<3 {
            let gx = (w * 0.3 + Double(k) * 40 + f.time * 8).truncatingRemainder(dividingBy: w * 1.2) - w * 0.1
            let gy = h * (0.28 + 0.02 * Double(k)) + sin(f.time * 0.7 + Double(k)) * 4
            var gull = Path()
            gull.move(to: CGPoint(x: gx - 7, y: gy - 2)); gull.addQuadCurve(to: CGPoint(x: gx, y: gy), control: CGPoint(x: gx - 3, y: gy - 5))
            gull.addQuadCurve(to: CGPoint(x: gx + 7, y: gy - 2), control: CGPoint(x: gx + 3, y: gy - 5))
            c.stroke(gull, with: .color(Sketch.hex(0x4A5A6A)), lineWidth: 1.3)
        }
        // The sea, glittering.
        let horizon = h * 0.48
        c.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h * 0.3)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x3F8FC4), Sketch.hex(0x7CC6E4)]),
            startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h * 0.78)))
        var rng = SeededGenerator(seed: 101)
        for _ in 0..<50 {
            let p = CGPoint(x: Double.random(in: 0...w, using: &rng), y: horizon + Double.random(in: 0...(h * 0.28), using: &rng))
            let glint = max(0, sin(f.time * 2 + Double.random(in: 0...6, using: &rng)))
            c.fill(Path(CGRect(x: p.x, y: p.y, width: 6, height: 1.2)), with: .color(.white.opacity(0.7 * glint)))
        }
        // Sailboats, one more each breath, drifting slowly.
        let stripes: [UInt32] = [0xE8574A, 0x4A78C8, 0xF2B33D, 0x3A9A7A, 0xB06AC8]
        for k in 0..<5 {
            let seen = ease(f.progress - Double(k))
            guard seen > 0 else { continue }
            let far = Double(k % 3)
            let size = w * (0.09 - 0.018 * far)
            let x = (w * (0.12 + 0.19 * Double(k)) + f.time * (2 + far)).truncatingRemainder(dividingBy: w * 1.1)
            let y = horizon + h * (0.03 + 0.05 * (2 - far)) + (f.openness - 0.5) * 2
            var hull = Path()
            hull.move(to: CGPoint(x: x - size * 0.5, y: y)); hull.addLine(to: CGPoint(x: x + size * 0.5, y: y))
            hull.addLine(to: CGPoint(x: x + size * 0.36, y: y + size * 0.16)); hull.addLine(to: CGPoint(x: x - size * 0.36, y: y + size * 0.16))
            hull.closeSubpath()
            c.fill(hull, with: .color(Sketch.hex(0x2F3F5A).opacity(seen)))
            var sail = Path()
            sail.move(to: CGPoint(x: x, y: y - size * 1.1)); sail.addLine(to: CGPoint(x: x + size * 0.42, y: y - size * 0.06))
            sail.addLine(to: CGPoint(x: x, y: y - size * 0.06)); sail.closeSubpath()
            c.fill(sail, with: .color(.white.opacity(seen)))
            var jib = Path()
            jib.move(to: CGPoint(x: x - size * 0.04, y: y - size * 0.95)); jib.addLine(to: CGPoint(x: x - size * 0.04, y: y - size * 0.06))
            jib.addLine(to: CGPoint(x: x - size * 0.36, y: y - size * 0.06)); jib.closeSubpath()
            c.fill(jib, with: .color(Sketch.hex(stripes[k]).opacity(seen)))
        }
        // The promenade: pale stone, a white rail, and two lamps.
        c.fill(Path(CGRect(x: 0, y: h * 0.78, width: w, height: h * 0.22)), with: .color(Sketch.hex(0xE8D9BF)))
        for k in 0..<6 {
            c.fill(Path(CGRect(x: 0, y: h * (0.82 + 0.035 * Double(k)), width: w, height: 1)), with: .color(Sketch.hex(0xCDBB9C)))
        }
        let rail = Sketch.hex(0xF6F3EC)
        c.fill(Path(CGRect(x: 0, y: h * 0.7, width: w, height: 5)), with: .color(rail))
        c.fill(Path(CGRect(x: 0, y: h * 0.76, width: w, height: 4)), with: .color(rail))
        for x in stride(from: 6.0, to: w, by: 16) {
            c.fill(Path(roundedRect: CGRect(x: x, y: h * 0.7, width: 4, height: h * 0.08), cornerRadius: 2), with: .color(rail))
        }
        for x in [w * 0.12, w * 0.88] {
            c.fill(Path(CGRect(x: x - 2.5, y: h * 0.56, width: 5, height: h * 0.24)), with: .color(Sketch.hex(0x2F5A50)))
            c.fill(Path(ellipseIn: CGRect(x: x - 11, y: h * 0.56 - 20, width: 22, height: 22)), with: .color(Sketch.hex(0xFFF8E6)))
            c.stroke(Path(ellipseIn: CGRect(x: x - 11, y: h * 0.56 - 20, width: 22, height: 22)), with: .color(Sketch.hex(0x2F5A50)), lineWidth: 2)
        }
    }

    // MARK: - Daylight helpers

    /// 0 before a step begins, easing to 1 as it completes.
    private static func ease(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return 1 - pow(1 - x, 3)
    }

    private static func daySky(_ c: inout GraphicsContext, _ s: CGSize, top: UInt32, bottom: UInt32) {
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(top), Sketch.hex(bottom)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: s.height * 0.7)))
    }

    /// A soft fair-weather cloud.
    private static func puff(_ c: inout GraphicsContext, center: CGPoint, width: Double, opacity: Double) {
        for (dx, dy, r) in [(-0.3, 0.05, 0.22), (-0.08, -0.08, 0.3), (0.18, -0.02, 0.26), (0.36, 0.06, 0.18)] {
            let radius = width * r
            c.fill(Path(ellipseIn: CGRect(x: center.x + width * dx - radius, y: center.y + width * dy - radius * 0.7,
                                          width: radius * 2, height: radius * 1.4)),
                   with: .color(.white.opacity(opacity)))
        }
    }

    /// A rolling hill from `y` to the bottom, reaching both edges.
    private static func hill(_ c: inout GraphicsContext, _ s: CGSize, y: Double, amplitude: Double, period: Double,
                             phase: Double, color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: s.height))
        for x in stride(from: 0.0, to: s.width, by: 8) {
            p.addLine(to: CGPoint(x: x, y: y - sin(x / period * 2 * .pi + phase) * amplitude))
        }
        p.addLine(to: CGPoint(x: s.width, y: y - sin(s.width / period * 2 * .pi + phase) * amplitude))
        p.addLine(to: CGPoint(x: s.width, y: s.height))
        p.closeSubpath()
        c.fill(p, with: .color(color))
    }

    /// Tiny flowers scattered through grass below `from`.
    private static func meadowFlowers(_ c: inout GraphicsContext, _ s: CGSize, from y: Double, seed: UInt64) {
        var rng = SeededGenerator(seed: seed)
        let colors: [UInt32] = [0xFFFFFF, 0xF6D06A, 0xF4A6C0, 0xC8A2E8]
        for _ in 0..<45 {
            let p = CGPoint(x: Double.random(in: 0...s.width, using: &rng), y: Double.random(in: y...s.height, using: &rng))
            let r = 2 + (p.y - y) / max(s.height - y, 1) * 3
            c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                   with: .color(Sketch.hex(colors.randomElement(using: &rng) ?? 0xFFFFFF)))
        }
    }

    /// Seven bands, each sweeping in over its breath.
    private static func rainbow(_ c: inout GraphicsContext, center: CGPoint, radius: Double, band: Double,
                                progress: Double, flipped: Bool, opacity: Double) {
        let colors: [UInt32] = [0xE8574A, 0xF29A3D, 0xF6D04A, 0x7AC74F, 0x4AA0D8, 0x5A6AC8, 0x9A6AC8]
        for k in 0..<7 {
            let amount = min(max(progress - Double(k), 0), 1)
            guard amount > 0 else { continue }
            // Left to right over the top, or under it for the reflection.
            let r = radius - Double(k) * band
            var arc = Path()
            for i in 0...48 {
                let angle = Double.pi + (flipped ? -1 : 1) * Double.pi * amount * Double(i) / 48
                let point = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                if i == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
            }
            c.stroke(arc, with: .color(Sketch.hex(colors[k]).opacity(opacity)), lineWidth: band)
        }
    }

    private static func mountains(_ c: inout GraphicsContext, _ s: CGSize, shore: Double) {
        let w = s.width, h = s.height
        let ranges: [(peaks: [(Double, Double)], rock: UInt32)] = [
            ([(0, 0.4), (0.22, 0.2), (0.4, 0.34), (0.62, 0.16), (0.84, 0.3), (1, 0.24)], 0x8A9EB8),
            ([(0, 0.46), (0.15, 0.36), (0.32, 0.44), (0.5, 0.3), (0.72, 0.42), (0.9, 0.34), (1, 0.4)], 0x6A84A0),
        ]
        for range in ranges {
            var ridge = Path()
            ridge.move(to: CGPoint(x: 0, y: shore))
            for (x, y) in range.peaks { ridge.addLine(to: CGPoint(x: w * x, y: h * y)) }
            ridge.addLine(to: CGPoint(x: w, y: shore))
            ridge.closeSubpath()
            c.fill(ridge, with: .color(Sketch.hex(range.rock)))
            // Snow on every peak: a small cap below each summit.
            for (i, (x, y)) in range.peaks.enumerated() where i > 0 && i < range.peaks.count - 1 {
                let left = range.peaks[i - 1], right = range.peaks[i + 1]
                guard y < left.1, y < right.1 else { continue }
                let depth = 0.05
                var cap = Path()
                cap.move(to: CGPoint(x: w * x, y: h * y))
                cap.addLine(to: CGPoint(x: w * (x + (right.0 - x) * depth / (right.1 - y)), y: h * (y + depth)))
                cap.addLine(to: CGPoint(x: w * x, y: h * (y + depth * 0.7)))
                cap.addLine(to: CGPoint(x: w * (x - (x - left.0) * depth / (left.1 - y)), y: h * (y + depth)))
                cap.closeSubpath()
                c.fill(cap, with: .color(.white.opacity(0.95)))
            }
        }
    }

    private static func bird(_ c: inout GraphicsContext, at p: CGPoint, size: Double, body: UInt32, breast: UInt32, facesLeft: Bool) {
        let dir = facesLeft ? -1.0 : 1.0
        var tail = Path()
        tail.move(to: CGPoint(x: p.x - dir * size * 0.5, y: p.y))
        tail.addLine(to: CGPoint(x: p.x - dir * size * 1.1, y: p.y - size * 0.25))
        tail.addLine(to: CGPoint(x: p.x - dir * size * 1.05, y: p.y + size * 0.1))
        tail.closeSubpath()
        c.fill(tail, with: .color(Sketch.hex(body)))
        c.fill(Path(ellipseIn: CGRect(x: p.x - size * 0.6, y: p.y - size * 0.4, width: size * 1.2, height: size * 0.8)),
               with: .color(Sketch.hex(body)))
        c.fill(Path(ellipseIn: CGRect(x: p.x + dir * size * 0.05 - size * 0.3, y: p.y - size * 0.15, width: size * 0.6, height: size * 0.5)),
               with: .color(Sketch.hex(breast)))
        let head = CGPoint(x: p.x + dir * size * 0.5, y: p.y - size * 0.4)
        c.fill(Path(ellipseIn: CGRect(x: head.x - size * 0.3, y: head.y - size * 0.3, width: size * 0.6, height: size * 0.6)),
               with: .color(Sketch.hex(body)))
        var beak = Path()
        beak.move(to: CGPoint(x: head.x + dir * size * 0.25, y: head.y - size * 0.06))
        beak.addLine(to: CGPoint(x: head.x + dir * size * 0.5, y: head.y + size * 0.02))
        beak.addLine(to: CGPoint(x: head.x + dir * size * 0.25, y: head.y + size * 0.1))
        beak.closeSubpath()
        c.fill(beak, with: .color(Sketch.hex(0xE8A040)))
        c.fill(Path(ellipseIn: CGRect(x: head.x + dir * size * 0.08 - 1.2, y: head.y - size * 0.1, width: 2.4, height: 2.4)),
               with: .color(.black))
        var legs = Path()
        legs.move(to: CGPoint(x: p.x - size * 0.1, y: p.y + size * 0.35)); legs.addLine(to: CGPoint(x: p.x - size * 0.1, y: p.y + size * 0.6))
        legs.move(to: CGPoint(x: p.x + size * 0.1, y: p.y + size * 0.35)); legs.addLine(to: CGPoint(x: p.x + size * 0.1, y: p.y + size * 0.6))
        c.stroke(legs, with: .color(Sketch.hex(0x5A3A2A)), lineWidth: 1)
    }
}
