//
//  Scenery.swift
//  Respire
//
//  A Canadian fall night behind the glass: the Rockies along the horizon, the
//  northern lights over them, and maple leaves in reds and ambers. Everything is
//  drawn in code (paths and a Metal shader), so it scales to any screen.
//
//  - `AuroraSky`       northern lights from the `aurora` shader; still or flowing.
//  - `RockyMountains`  three layered ranges with snowcaps and a pine treeline.
//  - `MapleLeaf`       the eleven-pointed leaf as a `Shape`.
//  - `FallingLeaves`   a few leaves drifting down, swaying and turning.
//  - `RestingLeaves`   the same leaves, still, for screens that shouldn't move.
//

import SwiftUI

// MARK: - Aurora

struct AuroraSky: View {
    /// Flowing animation. Off for quiet backdrops, on for the breath.
    var isFlowing = false
    /// Overall brightness, 0...1.
    var strength: Double = 0.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isFlowing || reduceMotion)) { timeline in
            let time = isFlowing && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000) : 42
            GeometryReader { geo in
                Rectangle()
                    .colorEffect(ShaderLibrary.aurora(
                        .float2(geo.size.width, geo.size.height),
                        .float(time),
                        .float(strength)
                    ))
                    .blendMode(.plusLighter)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Mountains

/// The Rockies: a pale far range, a middle range with snowcaps, and a dark near
/// ridge edged with pines. Drawn to fill its frame from the bottom up.
struct RockyMountains: View {
    var seed: UInt64 = 1867

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var rng = SeededGenerator(seed: seed)

            let layers: [(base: Double, rise: Double, step: ClosedRange<Double>, color: Color, snow: Bool)] = [
                (0.55, 0.5, 0.05...0.09, Color(red: 0.24, green: 0.28, blue: 0.42).opacity(0.75), true),
                (0.72, 0.42, 0.06...0.11, Color(red: 0.13, green: 0.16, blue: 0.26).opacity(0.92), true),
                (0.9, 0.14, 0.02...0.04, Color(red: 0.04, green: 0.05, blue: 0.09), false),
            ]

            for (index, layer) in layers.enumerated() {
                // A jagged ridge: alternating peaks and saddles.
                var ridge: [CGPoint] = []
                var x = -0.05
                var high = Bool.random(using: &rng)
                while x < 1.08 {
                    let lift = high ? Double.random(in: 0.55...1.0, using: &rng) : Double.random(in: 0.05...0.4, using: &rng)
                    let y = h * (layer.base - layer.rise * lift)
                    ridge.append(CGPoint(x: w * x, y: y))
                    x += Double.random(in: layer.step, using: &rng)
                    high.toggle()
                }

                // Break each slope into shoulders and crags, so ridges read as rock, not teeth.
                var rugged: [CGPoint] = []
                for i in 0..<ridge.count {
                    rugged.append(ridge[i])
                    guard i + 1 < ridge.count else { continue }
                    let a = ridge[i], b = ridge[i + 1]
                    for step in 1...2 {
                        let t = Double(step) / 3 + Double.random(in: -0.08...0.08, using: &rng)
                        let jitter = abs(b.y - a.y) * Double.random(in: -0.18...0.18, using: &rng)
                        rugged.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t + jitter))
                    }
                }

                var range = Path()
                range.move(to: CGPoint(x: 0, y: h))
                for point in rugged { range.addLine(to: point) }
                range.addLine(to: CGPoint(x: w, y: h))
                range.closeSubpath()
                // Moonlight catching the upper slopes.
                let top = h * (layer.base - layer.rise)
                context.fill(range, with: .linearGradient(
                    Gradient(colors: [layer.color.opacity(1), layer.color.opacity(1).mix(with: .black, by: 0.35)]),
                    startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: h)
                ))

                // Snowcaps on the taller peaks.
                if layer.snow {
                    for i in 1..<(ridge.count - 1) {
                        let peak = ridge[i], left = ridge[i - 1], right = ridge[i + 1]
                        guard peak.y < left.y, peak.y < right.y, peak.y < h * (layer.base - layer.rise * 0.6) else { continue }
                        let depth = 0.32
                        let l = CGPoint(x: peak.x + (left.x - peak.x) * depth, y: peak.y + (left.y - peak.y) * depth)
                        let r = CGPoint(x: peak.x + (right.x - peak.x) * depth, y: peak.y + (right.y - peak.y) * depth)
                        var cap = Path()
                        cap.move(to: peak)
                        cap.addLine(to: r)
                        cap.addLine(to: CGPoint(x: (peak.x + r.x) / 2, y: max(l.y, r.y) - (max(l.y, r.y) - peak.y) * 0.25))
                        cap.addLine(to: CGPoint(x: peak.x, y: max(l.y, r.y) - (max(l.y, r.y) - peak.y) * 0.05))
                        cap.addLine(to: CGPoint(x: (peak.x + l.x) / 2, y: max(l.y, r.y) - (max(l.y, r.y) - peak.y) * 0.3))
                        cap.addLine(to: l)
                        cap.closeSubpath()
                        context.fill(cap, with: .color(.white.opacity(index == 0 ? 0.35 : 0.6)))
                    }
                }

                // Pines along the near ridge.
                if index == layers.count - 1 {
                    var px = 0.0
                    while px < w {
                        let ground = ridgeY(at: px, ridge: ridge)
                        let tall = h * Double.random(in: 0.06...0.13, using: &rng)
                        let wide = tall * 0.34
                        var pine = Path()
                        pine.move(to: CGPoint(x: px, y: ground - tall))
                        pine.addLine(to: CGPoint(x: px + wide / 2, y: ground + 1))
                        pine.addLine(to: CGPoint(x: px - wide / 2, y: ground + 1))
                        pine.closeSubpath()
                        context.fill(pine, with: .color(layer.color))
                        px += Double.random(in: 5...14, using: &rng)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func ridgeY(at x: Double, ridge: [CGPoint]) -> Double {
        guard let right = ridge.firstIndex(where: { $0.x >= x }), right > 0 else { return Double(ridge.first?.y ?? 0) }
        let a = ridge[right - 1], b = ridge[right]
        let t = (x - a.x) / max(b.x - a.x, 0.001)
        return a.y + (b.y - a.y) * t
    }
}

// MARK: - Maple leaf

/// The eleven-pointed maple leaf, in a unit square, stem at the bottom.
struct MapleLeaf: Shape {
    /// Right half, from the top tip clockwise to the stem; mirrored for the left.
    nonisolated private static let half: [CGPoint] = [
        CGPoint(x: 0.0, y: -1.0), CGPoint(x: 0.12, y: -0.76), CGPoint(x: 0.27, y: -0.83),
        CGPoint(x: 0.2, y: -0.42), CGPoint(x: 0.45, y: -0.66), CGPoint(x: 0.51, y: -0.52),
        CGPoint(x: 0.7, y: -0.58), CGPoint(x: 0.61, y: -0.3), CGPoint(x: 0.88, y: -0.24),
        CGPoint(x: 0.81, y: -0.1), CGPoint(x: 0.94, y: 0.04), CGPoint(x: 0.56, y: 0.3),
        CGPoint(x: 0.62, y: 0.44), CGPoint(x: 0.3, y: 0.39), CGPoint(x: 0.05, y: 0.42),
        CGPoint(x: 0.04, y: 0.92), CGPoint(x: 0.0, y: 0.92),
    ]

    nonisolated func path(in rect: CGRect) -> Path {
        let points = Self.half + Self.half.reversed().dropFirst().dropLast().map { CGPoint(x: -$0.x, y: $0.y) }
        let scale = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for (i, p) in points.enumerated() {
            let point = CGPoint(x: center.x + p.x * scale, y: center.y + p.y * scale)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// Fall colors: crimson, red, orange, amber.
    static let fallColors: [Color] = [
        Color(red: 0.72, green: 0.1, blue: 0.13),
        Color(red: 0.88, green: 0.22, blue: 0.14),
        Color(red: 0.95, green: 0.48, blue: 0.12),
        Color(red: 0.98, green: 0.7, blue: 0.2),
    ]
}

// MARK: - Leaves

/// A few maple leaves drifting down, swaying and slowly turning. Given a
/// `landing` band (fractions of the height, e.g. a lake's surface), each leaf
/// comes to rest on the water there instead of falling through: it settles flat,
/// drifts, stirs a ripple where it touched down, then fades so another can fall.
struct FallingLeaves: View {
    var count = 9
    var seed: UInt64 = 1965
    /// Where leaves land and float, as fractions of the height. Nil: they fall past.
    var landing: ClosedRange<Double>? = nil
    /// Maple leaves, or cherry-blossom petals.
    var kind: LeafKind = .maple

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How long a leaf floats after landing before it fades away.
    private static let floatTime = 14.0

    var body: some View {
        if reduceMotion {
            RestingLeaves(count: count / 2, seed: seed)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000)
                Canvas { context, size in
                    var rng = SeededGenerator(seed: seed)
                    for _ in 0..<count {
                        let x0 = Double.random(in: 0...1, using: &rng)
                        let speed = Double.random(in: 18...38, using: &rng)
                        let offset = Double.random(in: 0...1000, using: &rng)
                        let sway = Double.random(in: 14...40, using: &rng)
                        let swaySpeed = Double.random(in: 0.4...0.9, using: &rng)
                        let leafSize = Double.random(in: 14...26, using: &rng)
                        let spin = Double.random(in: -0.8...0.8, using: &rng)
                        let palette = kind.colors
                        let color = palette[Int.random(in: 0..<palette.count, using: &rng)]
                        let landAt = landing.map { Double.random(in: $0, using: &rng) * size.height }

                        guard let landAt else {
                            let travel = size.height + 60
                            let y = (time * speed + offset).truncatingRemainder(dividingBy: travel) - 30
                            let x = x0 * size.width + sin(time * swaySpeed + offset) * sway
                            drawLeaf(in: &context, at: CGPoint(x: x, y: y), size: leafSize * kind.scale, angle: time * spin + offset, color: color, kind: kind)
                            continue
                        }

                        // One cycle: fall from above the screen to the water, then float.
                        let fallTime = (landAt + 30) / speed
                        let cycle = fallTime + Self.floatTime
                        let local = (time + offset).truncatingRemainder(dividingBy: cycle)
                        let swayAt = { (t: Double) in sin(t * swaySpeed + offset) * sway }

                        if local < fallTime {
                            let y = local * speed - 30
                            let x = x0 * size.width + swayAt(local)
                            drawLeaf(in: &context, at: CGPoint(x: x, y: y), size: leafSize * kind.scale, angle: local * spin + offset, color: color, kind: kind)
                        } else {
                            // Afloat: flattened by the angle of view, drifting on the surface.
                            let since = local - fallTime
                            let landedX = x0 * size.width + swayAt(fallTime)
                            let x = landedX + sin(since * 0.2 + offset) * 10 + since * 1.2
                            let point = CGPoint(x: x, y: landAt)
                            let fade = min(1, (Self.floatTime - since) / 3)
                            // Ripples from the touchdown.
                            for ring in 0..<2 {
                                let r = since * 14 - Double(ring) * 10
                                guard r > 0, since < 5 else { continue }
                                let ripple = CGRect(x: landedX - r, y: landAt - r * 0.16, width: r * 2, height: r * 0.32)
                                context.stroke(Path(ellipseIn: ripple),
                                                              with: .color(Color(red: 0.75, green: 0.9, blue: 1).opacity(0.3 * (1 - since / 5))),
                                                              lineWidth: 1)
                            }
                            var floating = context
                            floating.opacity = fade
                            floating.translateBy(x: point.x, y: point.y)
                            floating.scaleBy(x: 1, y: 0.42)
                            floating.translateBy(x: -point.x, y: -point.y)
                            drawLeaf(in: &floating, at: point, size: leafSize * 0.9 * kind.scale,
                                              angle: fallTime * spin + offset + since * 0.03, color: color, kind: kind)
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Maple leaves lying still, scattered near the bottom of the frame.
struct RestingLeaves: View {
    var count = 4
    var seed: UInt64 = 1965

    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: seed &+ 7)
            for _ in 0..<count {
                // Toward the edges, so leaves never sit under centered text.
                let side = Bool.random(using: &rng)
                let point = CGPoint(
                    x: (side ? Double.random(in: 0.04...0.24, using: &rng) : Double.random(in: 0.76...0.96, using: &rng)) * size.width,
                    y: Double.random(in: 0.7...0.97, using: &rng) * size.height
                )
                let color = MapleLeaf.fallColors[Int.random(in: 0..<MapleLeaf.fallColors.count, using: &rng)]
                drawLeaf(in: &context, at: point, size: Double.random(in: 12...20, using: &rng),
                                  angle: Double.random(in: -1...1, using: &rng), color: color.opacity(0.85))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// What falls: maple leaves, or cherry-blossom petals.
enum LeafKind {
    case maple, sakura

    var colors: [Color] {
        switch self {
        case .maple: MapleLeaf.fallColors
        case .sakura: [Color(red: 1, green: 0.84, blue: 0.9), Color(red: 0.98, green: 0.72, blue: 0.82), Color(red: 1, green: 0.92, blue: 0.95)]
        }
    }

    /// Petals are smaller than leaves.
    var scale: Double { self == .sakura ? 0.6 : 1 }
}

/// A single cherry-blossom petal: rounded, with a small notch at its tip.
struct SakuraPetal: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.midX + w * 0.12, y: rect.minY),
                                    control1: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.25),
                                    control2: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.14))
        path.addLine(to: CGPoint(x: rect.midX - w * 0.12, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                                    control1: CGPoint(x: rect.minX, y: rect.minY),
                                    control2: CGPoint(x: rect.minX, y: rect.maxY - h * 0.25))
        path.closeSubpath()
        return path
    }
}

private func drawLeaf(in context: inout GraphicsContext, at point: CGPoint, size: Double, angle: Double, color: Color, kind: LeafKind = .maple) {
    var leaf = context
    leaf.translateBy(x: point.x, y: point.y)
    leaf.rotate(by: .radians(angle))
    let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
    if kind == .sakura {
        leaf.fill(SakuraPetal().path(in: rect.insetBy(dx: size * 0.15, dy: 0)), with: .color(color))
        return
    }
    let path = MapleLeaf().path(in: rect)
    leaf.fill(path, with: .linearGradient(
        Gradient(colors: [color, color.opacity(0.7)]),
        startPoint: CGPoint(x: 0, y: -size / 2), endPoint: CGPoint(x: 0, y: size / 2)
    ))
    var vein = Path()
    vein.move(to: CGPoint(x: 0, y: size * 0.46))
    vein.addLine(to: CGPoint(x: 0, y: -size * 0.4))
    leaf.stroke(vein, with: .color(.black.opacity(0.25)), lineWidth: 0.6)
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(red: 0.04, green: 0.04, blue: 0.05)
        AuroraSky(isFlowing: true, strength: 0.9)
        RockyMountains().frame(height: 300)
        FallingLeaves()
    }
    .ignoresSafeArea()
}
