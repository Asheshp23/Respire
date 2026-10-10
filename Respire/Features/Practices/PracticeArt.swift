//
//  PracticeArt.swift
//  Respire
//
//  A scene for each guided session, drawn to match its technique, in the same
//  hand-drawn style as the Places. Each one breathes: `frame.openness` is the lung
//  volume (0 empty, 1 full), `frame.progress` the breaths so far (fractional), and
//  `frame.time` seconds since the scene appeared.
//
//  Bumble bees loop among opening flowers; a balloon fills; a starfish rests as waves
//  wash in; a light travels the four sides of a box; curtains sway at a night window;
//  dawn rises over a road; light grows between two people; a cup cools by a rainy
//  window; a circle widens around a lone tree; a bee hums on a lotus; two streams take
//  turns; sun swells over an armchair; lanterns light one by one in an evening garden.
//

import SwiftUI

enum PracticeArt {
    static func draw(_ id: String, _ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        switch id {
        case "bumble-bee": bumbleBee(&c, s, f)
        case "balloon-belly": balloonBelly(&c, s, f)
        case "sleepy-starfish": sleepyStarfish(&c, s, f)
        case "box-stress": boxBreathing(&c, s, f)
        case "sleep-sanctuary": sleepSanctuary(&c, s, f)
        case "test-prep": testPrep(&c, s, f)
        case "partner-peace": partnerPeace(&c, s, f)
        case "conflict-cool": coolTheArgument(&c, s, f)
        case "boundary-breath": boundaryBreath(&c, s, f)
        case "bhramari": bhramari(&c, s, f)
        case "nadi-shodhana": nadiShodhana(&c, s, f)
        case "gentle-chair": gentleChair(&c, s, f)
        case "evening-gratitude": eveningGratitude(&c, s, f)
        default: c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(Sketch.hex(0x101018)))
        }
    }

    /// The lighting pass for each scene. Bright, airy scenes glow less, so they never wash out.
    static func light(for id: String) -> PlaceEnvironment.Light {
        let soft = PlaceEnvironment.Light(point: CGPoint(x: 0.5, y: 0.2), color: .white, rays: 0, bloom: 0.2, threshold: 0.9)
        switch id {
        case "bumble-bee", "balloon-belly", "gentle-chair", "nadi-shodhana":
            return soft
        case "sleepy-starfish", "bhramari":
            return .init(point: CGPoint(x: 0.5, y: 0.15), color: Color(red: 0.85, green: 0.88, blue: 1), rays: 0.5)
        case "test-prep":
            return .init(point: CGPoint(x: 0.5, y: 0.55), color: Color(red: 1, green: 0.8, blue: 0.55), rays: 0.6, threshold: 0.65)
        case "evening-gratitude", "partner-peace":
            return .init(point: CGPoint(x: 0.5, y: 0.45), color: Color(red: 1, green: 0.8, blue: 0.5), rays: 0.35)
        default:
            return .init(point: CGPoint(x: 0.5, y: 0.3), color: .white, rays: 0.2)
        }
    }

    // MARK: - Pieces

    private static func sky(_ c: inout GraphicsContext, _ s: CGSize, _ top: UInt32, _ bottom: UInt32, to fraction: Double = 1) {
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(top), Sketch.hex(bottom)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: s.height * fraction)))
    }

    /// A rolling hill, its top at `y`.
    private static func hill(_ c: inout GraphicsContext, _ s: CGSize, y: Double, amplitude: Double, phase: Double, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: s.height))
        for x in stride(from: 0.0, through: s.width, by: 8) {
            path.addLine(to: CGPoint(x: x, y: y + sin(x / s.width * 3.2 + phase) * amplitude))
        }
        // The stride can stop short of the edge; finish the line exactly there.
        path.addLine(to: CGPoint(x: s.width, y: y + sin(3.2 + phase) * amplitude))
        path.addLine(to: CGPoint(x: s.width, y: s.height))
        path.closeSubpath()
        c.fill(path, with: .color(color))
    }

    private static func cloud(_ c: inout GraphicsContext, at p: CGPoint, width: Double, opacity: Double = 0.85) {
        for (dx, dy, r) in [(-0.3, 0.05, 0.22), (0.0, -0.06, 0.3), (0.3, 0.04, 0.24), (0.05, 0.1, 0.26)] {
            let radius = width * r
            c.fill(Path(ellipseIn: CGRect(x: p.x + width * dx - radius, y: p.y + width * dy - radius, width: radius * 2, height: radius * 1.6)),
                   with: .color(.white.opacity(opacity)))
        }
    }

    /// A flower that opens with `open` (0 closed, 1 wide).
    private static func flower(_ c: inout GraphicsContext, at p: CGPoint, size: Double, open: Double, petals: Int,
                               color: Color, sway: Double) {
        var stem = Path()
        stem.move(to: CGPoint(x: p.x, y: p.y + size * 3))
        stem.addQuadCurve(to: p, control: CGPoint(x: p.x + sway * size, y: p.y + size * 1.5))
        c.stroke(stem, with: .color(Sketch.hex(0x4E8A3A)), lineWidth: max(1.5, size * 0.12))
        let spread = size * (0.55 + 0.45 * open)
        for k in 0..<petals {
            let angle = Double(k) / Double(petals) * 2 * .pi
            let petal = Path(ellipseIn: CGRect(x: -spread * 0.35, y: -spread, width: spread * 0.7, height: spread))
            c.fill(petal.applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: p.x, y: p.y))),
                   with: .color(color))
        }
        c.fill(Path(ellipseIn: CGRect(x: p.x - size * 0.28, y: p.y - size * 0.28, width: size * 0.56, height: size * 0.56)),
               with: .color(Sketch.hex(0xF4C430)))
    }

    /// A round, striped bumblebee with fast, see-through wings.
    private static func bee(_ c: inout GraphicsContext, at p: CGPoint, size: Double, time: Double, tilt: Double) {
        var bee = c
        bee.translateBy(x: p.x, y: p.y)
        bee.rotate(by: .radians(tilt))
        let flap = 0.6 + 0.4 * sin(time * 38)
        for side in [-1.0, 1.0] {
            let wing = Path(ellipseIn: CGRect(x: side < 0 ? -size * 0.7 : size * 0.05, y: -size * (0.9 + 0.3 * flap),
                                              width: size * 0.65, height: size * 0.75 * flap + size * 0.2))
            bee.fill(wing, with: .color(.white.opacity(0.65)))
            bee.stroke(wing, with: .color(Sketch.hex(0x8AA8C0, 0.6)), lineWidth: 0.8)
        }
        let body = CGRect(x: -size * 0.6, y: -size * 0.4, width: size * 1.2, height: size * 0.8)
        bee.fill(Path(ellipseIn: body), with: .color(Sketch.hex(0xF6C232)))
        var stripes = bee
        stripes.clip(to: Path(ellipseIn: body))
        for k in 0..<2 {
            stripes.fill(Path(CGRect(x: -size * 0.15 + Double(k) * size * 0.35, y: body.minY, width: size * 0.16, height: body.height)),
                         with: .color(Sketch.hex(0x2A2016)))
        }
        bee.fill(Path(ellipseIn: CGRect(x: size * 0.42, y: -size * 0.28, width: size * 0.42, height: size * 0.5)),
                 with: .color(Sketch.hex(0x2A2016)))
    }

    /// A seated figure in silhouette, facing `facing` (-1 left, 1 right).
    private static func seated(_ c: inout GraphicsContext, base: CGPoint, height: Double, facing: Double, color: Color) {
        let head = height * 0.16
        c.fill(Path(ellipseIn: CGRect(x: base.x - head, y: base.y - height, width: head * 2, height: head * 2)), with: .color(color))
        var body = Path()
        body.move(to: CGPoint(x: base.x - height * 0.18, y: base.y))
        body.addQuadCurve(to: CGPoint(x: base.x, y: base.y - height + head * 2.1),
                          control: CGPoint(x: base.x - height * 0.22, y: base.y - height * 0.5))
        body.addQuadCurve(to: CGPoint(x: base.x + height * 0.18 + facing * height * 0.06, y: base.y),
                          control: CGPoint(x: base.x + height * 0.2, y: base.y - height * 0.45))
        body.closeSubpath()
        c.fill(body, with: .color(color))
    }

    // MARK: - Bumble Bee Breath

    private static func bumbleBee(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        sky(&c, s, 0x8FCDEB, 0xFCEFCF, to: 0.8)
        Sketch.glow(&c, at: CGPoint(x: w * 0.82, y: h * 0.14), radius: m * 0.35, color: Sketch.hex(0xFFF2B0), opacity: 0.7)
        cloud(&c, at: CGPoint(x: (w * 0.2 + f.time * 4).truncatingRemainder(dividingBy: w * 1.3) - w * 0.1, y: h * 0.2), width: m * 0.3)
        hill(&c, s, y: h * 0.68, amplitude: h * 0.02, phase: 0.5, color: Sketch.hex(0x9BCF72))
        hill(&c, s, y: h * 0.78, amplitude: h * 0.015, phase: 2, color: Sketch.hex(0x78B556))

        // Flowers open as the lungs fill.
        let colors = [0xF27BA0, 0xB07BE0, 0xFFFFFF, 0xF59A4A, 0xF27BA0, 0x7BA8F2] as [UInt32]
        var spots: [CGPoint] = []
        for k in 0..<6 {
            let p = CGPoint(x: w * (0.12 + 0.155 * Double(k)), y: h * (0.74 + 0.05 * sin(Double(k) * 1.9)))
            spots.append(p)
            flower(&c, at: p, size: m * 0.055, open: 0.4 + 0.6 * f.openness, petals: k % 2 == 0 ? 6 : 5,
                   color: Sketch.hex(colors[k]), sway: sin(f.time * 0.8 + Double(k)) * 0.4)
        }
        // Bees loop between them, buzzing harder on the out-breath, when you hum.
        let hum = 1 - f.openness
        for k in 0..<3 {
            let home = spots[(k * 2 + 1) % spots.count]
            let a = f.time * (0.7 + 0.15 * Double(k)) + Double(k) * 2.1
            let p = CGPoint(x: home.x + cos(a) * m * 0.12, y: home.y - m * 0.16 + sin(a * 1.6) * m * 0.06)
            for ring in 1...2 {
                let r = m * 0.03 * Double(ring) * (1 + hum)
                c.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                         with: .color(Sketch.hex(0xF6C232, 0.35 * hum / Double(ring))), lineWidth: 1.2)
            }
            bee(&c, at: p, size: m * 0.045, time: f.time + Double(k), tilt: sin(a) * 0.3)
        }
    }

    // MARK: - Balloon Belly

    private static func balloonBelly(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        sky(&c, s, 0xA9D6F5, 0xFBE3EC)
        for k in 0..<3 {
            let x = (Double(k) * w * 0.45 + f.time * (5 + Double(k) * 2)).truncatingRemainder(dividingBy: w * 1.4) - w * 0.2
            cloud(&c, at: CGPoint(x: x, y: h * (0.15 + 0.12 * Double(k))), width: m * (0.22 + 0.06 * Double(k)), opacity: 0.8)
        }
        hill(&c, s, y: h * 0.86, amplitude: h * 0.01, phase: 1, color: Sketch.hex(0x8CCB7A))

        // The balloon fills and lifts with the in-breath.
        let r = m * (0.15 + 0.11 * f.openness)
        let center = CGPoint(x: w / 2 + sin(f.time * 0.6) * m * 0.02, y: h * 0.46 - f.openness * h * 0.04)
        var string = Path()
        string.move(to: CGPoint(x: center.x, y: center.y + r * 1.15))
        string.addCurve(to: CGPoint(x: w / 2, y: h * 0.88),
                        control1: CGPoint(x: center.x + m * 0.05 * sin(f.time), y: center.y + r * 1.6),
                        control2: CGPoint(x: w / 2 - m * 0.04, y: h * 0.75))
        c.stroke(string, with: .color(Sketch.hex(0x6A5A70)), lineWidth: 1.4)
        let balloon = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 1.12, width: r * 2, height: r * 2.24))
        c.fill(balloon, with: .radialGradient(Gradient(colors: [Sketch.hex(0xFF9AA6), Sketch.hex(0xE8506A)]),
                                              center: CGPoint(x: center.x - r * 0.35, y: center.y - r * 0.45), startRadius: 0, endRadius: r * 1.6))
        c.fill(Path(ellipseIn: CGRect(x: center.x - r * 0.55, y: center.y - r * 0.75, width: r * 0.32, height: r * 0.5)),
               with: .color(.white.opacity(0.45)))
        var knot = Path()
        knot.move(to: CGPoint(x: center.x - r * 0.08, y: center.y + r * 1.15))
        knot.addLine(to: CGPoint(x: center.x + r * 0.08, y: center.y + r * 1.15))
        knot.addLine(to: CGPoint(x: center.x, y: center.y + r * 1.05))
        knot.closeSubpath()
        c.fill(knot, with: .color(Sketch.hex(0xE8506A)))
    }

    // MARK: - Sleepy Starfish

    private static func sleepyStarfish(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        Sketch.night(&c, s, top: Sketch.hex(0x0A1030), bottom: Sketch.hex(0x2A3A6A), stars: 110, starsTo: 0.45, time: f.time)
        // Low enough to stay clear of the title bar above it.
        let moon = CGPoint(x: w * 0.74, y: h * 0.28)
        Sketch.glow(&c, at: moon, radius: m * 0.3, color: Sketch.hex(0xF0F0FF), opacity: 0.3)
        c.fill(Path(ellipseIn: CGRect(x: moon.x - m * 0.06, y: moon.y - m * 0.06, width: m * 0.12, height: m * 0.12)),
               with: .color(Sketch.hex(0xF4F0E0)))
        let sea = h * 0.52
        c.fill(Path(CGRect(x: 0, y: sea, width: w, height: h - sea)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x1E3060), Sketch.hex(0x2E4A7A)]), startPoint: CGPoint(x: 0, y: sea), endPoint: CGPoint(x: 0, y: h * 0.7)))
        // The sand, and the wave washing up it as you breathe in.
        let shore = h * 0.7 - f.openness * h * 0.06
        var sand = Path()
        sand.move(to: CGPoint(x: 0, y: shore))
        for x in stride(from: 0.0, through: w, by: 8) {
            sand.addLine(to: CGPoint(x: x, y: shore + sin(x / 40 + f.time * 0.6) * 3))
        }
        sand.addLine(to: CGPoint(x: w, y: shore + sin(w / 40 + f.time * 0.6) * 3))
        sand.addLine(to: CGPoint(x: w, y: h))
        sand.addLine(to: CGPoint(x: 0, y: h))
        sand.closeSubpath()
        c.fill(sand, with: .color(Sketch.hex(0x9A8668)))
        var foam = Path()
        foam.move(to: CGPoint(x: 0, y: shore))
        for x in stride(from: 0.0, through: w, by: 8) {
            foam.addLine(to: CGPoint(x: x, y: shore + sin(x / 40 + f.time * 0.6) * 3))
        }
        foam.addLine(to: CGPoint(x: w, y: shore + sin(w / 40 + f.time * 0.6) * 3))
        c.stroke(foam, with: .color(.white.opacity(0.55)), lineWidth: 2)
        // The starfish, its arms softening as you breathe.
        let center = CGPoint(x: w / 2, y: h * 0.84)
        let reach = m * 0.15 * (0.92 + 0.08 * f.openness)
        var star = Path()
        for k in 0..<10 {
            let angle = Double(k) / 10 * 2 * .pi - .pi / 2 + sin(f.time * 0.1) * 0.05
            let r = k % 2 == 0 ? reach : reach * 0.42
            let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r * 0.62)
            if k == 0 { star.move(to: p) } else { star.addLine(to: p) }
        }
        star.closeSubpath()
        c.fill(star, with: .color(Sketch.hex(0xE88A5A)))
        Sketch.ink(&c, star, Sketch.hex(0xA85A34, 0.6), width: 1.2)
        for k in 0..<12 {
            let a = Double(k) * 0.52
            c.fill(Path(ellipseIn: CGRect(x: center.x + cos(a) * reach * 0.4 - 1.5, y: center.y + sin(a) * reach * 0.25 - 1.5, width: 3, height: 3)),
                   with: .color(Sketch.hex(0xFFC09A)))
        }
    }

    // MARK: - Box Breathing

    /// A window at night, rain and moonlit hills outside; a light travels its wooden frame.
    private static func boxBreathing(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        // The room: a warm, dim wall.
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0x2A2230), Sketch.hex(0x1A1620)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        let side = m * 0.58
        let box = CGRect(x: w / 2 - side / 2, y: h * 0.46 - side / 2, width: side, height: side)

        // Outside: night hills under a hazy moon, in soft rain.
        var outside = c
        outside.clip(to: Path(box))
        Sketch.night(&outside, s, top: Sketch.hex(0x101C36), bottom: Sketch.hex(0x2A3A5A), stars: 30, starsTo: 0.4, time: f.time)
        let moon = CGPoint(x: box.minX + side * 0.7, y: box.minY + side * 0.28)
        Sketch.glow(&outside, at: moon, radius: side * 0.35, color: Sketch.hex(0xD8E0FF), opacity: 0.35)
        outside.fill(Path(ellipseIn: CGRect(x: moon.x - side * 0.06, y: moon.y - side * 0.06, width: side * 0.12, height: side * 0.12)),
                     with: .color(Sketch.hex(0xEEEAD8)))
        for (k, color) in [(0, 0x26324E), (1, 0x1A2238)] as [(Int, UInt32)] {
            var ridge = Path()
            let base = box.minY + side * (0.62 + 0.14 * Double(k))
            ridge.move(to: CGPoint(x: box.minX, y: box.maxY))
            for x in stride(from: box.minX, through: box.maxX, by: 6) {
                let t = (x - box.minX) / side
                ridge.addLine(to: CGPoint(x: x, y: base - sin(t * 5 + Double(k) * 2) * side * 0.05 - sin(t * 13) * side * 0.012))
            }
            ridge.addLine(to: CGPoint(x: box.maxX, y: box.maxY))
            ridge.closeSubpath()
            outside.fill(ridge, with: .color(Sketch.hex(color)))
        }
        Sketch.rain(&outside, s, density: 0.4, time: f.time, seed: 301, opacity: 0.22, region: box)

        // The wooden frame, a sill, and the crossbars.
        let wood = Sketch.hex(0x6A4A34)
        c.stroke(Path(box), with: .color(wood), lineWidth: m * 0.03)
        c.fill(Path(roundedRect: CGRect(x: box.minX - m * 0.05, y: box.maxY + m * 0.012, width: side + m * 0.1, height: m * 0.03), cornerRadius: 3),
               with: .color(Sketch.hex(0x7A5A40)))
        var bars = Path()
        bars.move(to: CGPoint(x: box.midX, y: box.minY)); bars.addLine(to: CGPoint(x: box.midX, y: box.maxY))
        bars.move(to: CGPoint(x: box.minX, y: box.midY)); bars.addLine(to: CGPoint(x: box.maxX, y: box.midY))
        c.stroke(bars, with: .color(wood), lineWidth: m * 0.012)
        // Warm lamplight from inside, on the wall below.
        Sketch.glow(&c, at: CGPoint(x: w * 0.5, y: h * 0.95), radius: m * 0.5, color: Sketch.hex(0xFFB060), opacity: 0.18)

        // A light travels the frame: up the left as you breathe in, across the top as you
        // hold, down the right as you breathe out, back along the bottom as you rest.
        let fraction = f.progress - floor(f.progress)
        func point(_ t: Double) -> CGPoint {
            let u = t * 4
            switch u {
            case ..<1: return CGPoint(x: box.minX, y: box.maxY - side * u)
            case ..<2: return CGPoint(x: box.minX + side * (u - 1), y: box.minY)
            case ..<3: return CGPoint(x: box.maxX, y: box.minY + side * (u - 2))
            default: return CGPoint(x: box.maxX - side * (u - 3), y: box.maxY)
            }
        }
        var trail = Path()
        let start = max(fraction - 0.18, 0)
        trail.move(to: point(start))
        for k in 1...24 { trail.addLine(to: point(start + (fraction - start) * Double(k) / 24)) }
        c.stroke(trail, with: .color(Sketch.hex(0xFFD8A0, 0.75)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        let dot = point(fraction)
        Sketch.glow(&c, at: dot, radius: m * 0.08, color: Sketch.hex(0xFFD8A0), opacity: 0.7)
        c.fill(Path(ellipseIn: CGRect(x: dot.x - 5, y: dot.y - 5, width: 10, height: 10)), with: .color(Sketch.hex(0xFFF6E8)))
    }

    // MARK: - Sleep Sanctuary

    private static func sleepSanctuary(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .color(Sketch.hex(0x16182E)))
        let window = CGRect(x: w * 0.24, y: h * 0.16, width: w * 0.52, height: h * 0.34)
        var outside = c
        outside.clip(to: Path(roundedRect: window, cornerRadius: 6))
        Sketch.night(&outside, s, top: Sketch.hex(0x060A22), bottom: Sketch.hex(0x1A2450), stars: 90, starsTo: 0.5, time: f.time)
        let moon = CGPoint(x: window.midX + window.width * 0.18, y: window.minY + window.height * 0.3)
        Sketch.glow(&outside, at: moon, radius: m * 0.2, color: Sketch.hex(0xE8ECFF), opacity: 0.35)
        outside.fill(Path(ellipseIn: CGRect(x: moon.x - m * 0.045, y: moon.y - m * 0.045, width: m * 0.09, height: m * 0.09)),
                     with: .color(Sketch.hex(0xF2EEDC)))
        c.stroke(Path(roundedRect: window, cornerRadius: 6), with: .color(Sketch.hex(0x3A3C60)), lineWidth: 6)
        var bars = Path()
        bars.move(to: CGPoint(x: window.midX, y: window.minY))
        bars.addLine(to: CGPoint(x: window.midX, y: window.maxY))
        c.stroke(bars, with: .color(Sketch.hex(0x3A3C60)), lineWidth: 4)
        // Curtains drift with the breath.
        for side in [-1.0, 1.0] {
            let sway = f.openness * w * 0.02 * side
            let x0 = side < 0 ? window.minX - w * 0.1 : window.maxX - w * 0.02
            var curtain = Path()
            curtain.move(to: CGPoint(x: x0, y: window.minY - h * 0.04))
            curtain.addLine(to: CGPoint(x: x0 + w * 0.12, y: window.minY - h * 0.04))
            curtain.addQuadCurve(to: CGPoint(x: x0 + w * 0.12 + sway, y: window.maxY + h * 0.08),
                                 control: CGPoint(x: x0 + w * 0.12 + sway * 2, y: window.midY))
            curtain.addLine(to: CGPoint(x: x0 + sway, y: window.maxY + h * 0.08))
            curtain.closeSubpath()
            c.fill(curtain, with: .color(Sketch.hex(0x4A3A6A, 0.9)))
        }
        // The floor, a bedside table with a lamp that dims as the session goes on, and the bed.
        c.fill(Path(CGRect(x: 0, y: h * 0.9, width: w, height: h * 0.1)), with: .color(Sketch.hex(0x101224)))
        let table = CGRect(x: w * 0.04, y: h * 0.66, width: w * 0.2, height: h * 0.24)
        c.fill(Path(roundedRect: table, cornerRadius: 4), with: .color(Sketch.hex(0x3A2E40)))
        c.fill(Path(CGRect(x: table.minX + 6, y: table.minY + table.height * 0.4, width: table.width - 12, height: 2)),
               with: .color(Sketch.hex(0x2A2030)))
        let glowing = 1 - 0.7 * f.fraction
        let lamp = CGPoint(x: table.midX, y: table.minY - m * 0.09)
        Sketch.glow(&c, at: lamp, radius: m * 0.32, color: Sketch.hex(0xFFB868), opacity: 0.45 * glowing)
        c.fill(Path(CGRect(x: lamp.x - 1.5, y: lamp.y, width: 3, height: m * 0.09)), with: .color(Sketch.hex(0x5A4A50)))
        c.fill(Path(ellipseIn: CGRect(x: lamp.x - m * 0.035, y: table.minY - m * 0.012, width: m * 0.07, height: m * 0.02)),
               with: .color(Sketch.hex(0x5A4A50)))
        var shade = Path()
        shade.move(to: CGPoint(x: lamp.x - m * 0.035, y: lamp.y - m * 0.05))
        shade.addLine(to: CGPoint(x: lamp.x + m * 0.035, y: lamp.y - m * 0.05))
        shade.addLine(to: CGPoint(x: lamp.x + m * 0.06, y: lamp.y + m * 0.01))
        shade.addLine(to: CGPoint(x: lamp.x - m * 0.06, y: lamp.y + m * 0.01))
        shade.closeSubpath()
        c.fill(shade, with: .color(Sketch.hex(0xF0C890, 0.6 + 0.35 * glowing)))

        // The headboard, mattress, pillow, and a blanket that rises softly with the breath.
        let headboard = CGRect(x: w * 0.28, y: h * 0.6, width: w * 0.05, height: h * 0.3)
        c.fill(Path(roundedRect: headboard, cornerRadius: 6), with: .color(Sketch.hex(0x4A3A5A)))
        let mattress = CGRect(x: headboard.maxX - 2, y: h * 0.76, width: w * 0.72, height: h * 0.1)
        c.fill(Path(roundedRect: mattress, cornerRadius: 10), with: .color(Sketch.hex(0x3A3E6A)))
        c.fill(Path(CGRect(x: mattress.minX + 4, y: mattress.maxY, width: 5, height: h * 0.04)), with: .color(Sketch.hex(0x2A2240)))
        c.fill(Path(roundedRect: CGRect(x: headboard.maxX + w * 0.01, y: mattress.minY - h * 0.045, width: w * 0.16, height: h * 0.06), cornerRadius: 12),
               with: .color(Sketch.hex(0x8A8EC0)))
        let rise = h * 0.012 * f.openness
        var blanket = Path()
        let left = headboard.maxX + w * 0.16
        blanket.move(to: CGPoint(x: left, y: mattress.maxY))
        blanket.addLine(to: CGPoint(x: left, y: mattress.minY - h * 0.01))
        blanket.addCurve(to: CGPoint(x: w * 1.02, y: mattress.minY + h * 0.005),
                         control1: CGPoint(x: left + w * 0.12, y: mattress.minY - h * 0.06 - rise),
                         control2: CGPoint(x: left + w * 0.3, y: mattress.minY - h * 0.03 - rise * 0.5))
        blanket.addLine(to: CGPoint(x: w * 1.02, y: mattress.maxY + h * 0.02))
        blanket.addLine(to: CGPoint(x: left, y: mattress.maxY + h * 0.02))
        blanket.closeSubpath()
        c.fill(blanket, with: .color(Sketch.hex(0x5A4E8A)))
        var fold = Path()
        fold.move(to: CGPoint(x: left + w * 0.015, y: mattress.minY - h * 0.005))
        fold.addLine(to: CGPoint(x: left + w * 0.015, y: mattress.maxY + h * 0.015))
        c.stroke(fold, with: .color(Sketch.hex(0x7A70AA)), lineWidth: 3)
    }

    // MARK: - Before a Test

    private static func testPrep(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        let horizon = h * 0.6
        // Dawn: the sky warms and the sun rises over the session.
        let warm = f.fraction
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.mix(Sketch.hex(0x1A2448), Sketch.hex(0x3A5A9A), warm), Sketch.hex(0xF4A876), Sketch.hex(0xFFD8A0)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))
        let sun = CGPoint(x: w / 2, y: horizon - m * 0.05 - h * 0.14 * warm)
        Sketch.glow(&c, at: sun, radius: m * (0.4 + 0.08 * f.openness), color: Sketch.hex(0xFFE0A0), opacity: 0.55)
        c.fill(Path(ellipseIn: CGRect(x: sun.x - m * 0.08, y: sun.y - m * 0.08, width: m * 0.16, height: m * 0.16)),
               with: .color(Sketch.hex(0xFFF0C8)))
        hill(&c, s, y: horizon, amplitude: h * 0.03, phase: 0.2, color: Sketch.hex(0x6A5A8A))
        hill(&c, s, y: horizon + h * 0.08, amplitude: h * 0.02, phase: 1.7, color: Sketch.hex(0x4A4A72))
        // A road running toward the sun.
        var road = Path()
        road.move(to: CGPoint(x: w * 0.2, y: h))
        road.addLine(to: CGPoint(x: w * 0.49, y: horizon + h * 0.04))
        road.addLine(to: CGPoint(x: w * 0.51, y: horizon + h * 0.04))
        road.addLine(to: CGPoint(x: w * 0.8, y: h))
        road.closeSubpath()
        c.fill(road, with: .linearGradient(Gradient(colors: [Sketch.hex(0xC8A080), Sketch.hex(0x3A3458)]),
                                           startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h)))
        for k in 0..<6 {
            let t = Double(k) / 6
            let y = horizon + h * 0.06 + (h - horizon) * t * t
            c.fill(Path(CGRect(x: w / 2 - 1 - t * 3, y: y, width: 2 + t * 6, height: 4 + t * 18)), with: .color(.white.opacity(0.5)))
        }
    }

    // MARK: - Space Before You Speak

    private static func partnerPeace(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        sky(&c, s, 0x3A2E5A, 0xEFA88A, to: 0.6)
        let water = h * 0.6
        c.fill(Path(CGRect(x: 0, y: water, width: w, height: h - water)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0xB0809A), Sketch.hex(0x2A2448)]), startPoint: CGPoint(x: 0, y: water), endPoint: CGPoint(x: 0, y: h)))
        for k in 0..<6 {
            var ripple = Path()
            let y = water + Double(k + 1) * (h - water) / 8
            ripple.move(to: CGPoint(x: w * 0.1, y: y))
            ripple.addLine(to: CGPoint(x: w * 0.9, y: y + sin(f.time * 0.4 + Double(k)) * 1.5))
            c.stroke(ripple, with: .color(.white.opacity(0.08)), lineWidth: 1)
        }
        // Two people on a bench, with room between them, and a light that grows in that space.
        let bench = CGRect(x: w * 0.14, y: water - h * 0.05, width: w * 0.72, height: h * 0.018)
        let between = CGPoint(x: w / 2, y: bench.minY - m * 0.09)
        Sketch.glow(&c, at: between, radius: m * (0.12 + 0.12 * f.openness), color: Sketch.hex(0xFFD8A0), opacity: 0.55)
        c.fill(Path(ellipseIn: CGRect(x: between.x - 4, y: between.y - 4, width: 8, height: 8)), with: .color(Sketch.hex(0xFFF0D0)))
        c.fill(Path(bench), with: .color(Sketch.hex(0x2A1C2E)))
        for x in [bench.minX + 10, bench.maxX - 14] {
            c.fill(Path(CGRect(x: x, y: bench.maxY, width: 4, height: h * 0.04)), with: .color(Sketch.hex(0x2A1C2E)))
        }
        seated(&c, base: CGPoint(x: w * 0.3, y: bench.minY), height: m * 0.2, facing: 1, color: Sketch.hex(0x2A1C2E))
        seated(&c, base: CGPoint(x: w * 0.7, y: bench.minY), height: m * 0.19, facing: -1, color: Sketch.hex(0x2A1C2E))
        // Their reflection, and the light's.
        Sketch.glow(&c, at: CGPoint(x: between.x, y: water + (water - between.y) * 0.6), radius: m * 0.1, color: Sketch.hex(0xFFD8A0), opacity: 0.2)
    }

    // MARK: - Cool the Argument

    private static func coolTheArgument(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        // The room cools from a hot red toward a calm blue as the session goes on.
        let cool = f.fraction
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.mix(Sketch.hex(0x5A2420), Sketch.hex(0x1E2E48), cool), Sketch.mix(Sketch.hex(0x3A1814), Sketch.hex(0x142236), cool)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        let window = CGRect(x: w * 0.18, y: h * 0.14, width: w * 0.64, height: h * 0.36)
        var pane = c
        pane.clip(to: Path(roundedRect: window, cornerRadius: 8))
        pane.fill(Path(window), with: .linearGradient(Gradient(colors: [Sketch.hex(0x2A3A5A), Sketch.hex(0x4A6080)]),
                                                     startPoint: CGPoint(x: 0, y: window.minY), endPoint: CGPoint(x: 0, y: window.maxY)))
        Sketch.rain(&pane, s, density: 0.5, time: f.time, seed: 311, opacity: 0.35, region: window)
        c.stroke(Path(roundedRect: window, cornerRadius: 8), with: .color(Sketch.hex(0x1A1012, 0.8)), lineWidth: 6)
        // A table, and a cup whose steam settles as things cool.
        let table = h * 0.72
        c.fill(Path(CGRect(x: 0, y: table, width: w, height: h - table)), with: .color(Sketch.mix(Sketch.hex(0x4A2A1E), Sketch.hex(0x2A2A34), cool)))
        let cup = CGRect(x: w / 2 - m * 0.1, y: table - m * 0.15, width: m * 0.2, height: m * 0.15)
        c.fill(Path(ellipseIn: CGRect(x: cup.minX - m * 0.05, y: table - m * 0.02, width: cup.width + m * 0.1, height: m * 0.05)),
               with: .color(Sketch.hex(0xE8E0D4)))
        var body = Path()
        body.move(to: CGPoint(x: cup.minX, y: cup.minY))
        body.addLine(to: CGPoint(x: cup.maxX, y: cup.minY))
        body.addQuadCurve(to: CGPoint(x: cup.midX, y: cup.maxY), control: CGPoint(x: cup.maxX, y: cup.maxY))
        body.addQuadCurve(to: CGPoint(x: cup.minX, y: cup.minY), control: CGPoint(x: cup.minX, y: cup.maxY))
        c.fill(body, with: .color(Sketch.hex(0xF2ECE2)))
        c.stroke(Path(ellipseIn: CGRect(x: cup.maxX - m * 0.02, y: cup.minY + m * 0.03, width: m * 0.06, height: m * 0.06)),
                 with: .color(Sketch.hex(0xF2ECE2)), lineWidth: 3)
        let steam = 1 - 0.6 * cool
        for k in 0..<3 {
            var wisp = Path()
            let x0 = cup.minX + cup.width * (0.25 + 0.25 * Double(k))
            wisp.move(to: CGPoint(x: x0, y: cup.minY - 4))
            for step in 1...12 {
                let t = Double(step) / 12
                wisp.addLine(to: CGPoint(x: x0 + sin(t * 5 + f.time * 1.2 + Double(k)) * m * 0.025, y: cup.minY - 4 - t * m * 0.22 * steam))
            }
            c.stroke(wisp, with: .color(.white.opacity(0.35 * steam * (0.6 + 0.4 * (1 - f.openness)))), lineWidth: 2)
        }
    }

    // MARK: - Boundary Breath

    private static func boundaryBreath(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        sky(&c, s, 0x241C48, 0xE0906A, to: 0.66)
        Sketch.night(&c, CGSize(width: w, height: h * 0.35), top: .clear, bottom: .clear, stars: 50, starsTo: 1, time: f.time)
        let crest = CGPoint(x: w / 2, y: h * 0.6)
        var hillPath = Path()
        hillPath.move(to: CGPoint(x: -w * 0.1, y: h))
        hillPath.addQuadCurve(to: CGPoint(x: w * 1.1, y: h), control: CGPoint(x: w / 2, y: crest.y - h * 0.14))
        c.fill(hillPath, with: .color(Sketch.hex(0x3A2E40)))
        // A circle of your own space, widening as you breathe in.
        let r = m * (0.24 + 0.08 * f.openness)
        let center = CGPoint(x: crest.x, y: crest.y - m * 0.12)
        c.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
               with: .radialGradient(Gradient(colors: [Sketch.hex(0xFFD8A0, 0.25), .clear]), center: center, startRadius: r * 0.3, endRadius: r))
        c.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                 with: .color(Sketch.hex(0xFFE0B0, 0.55)), lineWidth: 1.5)
        // The lone tree, rooted.
        var trunk = Path()
        trunk.move(to: CGPoint(x: crest.x, y: crest.y - h * 0.03))
        trunk.addLine(to: CGPoint(x: crest.x, y: center.y - m * 0.02))
        c.stroke(trunk, with: .color(Sketch.hex(0x1E1424)), lineWidth: 6)
        for (dx, dy, rr) in [(0.0, -0.1, 0.09), (-0.06, -0.06, 0.07), (0.06, -0.06, 0.07)] {
            let p = CGPoint(x: crest.x + m * dx, y: center.y + m * dy + sin(f.time * 0.5) * 2)
            c.fill(Path(ellipseIn: CGRect(x: p.x - m * rr, y: p.y - m * rr, width: m * rr * 2, height: m * rr * 2)),
                   with: .color(Sketch.hex(0x2A2034)))
        }
    }

    // MARK: - Bhramari

    private static func bhramari(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        Sketch.night(&c, s, top: Sketch.hex(0x140C2A), bottom: Sketch.hex(0x2E1E4A), stars: 80, starsTo: 0.5, time: f.time)
        let water = h * 0.66
        c.fill(Path(CGRect(x: 0, y: water, width: w, height: h - water)), with: .color(Sketch.hex(0x1A1434)))
        let lotus = CGPoint(x: w / 2, y: water - m * 0.02)
        // Sound spreading from the humming bee, strongest on the out-breath.
        let hum = 1 - f.openness
        for k in 0..<5 {
            let t = (f.time * 0.35 + Double(k) / 5).truncatingRemainder(dividingBy: 1)
            let r = m * (0.1 + 0.55 * t)
            c.stroke(Path(ellipseIn: CGRect(x: lotus.x - r, y: lotus.y - m * 0.12 - r, width: r * 2, height: r * 2)),
                     with: .color(Sketch.hex(0xE8C0FF, 0.25 * (1 - t) * (0.3 + 0.7 * hum))), lineWidth: 1.4)
            let rx = r * 1.3
            c.stroke(Path(ellipseIn: CGRect(x: lotus.x - rx, y: water + m * 0.02 - rx * 0.12, width: rx * 2, height: rx * 0.24)),
                     with: .color(.white.opacity(0.12 * (1 - t))), lineWidth: 1)
        }
        // The lotus.
        for k in 0..<7 {
            let angle = -.pi / 2 + (Double(k) - 3) * 0.32
            let petal = Path(ellipseIn: CGRect(x: -m * 0.035, y: -m * 0.13, width: m * 0.07, height: m * 0.13))
            c.fill(petal.applying(CGAffineTransform(rotationAngle: angle + .pi / 2).concatenating(CGAffineTransform(translationX: lotus.x, y: lotus.y))),
                   with: .color(Sketch.mix(Sketch.hex(0xF2A8C8), Sketch.hex(0xFFE0EC), abs(Double(k) - 3) / 3)))
        }
        c.fill(Path(ellipseIn: CGRect(x: lotus.x - m * 0.16, y: lotus.y - m * 0.01, width: m * 0.32, height: m * 0.05)),
               with: .color(Sketch.hex(0x2A5A3A)))
        bee(&c, at: CGPoint(x: lotus.x, y: lotus.y - m * 0.12), size: m * 0.04, time: f.time * (0.3 + hum), tilt: 0)
    }

    // MARK: - Nadi Shodhana

    private static func nadiShodhana(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        sky(&c, s, 0xC6DCEC, 0xEDE6D8)
        hill(&c, s, y: h * 0.3, amplitude: h * 0.04, phase: 0.3, color: Sketch.hex(0xA8B8C8))
        hill(&c, s, y: h * 0.42, amplitude: h * 0.03, phase: 2.2, color: Sketch.hex(0x8EA894))
        c.fill(Path(CGRect(x: 0, y: h * 0.5, width: w, height: h * 0.5)), with: .color(Sketch.hex(0x7E9A80)))
        // Two streams, cool and warm, take turns with the breath and meet in one pond.
        let breath = Int(f.progress)
        let leftActive = breath % 2 == 0
        let pool = CGPoint(x: w / 2, y: h * 0.8)
        for (index, side) in [-1.0, 1.0].enumerated() {
            let active = (index == 0) == leftActive
            let p0 = CGPoint(x: w / 2 + side * w * 0.42, y: h * 0.38)
            let p1 = CGPoint(x: w / 2 + side * w * 0.1, y: h * 0.5)
            let p2 = CGPoint(x: w / 2 + side * w * 0.32, y: h * 0.7)
            let p3 = CGPoint(x: pool.x + side * m * 0.08, y: pool.y)
            func along(_ t: Double) -> CGPoint {
                let u = 1 - t
                return CGPoint(x: u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x,
                               y: u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y)
            }
            var stream = Path()
            stream.move(to: p0)
            stream.addCurve(to: p3, control1: p1, control2: p2)
            let color = index == 0 ? Sketch.hex(0x5AA8D8) : Sketch.hex(0xD8A85A)
            let strength = active ? 0.6 + 0.4 * f.openness : 0.4
            // Banks, water, and a pale sheen down the middle.
            c.stroke(stream, with: .color(Sketch.hex(0x5E7A60)), style: StrokeStyle(lineWidth: m * 0.07, lineCap: .round))
            c.stroke(stream, with: .color(color.opacity(strength)), style: StrokeStyle(lineWidth: m * (active ? 0.05 : 0.04), lineCap: .round))
            c.stroke(stream, with: .color(.white.opacity(active ? 0.28 : 0.12)), style: StrokeStyle(lineWidth: m * 0.008, lineCap: .round))
            // Glints carried downstream, quicker on the side that's breathing.
            for k in 0..<6 {
                let t = (Double(k) / 6 + f.time * (active ? 0.08 : 0.03)).truncatingRemainder(dividingBy: 1)
                let p = along(t)
                c.fill(Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 1, width: 4, height: 2)),
                       with: .color(.white.opacity((active ? 0.7 : 0.3) * sin(t * .pi))))
            }
        }
        // The pond, with reeds and stones on its edge.
        let pond = CGRect(x: pool.x - m * 0.28, y: pool.y - m * 0.07, width: m * 0.56, height: m * 0.16)
        c.fill(Path(ellipseIn: pond.insetBy(dx: -m * 0.015, dy: -m * 0.012)), with: .color(Sketch.hex(0x5E7A60)))
        c.fill(Path(ellipseIn: pond), with: .linearGradient(
            Gradient(colors: [Sketch.mix(Sketch.hex(0x5AA8D8), Sketch.hex(0xD8A85A), 0.5), Sketch.hex(0x4A7E92)]),
            startPoint: CGPoint(x: 0, y: pond.minY), endPoint: CGPoint(x: 0, y: pond.maxY)))
        for k in 0..<2 {
            let grow = (f.time * 0.2 + Double(k) / 2).truncatingRemainder(dividingBy: 1)
            c.stroke(Path(ellipseIn: CGRect(x: pool.x - pond.width * 0.4 * grow, y: pool.y + pond.height * 0.1 - pond.height * 0.3 * grow,
                                             width: pond.width * 0.8 * grow, height: pond.height * 0.6 * grow)),
                     with: .color(.white.opacity(0.35 * (1 - grow))), lineWidth: 1)
        }
        for (x, r) in [(-0.3, 0.025), (-0.24, 0.018), (0.29, 0.022)] {
            c.fill(Path(ellipseIn: CGRect(x: pool.x + m * x - m * r, y: pond.maxY - m * r * 0.8, width: m * r * 2, height: m * r * 1.2)),
                   with: .color(Sketch.hex(0x8A8A7A)))
        }
        for k in 0..<7 {
            let x = pond.maxX - m * 0.06 + Double(k) * m * 0.012
            var reed = Path()
            reed.move(to: CGPoint(x: x, y: pond.midY + m * 0.02))
            reed.addQuadCurve(to: CGPoint(x: x + sin(f.time * 0.8 + Double(k)) * 3, y: pond.midY - m * (0.1 + 0.02 * Double(k % 3))),
                              control: CGPoint(x: x - 2, y: pond.midY - m * 0.04))
            c.stroke(reed, with: .color(Sketch.hex(0x4E6A44)), lineWidth: 1.5)
        }
    }

    // MARK: - Gentle Chair Breath

    private static func gentleChair(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
            Gradient(colors: [Sketch.hex(0xD8C4A8), Sketch.hex(0xB89A78)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        let window = CGRect(x: w * 0.56, y: h * 0.14, width: w * 0.34, height: h * 0.36)
        c.fill(Path(window), with: .linearGradient(Gradient(colors: [Sketch.hex(0xBFE0F4), Sketch.hex(0xFFF2D8)]),
                                                 startPoint: CGPoint(x: 0, y: window.minY), endPoint: CGPoint(x: 0, y: window.maxY)))
        c.stroke(Path(window), with: .color(Sketch.hex(0x8A6A4A)), lineWidth: 5)
        // Sunlight across the floor, swelling a little with the breath.
        var beam = Path()
        beam.move(to: CGPoint(x: window.minX, y: window.minY))
        beam.addLine(to: CGPoint(x: window.maxX, y: window.maxY))
        beam.addLine(to: CGPoint(x: w * 0.55, y: h))
        beam.addLine(to: CGPoint(x: w * 0.02, y: h))
        beam.closeSubpath()
        c.fill(beam, with: .linearGradient(Gradient(colors: [Sketch.hex(0xFFF2D0, 0.25 + 0.15 * f.openness), .clear]),
                                           startPoint: CGPoint(x: window.midX, y: window.minY), endPoint: CGPoint(x: w * 0.3, y: h)))
        let floor = h * 0.78
        c.fill(Path(CGRect(x: 0, y: floor, width: w, height: h - floor)), with: .color(Sketch.hex(0x9A7A5A)))
        // The armchair: a tall back, two arms, a deep seat, and short turned legs.
        // Sized from the shorter side, so it stays an armchair on wide screens, not a sofa.
        let chairWidth = m * 0.46, chairHeight = m * 0.52
        let chair = CGRect(x: w * 0.12, y: floor + m * 0.03 - chairHeight, width: chairWidth, height: chairHeight)
        let fabric = Sketch.hex(0x6E8E7E), shadow = Sketch.hex(0x5A7A6A)
        c.fill(Path(roundedRect: CGRect(x: chair.minX + chair.width * 0.12, y: chair.minY, width: chair.width * 0.76, height: chair.height * 0.6),
                    cornerRadius: chair.width * 0.18), with: .color(fabric))
        c.fill(Path(roundedRect: CGRect(x: chair.minX + chair.width * 0.14, y: chair.minY + chair.height * 0.5, width: chair.width * 0.72, height: chair.height * 0.22),
                    cornerRadius: 12), with: .color(Sketch.hex(0x7E9E8E)))
        for x in [chair.minX, chair.maxX - chair.width * 0.2] {
            c.fill(Path(roundedRect: CGRect(x: x, y: chair.minY + chair.height * 0.38, width: chair.width * 0.2, height: chair.height * 0.42),
                        cornerRadius: chair.width * 0.08), with: .color(shadow))
        }
        c.fill(Path(roundedRect: CGRect(x: chair.minX + chair.width * 0.06, y: chair.minY + chair.height * 0.7, width: chair.width * 0.88, height: chair.height * 0.14),
                    cornerRadius: 6), with: .color(shadow))
        for x in [chair.minX + chair.width * 0.1, chair.maxX - chair.width * 0.14] {
            c.fill(Path(roundedRect: CGRect(x: x, y: chair.minY + chair.height * 0.84, width: chair.width * 0.04, height: chair.height * 0.1), cornerRadius: 2),
                   with: .color(Sketch.hex(0x5A3A24)))
        }
        // A plant by the window, its leaves moving in the air.
        let pot = CGRect(x: w * 0.7, y: floor - m * 0.12, width: m * 0.12, height: m * 0.12)
        for k in 0..<7 {
            let angle = -.pi / 2 + (Double(k) - 3) * 0.32 + sin(f.time * 0.7 + Double(k)) * 0.06 * (0.6 + f.openness)
            c.fill(Sketch.leaf(at: CGPoint(x: pot.midX, y: pot.minY), size: m * 0.13, angle: angle), with: .color(Sketch.hex(0x4E8A4A)))
        }
        c.fill(Path(roundedRect: pot, cornerRadius: 4), with: .color(Sketch.hex(0xC0704A)))
        // Dust turning slowly in the sunbeam, and only there.
        var inBeam = c
        inBeam.clip(to: beam)
        Sketch.drift(&inBeam, s, count: 30, time: f.time, seed: 331, color: Sketch.hex(0xFFF0C8), speed: 1...3, size: 0.8...1.6)
    }

    // MARK: - Evening Gratitude

    private static func eveningGratitude(_ c: inout GraphicsContext, _ s: CGSize, _ f: PlaceFrame) {
        let w = s.width, h = s.height, m = min(w, h)
        sky(&c, s, 0x1E2048, 0xE89A7A, to: 0.62)
        Sketch.night(&c, CGSize(width: w, height: h * 0.3), top: .clear, bottom: .clear, stars: 40, starsTo: 1, time: f.time)
        hill(&c, s, y: h * 0.62, amplitude: h * 0.02, phase: 1, color: Sketch.hex(0x2A2440))
        for k in 0..<9 {
            let x = w * (Double(k) / 8)
            let r = m * (0.08 + 0.04 * sin(Double(k) * 2.3))
            c.fill(Path(ellipseIn: CGRect(x: x - r, y: h * 0.66 - r * 0.6, width: r * 2, height: r * 1.4)), with: .color(Sketch.hex(0x1E1A30)))
        }
        c.fill(Path(CGRect(x: 0, y: h * 0.7, width: w, height: h * 0.3)), with: .color(Sketch.hex(0x1A1628)))
        // A string of lanterns across the garden, lighting one by one through the session.
        let count = 7
        let lit = f.fraction * Double(count)
        var string = Path()
        string.move(to: CGPoint(x: -10, y: h * 0.38))
        string.addQuadCurve(to: CGPoint(x: w + 10, y: h * 0.38), control: CGPoint(x: w / 2, y: h * 0.5))
        c.stroke(string, with: .color(Sketch.hex(0x1A1420)), lineWidth: 1.5)
        for k in 0..<count {
            let t = (Double(k) + 0.5) / Double(count)
            let x = -10 + (w + 20) * t
            let y = h * 0.38 + 4 * t * (1 - t) * (h * 0.12) + m * 0.03
            let on = min(max(lit - Double(k), 0), 1)
            if on > 0 {
                Sketch.glow(&c, at: CGPoint(x: x, y: y), radius: m * 0.09 * (0.8 + 0.2 * f.openness), color: Sketch.hex(0xFFC070), opacity: 0.6 * on)
            }
            c.fill(Path(roundedRect: CGRect(x: x - m * 0.022, y: y - m * 0.03, width: m * 0.044, height: m * 0.06), cornerRadius: m * 0.015),
                   with: .color(Sketch.mix(Sketch.hex(0x3A2A30), Sketch.hex(0xFFD890), on)))
        }
        // Fireflies over the grass.
        for k in 0..<16 {
            let x = (Double(k) * w * 0.137 + sin(f.time * 0.3 + Double(k)) * 20).truncatingRemainder(dividingBy: w)
            let y = h * (0.72 + 0.2 * abs(sin(Double(k) * 1.7))) + sin(f.time * 0.5 + Double(k)) * 6
            let blink = pow(0.5 + 0.5 * sin(f.time * 1.3 + Double(k) * 2), 3)
            Sketch.glow(&c, at: CGPoint(x: x, y: y), radius: 8, color: Sketch.hex(0xD8F06A), opacity: 0.7 * blink)
        }
    }
}

// MARK: - Views

/// A practice's scene for one frame.
struct PracticeCanvas: View {
    let practice: Practice
    var frame: PlaceFrame

    var body: some View {
        Canvas { context, size in
            PracticeArt.draw(practice.id, &context, size, frame)
        }
        .accessibilityHidden(true)
    }
}

/// A practice's scene, alive and breathing with the engine, lit with the painterly finish.
struct PracticeScene: View {
    let practice: Practice
    let engine: BreathEngine

    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let current = frame(at: timeline.date)
            PracticeCanvas(practice: practice, frame: current)
                .placeLighting(PracticeArt.light(for: practice.id), breath: current.openness, time: current.time)
        }
        .accessibilityHidden(true)
    }

    private func frame(at date: Date) -> PlaceFrame {
        let elapsed = date.timeIntervalSince(start)
        let progress: Double = switch engine.state {
        case .idle: 0
        case .finished: Double(practice.breaths)
        case .running, .paused: engine.cycleProgress(at: date)
        }
        let openness = reduceMotion ? 0.6 : (engine.state == .running || engine.state == .paused
            ? engine.snapshot(at: date).lungVolume
            : 0.35 + 0.1 * sin(elapsed * 0.5))
        return PlaceFrame(progress: progress, steps: practice.breaths, openness: openness, time: reduceMotion ? 3 : elapsed)
    }
}

#Preview("All practice scenes") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
            ForEach(Practice.all) { practice in
                PracticeCanvas(practice: practice, frame: PlaceFrame(progress: 2.4, steps: practice.breaths, openness: 0.6, time: 3))
                    .frame(height: 200)
                    .overlay(alignment: .bottomLeading) {
                        Text(practice.title).font(.caption2.bold()).foregroundStyle(.white).shadow(radius: 2).padding(4)
                    }
                    .clipped()
            }
        }
    }
    .background(.black)
}

#Preview("The last five scenes") {
    VStack(spacing: 4) {
        ForEach(Array(Practice.all.suffix(5))) { practice in
            PracticeCanvas(practice: practice, frame: PlaceFrame(progress: 2.4, steps: practice.breaths, openness: 0.6, time: 3))
                .frame(height: 160)
                .overlay(alignment: .bottomLeading) {
                    Text(practice.title).font(.caption2.bold()).foregroundStyle(.white).shadow(radius: 2).padding(4)
                }
                .clipped()
        }
    }
    .background(.black)
}
