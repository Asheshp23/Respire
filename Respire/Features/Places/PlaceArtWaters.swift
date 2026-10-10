//
//  PlaceArtWaters.swift
//  Respire
//
//  Places 16–20: Paper Boat Canal, Mountain Hut Window, Firefly Meadow,
//  Moon Garden Gates, Ocean Postbox.
//

import SwiftUI

extension PlaceArt {
    // MARK: 16 · Paper Boat Canal

    /// A canal between quiet houses; a paper boat sets off with each breath and drifts away.
    static func paperBoats(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x2A2A5A), Sketch.hex(0xC0708A), Sketch.hex(0xF0B08A)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.45)))
        let horizon = h * 0.42
        // Houses lining both banks, shrinking toward the horizon: pitched roofs, a chimney
        // here and there, and rows of lit windows.
        var rng = SeededGenerator(seed: 161)
        for side in [-1.0, 1.0] {
            for k in (0..<6).reversed() {
                let t = Double(k) / 6
                let height = h * (0.24 - 0.17 * t) * Double.random(in: 0.85...1.15, using: &rng)
                let width = w * (0.2 - 0.13 * t)
                let x = w / 2 + side * (w * 0.5 - t * w * 0.4) - (side > 0 ? width : 0)
                let base = horizon + h * 0.13 * (1 - t)
                let rect = CGRect(x: x, y: base - height, width: width, height: height)
                let wall = Sketch.mix(Sketch.hex(0x4A3450), Sketch.hex(0x9A7A90), t)
                c.fill(Path(rect), with: .color(wall))
                var roof = Path()
                roof.move(to: CGPoint(x: rect.minX - width * 0.04, y: rect.minY))
                roof.addLine(to: CGPoint(x: rect.midX, y: rect.minY - height * 0.28))
                roof.addLine(to: CGPoint(x: rect.maxX + width * 0.04, y: rect.minY))
                roof.closeSubpath()
                c.fill(roof, with: .color(Sketch.mix(wall, .black, 0.3)))
                if k % 2 == 0 {
                    c.fill(Path(CGRect(x: rect.minX + width * 0.68, y: rect.minY - height * 0.24, width: width * 0.1, height: height * 0.16)),
                           with: .color(Sketch.mix(wall, .black, 0.35)))
                }
                for row in 0..<2 {
                    for col in 0..<2 {
                        guard Double.random(in: 0...1, using: &rng) > 0.3 else { continue }
                        let window = CGRect(x: rect.minX + width * (0.2 + 0.38 * Double(col)), y: rect.minY + height * (0.18 + 0.36 * Double(row)),
                                            width: width * 0.22, height: height * 0.18)
                        c.fill(Path(roundedRect: window, cornerRadius: 1.5), with: .color(Sketch.hex(0xFFD08A, 0.85 - 0.45 * t)))
                    }
                }
            }
        }
        // The canal: a trapezoid of water narrowing to the horizon.
        var canal = Path()
        canal.move(to: CGPoint(x: w * 0.1, y: h))
        canal.addLine(to: CGPoint(x: w * 0.46, y: horizon + h * 0.04))
        canal.addLine(to: CGPoint(x: w * 0.54, y: horizon + h * 0.04))
        canal.addLine(to: CGPoint(x: w * 0.9, y: h))
        canal.closeSubpath()
        c.fill(canal, with: .linearGradient(Gradient(colors: [Sketch.hex(0xD8907A), Sketch.hex(0x2A2A4A)]),
                                            startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h)))
        for k in 0..<12 {
            let y = horizon + h * 0.06 + Double(k) * (h - horizon) / 12
            var ripple = Path()
            ripple.move(to: CGPoint(x: w / 2 - 30 - Double(k) * 8, y: y))
            ripple.addLine(to: CGPoint(x: w / 2 + 30 + Double(k) * 8 + sin(f.time + Double(k)) * 4, y: y))
            c.stroke(ripple, with: .color(.white.opacity(0.08)), lineWidth: 1)
        }
        // Boats: each launches near you and floats off toward the horizon.
        for i in 0..<f.steps {
            let age = f.progress - Double(i)
            guard age > 0 else { continue }
            let t = min(age / 3, 1) // three breaths to drift away
            let y = h * 0.88 - (h * 0.88 - horizon - h * 0.06) * t
            let x = w / 2 + (Double(i % 2 == 0 ? -1 : 1) * w * 0.12) * (1 - t) + sin(f.time * 0.6 + Double(i)) * 6 * (1 - t)
            let size = w * 0.09 * (1 - 0.8 * t)
            var boat = Path()
            boat.move(to: CGPoint(x: x - size, y: y))
            boat.addLine(to: CGPoint(x: x + size, y: y))
            boat.addLine(to: CGPoint(x: x + size * 0.6, y: y + size * 0.4))
            boat.addLine(to: CGPoint(x: x - size * 0.6, y: y + size * 0.4))
            boat.closeSubpath()
            var sail = Path()
            sail.move(to: CGPoint(x: x - size * 0.5, y: y))
            sail.addLine(to: CGPoint(x: x, y: y - size * 0.9))
            sail.addLine(to: CGPoint(x: x + size * 0.5, y: y))
            sail.closeSubpath()
            let alpha = 1 - t * 0.6
            c.fill(boat, with: .color(Sketch.hex(0xF8F4EC, alpha)))
            c.fill(sail, with: .color(Sketch.hex(0xEDE6DA, alpha)))
            Sketch.ink(&c, sail, Sketch.hex(0x8A7A6A, alpha * 0.6), width: 0.8)
        }
    }

    // MARK: 17 · Mountain Hut Window

    /// A wooden window over the peaks; the weather outside changes with each breath.
    static func hutWindow(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(Sketch.hex(0x3A2414)))
        // Wood grain on the walls.
        var rng = SeededGenerator(seed: 171)
        for _ in 0..<50 {
            var grain = Path()
            let y = Double.random(in: 0...h, using: &rng)
            grain.move(to: CGPoint(x: 0, y: y))
            grain.addQuadCurve(to: CGPoint(x: w, y: y + Double.random(in: -10...10, using: &rng)), control: CGPoint(x: w / 2, y: y + Double.random(in: -20...20, using: &rng)))
            c.stroke(grain, with: .color(Sketch.hex(0x5A3A22, 0.4)), lineWidth: 1)
        }
        let pane = CGRect(x: w * 0.14, y: h * 0.16, width: w * 0.72, height: h * 0.5)
        var view = c
        view.clip(to: Path(pane))
        // Sky by weather: clear morning, fog, rain, snow, starry night.
        let skies: [(UInt32, UInt32)] = [(0x8AC0F0, 0xF0E0C0), (0xB8C0C8, 0xD8D8D8), (0x5A6A7A, 0x8A9AA8), (0x9AA8C0, 0xD8E0EA), (0x060A20, 0x1A2448)]
        let sky = skies[min(f.stage, skies.count - 1)]
        view.fill(Path(pane), with: .linearGradient(Gradient(colors: [Sketch.hex(sky.0), Sketch.hex(sky.1)]),
                                                    startPoint: CGPoint(x: 0, y: pane.minY), endPoint: CGPoint(x: 0, y: pane.maxY)))
        if f.stage == 4 {
            var night = view
            Sketch.night(&night, s, top: Sketch.hex(0x060A20), bottom: Sketch.hex(0x1A2448), stars: 120, starsTo: 0.5, time: f.time)
        }
        // Peaks with snowcaps.
        for (i, layer) in [(0.48, 0x6A7A9A), (0.56, 0x3A4A6A)].enumerated() {
            var range = Path()
            range.move(to: CGPoint(x: pane.minX, y: pane.maxY))
            let peaks = [0.0, 0.18, 0.32, 0.5, 0.66, 0.82, 1.0]
            for (k, px) in peaks.enumerated() {
                let up = k % 2 == 1 ? 0.22 : 0.08
                range.addLine(to: CGPoint(x: pane.minX + pane.width * px, y: pane.minY + pane.height * (layer.0 - up + 0.05 * Double(i))))
            }
            range.addLine(to: CGPoint(x: pane.maxX, y: pane.maxY)); range.closeSubpath()
            view.fill(range, with: .color(Sketch.hex(UInt32(layer.1))))
        }
        switch f.stage {
        case 1:
            for k in 0..<6 {
                let x = pane.minX + (Double(k) * pane.width * 0.3 + f.time * 8).truncatingRemainder(dividingBy: pane.width * 1.4) - pane.width * 0.2
                view.fill(Path(ellipseIn: CGRect(x: x, y: pane.minY + pane.height * (0.35 + 0.1 * Double(k % 3)), width: pane.width * 0.5, height: pane.height * 0.12)),
                          with: .color(.white.opacity(0.45)))
            }
        case 2:
            Sketch.rain(&view, s, density: 0.6, time: f.time, seed: 172, opacity: 0.4, region: pane)
        case 3:
            Sketch.drift(&view, s, count: 120, time: f.time, seed: 173, speed: 12...26, size: 1.5...3)
        default:
            break
        }
        // The frame and its cross bars, and a mug on the sill.
        Sketch.ink(&c, Path(pane), Sketch.hex(0x8A5A32), width: 12)
        var bars = Path()
        bars.move(to: CGPoint(x: pane.midX, y: pane.minY)); bars.addLine(to: CGPoint(x: pane.midX, y: pane.maxY))
        bars.move(to: CGPoint(x: pane.minX, y: pane.midY)); bars.addLine(to: CGPoint(x: pane.maxX, y: pane.midY))
        c.stroke(bars, with: .color(Sketch.hex(0x8A5A32)), lineWidth: 7)
        let sill = CGRect(x: w * 0.08, y: pane.maxY + 6, width: w * 0.84, height: h * 0.04)
        c.fill(Path(roundedRect: sill, cornerRadius: 3), with: .color(Sketch.hex(0x6A4428)))
        let mug = CGRect(x: w * 0.66, y: sill.minY - h * 0.06, width: w * 0.08, height: h * 0.06)
        c.fill(Path(roundedRect: mug, cornerRadius: 4), with: .color(Sketch.hex(0xE8E0D0)))
        for k in 0..<2 {
            var steam = Path()
            steam.move(to: CGPoint(x: mug.midX - 4 + Double(k) * 8, y: mug.minY))
            steam.addQuadCurve(to: CGPoint(x: mug.midX - 4 + Double(k) * 8, y: mug.minY - 26),
                               control: CGPoint(x: mug.midX + 6 + sin(f.time + Double(k)) * 6, y: mug.minY - 13))
            c.stroke(steam, with: .color(.white.opacity(0.4 * (1 - f.openness * 0.5))), lineWidth: 1.5)
        }
    }

    // MARK: 18 · Firefly Meadow

    /// Tall grass at dusk; fireflies gather, more with every breath, glowing as you breathe in.
    static func fireflyMeadow(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x14103A), bottom: Sketch.hex(0x3A2A4A), stars: 80, starsTo: 0.4, time: f.time)
        Sketch.glow(&c, at: CGPoint(x: w * 0.2, y: h * 0.62), radius: w * 0.5, color: Sketch.hex(0xE8806A), opacity: 0.25)
        // Layers of grass silhouettes swaying.
        var rng = SeededGenerator(seed: 181)
        for layer in 0..<3 {
            let base = h * (0.7 + 0.12 * Double(layer))
            let color = Sketch.mix(Sketch.hex(0x2A2A3A), Sketch.hex(0x0A0A10), Double(layer) / 2)
            for _ in 0..<70 {
                let x = Double.random(in: -10...(w + 10), using: &rng)
                let height = h * Double.random(in: 0.08...0.2, using: &rng)
                let sway = sin(f.time * 0.6 + x / 60) * 6
                var blade = Path()
                blade.move(to: CGPoint(x: x - 2, y: base + 20))
                blade.addQuadCurve(to: CGPoint(x: x + sway, y: base - height), control: CGPoint(x: x, y: base - height * 0.5))
                blade.addQuadCurve(to: CGPoint(x: x + 2, y: base + 20), control: CGPoint(x: x + 1, y: base - height * 0.4))
                c.fill(blade, with: .color(color))
            }
            c.fill(Path(CGRect(x: 0, y: base + 10, width: w, height: h - base)), with: .color(color))
        }
        // Fireflies: a dozen at first, more each breath.
        let count = 12 + Int(f.progress * 10)
        var flies = SeededGenerator(seed: 182)
        for i in 0..<count {
            let x0 = Double.random(in: 0...w, using: &flies)
            let y0 = Double.random(in: (h * 0.35)...(h * 0.85), using: &flies)
            let phase = Double.random(in: 0...(2 * .pi), using: &flies)
            let p = CGPoint(x: x0 + sin(f.time * 0.4 + phase) * 14, y: y0 + cos(f.time * 0.3 + phase) * 10)
            let blink = 0.5 + 0.5 * sin(f.time * 1.2 + phase)
            let glow = (0.3 + 0.7 * f.openness) * blink
            Sketch.glow(&c, at: p, radius: 10, color: Sketch.hex(0xD8F06A), opacity: 0.6 * glow)
            c.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3)), with: .color(Sketch.hex(0xF8FFB0, glow)))
            _ = i
        }
    }

    // MARK: 19 · Moon Garden Gates

    /// Round moon gates in a misty garden; one opens to light with each breath.
    static func moonGates(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        Sketch.night(&c, s, top: Sketch.hex(0x0A0A24), bottom: Sketch.hex(0x2A2448), stars: 110, starsTo: 0.4, time: f.time)
        let moon = CGPoint(x: w / 2, y: h * 0.16)
        Sketch.glow(&c, at: moon, radius: w * 0.3, color: Sketch.hex(0xF0E8FF), opacity: 0.3)
        c.fill(Path(ellipseIn: CGRect(x: moon.x - w * 0.07, y: moon.y - w * 0.07, width: w * 0.14, height: w * 0.14)), with: .color(Sketch.hex(0xF6F0E4)))
        // A path of stepping stones toward the gates.
        for k in 0..<8 {
            let t = Double(k) / 8
            let y = h * (0.95 - 0.32 * t)
            let r = w * (0.07 - 0.05 * t)
            c.fill(Path(ellipseIn: CGRect(x: w / 2 - r + sin(Double(k)) * 6, y: y, width: r * 2, height: r * 0.5)), with: .color(Sketch.hex(0x6A6A8A, 0.6)))
        }
        // A low garden wall across the middle, with round moon gates set into it.
        c.fill(Path(CGRect(x: 0, y: h * 0.5, width: w, height: h * 0.1)), with: .color(Sketch.hex(0x3A3458)))
        // Gates from far (small) to near (large), each a stone ring that glows once opened.
        for i in (0..<f.steps).reversed() {
            let t = Double(i) / Double(max(f.steps - 1, 1))
            let radius = w * (0.34 - 0.24 * t)
            let center = CGPoint(x: w / 2, y: h * (0.62 - 0.12 * t))
            let ring = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            let stone = Sketch.mix(Sketch.hex(0xB8B0D0), Sketch.hex(0x6A6488), t)
            c.stroke(ring, with: .color(stone), lineWidth: radius * 0.16)
            Sketch.ink(&c, ring, Sketch.hex(0x2A2448, 0.5), width: 1)
            let open = min(max(f.progress - Double(i), 0), 1)
            if open > 0 {
                Sketch.glow(&c, at: center, radius: radius * 0.95, color: Sketch.hex(0xF8E8FF), opacity: 0.22 * open)
                c.stroke(ring, with: .color(Sketch.hex(0xFFF0FF, 0.7 * open)), lineWidth: 2)
            }
        }
        // Mist drifting through the garden.
        for k in 0..<5 {
            let x = (Double(k) * w * 0.35 + f.time * 6).truncatingRemainder(dividingBy: w * 1.5) - w * 0.3
            c.fill(Path(ellipseIn: CGRect(x: x, y: h * (0.62 + 0.06 * Double(k % 3)), width: w * 0.6, height: h * 0.06)),
                   with: .color(.white.opacity(0.1)))
        }
    }

    // MARK: 20 · Ocean Postbox

    /// A red postbox at the end of a pier; a letter flies out to sea with each out-breath.
    static func oceanPostbox(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x2A3A6A), Sketch.hex(0xD8806A), Sketch.hex(0xF8C08A)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.55)))
        let sea = h * 0.55
        Sketch.glow(&c, at: CGPoint(x: w * 0.7, y: sea), radius: w * 0.4, color: Sketch.hex(0xFFD0A0), opacity: 0.5)
        c.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: sea - w * 0.08, width: w * 0.16, height: w * 0.16)), with: .color(Sketch.hex(0xFFE0B0)))
        c.fill(Path(CGRect(x: 0, y: sea, width: w, height: h - sea)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x8A5A7A), Sketch.hex(0x1A2040)]), startPoint: CGPoint(x: 0, y: sea), endPoint: CGPoint(x: 0, y: h)))
        for k in 0..<8 {
            var wave = Path()
            let y = sea + Double(k + 1) * (h - sea) / 9
            wave.move(to: CGPoint(x: 0, y: y))
            for x in stride(from: 0.0, through: w, by: 10) {
                wave.addLine(to: CGPoint(x: x, y: y + sin(x / 40 + f.time * 0.5 + Double(k)) * 2))
            }
            c.stroke(wave, with: .color(.white.opacity(0.1)), lineWidth: 1)
        }
        // The pier, running out from the bottom left.
        var pier = Path()
        pier.move(to: CGPoint(x: 0, y: h * 0.86)); pier.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
        pier.addLine(to: CGPoint(x: w * 0.42, y: h * 0.75)); pier.addLine(to: CGPoint(x: 0, y: h * 0.9)); pier.closeSubpath()
        c.fill(pier, with: .color(Sketch.hex(0x4A2E22)))
        for k in 0..<5 {
            let t = Double(k) / 4
            var post = Path()
            post.move(to: CGPoint(x: w * 0.42 * t, y: h * (0.88 - 0.14 * t)))
            post.addLine(to: CGPoint(x: w * 0.42 * t, y: h * (0.97 - 0.14 * t)))
            c.stroke(post, with: .color(Sketch.hex(0x2A1A12)), lineWidth: 4)
        }
        // The postbox.
        let box = CGRect(x: w * 0.33, y: h * 0.63, width: w * 0.07, height: h * 0.09)
        c.fill(Path(roundedRect: box, cornerRadius: 6), with: .color(Sketch.hex(0xC8302A)))
        c.fill(Path(CGRect(x: box.minX + 4, y: box.minY + box.height * 0.3, width: box.width - 8, height: 3)), with: .color(Sketch.hex(0x2A0A0A)))
        // Letters lift away over the sea, one per breath, released on the out-breath.
        let origin = CGPoint(x: box.midX, y: box.minY)
        for i in 0..<f.steps {
            let age = f.progress - Double(i)
            guard age > 0.4 else { continue } // leaves as the out-breath begins
            let t = min((age - 0.4) / 2.5, 1)
            let target = CGPoint(x: w * (0.62 + 0.08 * Double(i % 3)), y: sea - h * (0.12 + 0.05 * Double(i % 2)))
            let p = CGPoint(x: origin.x + (target.x - origin.x) * t, y: origin.y + (target.y - origin.y) * t - sin(t * .pi) * h * 0.12)
            let size = 14 * (1 - 0.6 * t)
            var letter = c
            letter.opacity = 1 - t * 0.7
            letter.translateBy(x: p.x, y: p.y)
            letter.rotate(by: .radians(sin(f.time * 2 + Double(i)) * 0.3))
            let rect = CGRect(x: -size, y: -size * 0.65, width: size * 2, height: size * 1.3)
            letter.fill(Path(rect), with: .color(Sketch.hex(0xF8F2E6)))
            var flap = Path()
            flap.move(to: CGPoint(x: rect.minX, y: rect.minY)); flap.addLine(to: CGPoint(x: 0, y: 0)); flap.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            letter.stroke(flap, with: .color(Sketch.hex(0xB8A890)), lineWidth: 0.8)
        }
        // A few gulls.
        for k in 0..<3 {
            let x = (f.time * 10 + Double(k) * w * 0.3).truncatingRemainder(dividingBy: w + 40) - 20
            let y = h * (0.18 + 0.05 * Double(k))
            let flapUp = 3 + sin(f.time * 3 + Double(k)) * 2
            var gull = Path()
            gull.move(to: CGPoint(x: x - 7, y: y - flapUp))
            gull.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 3, y: y - flapUp - 2))
            gull.addQuadCurve(to: CGPoint(x: x + 7, y: y - flapUp), control: CGPoint(x: x + 3, y: y - flapUp - 2))
            c.stroke(gull, with: .color(Sketch.hex(0x2A2030, 0.7)), lineWidth: 1.2)
        }
    }
}
