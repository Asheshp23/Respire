//
//  AuroraLake.swift
//  Respire
//
//  Aurora Lake: the northern lights over the Rockies, held in a still lake, with
//  a lotus on the water that opens as you breathe in and folds as you breathe
//  out. Also the shared night-sky pieces (`Stars`, `WaterShimmer`).
//

import SwiftUI

// MARK: - Aurora Lake

/// A Canadian fall night: the northern lights flowing over the Rockies and
/// lighting the sky and the lake, leaves landing on the water, a lotus breathing.
struct AuroraLakeScene: View {
    var openness: Double
    var time: Double
    var showsLeaves = true

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let water = geo.size.height * Lotus.waterLine
                let range = geo.size.height * 0.2
                // How brightly the aurora lights everything; it swells a little as you breathe in.
                let glow = 0.75 + 0.25 * openness
                ZStack(alignment: .top) {
                    // A sky lit by the aurora: violet at the zenith, brightening to teal
                    // where the lights hang and toward the horizon.
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.07, green: 0.06, blue: 0.2), location: 0),
                            .init(color: Color(red: 0.07, green: 0.2, blue: 0.24), location: 0.45),
                            .init(color: Color(red: 0.12, green: 0.24, blue: 0.3), location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: water)
                    Stars()
                        .frame(height: water * 0.85)
                        .opacity(0.8)
                    // Airglow: the green light the aurora spills across the whole sky.
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [Color(red: 0.25, green: 0.95, blue: 0.6).opacity(0.5), Color(red: 0.4, green: 0.3, blue: 1).opacity(0.12), .clear],
                            center: .center, startRadius: 0, endRadius: geo.size.width * 0.75
                        ))
                        .frame(width: geo.size.width * 1.6, height: water * 0.9)
                        .offset(y: water * 0.08)
                        .blur(radius: 40)
                        .blendMode(.plusLighter)
                        .opacity(glow)
                    AuroraSky(isFlowing: true, strength: 0.95)
                        .frame(height: water)
                    RockyMountains()
                        .frame(height: range)
                        .offset(y: water - range)
                    // Aurora light catching the peaks and snow.
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 1, blue: 0.65).opacity(0.22), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: range)
                    .offset(y: water - range)
                    .mask(RockyMountains().frame(height: range).offset(y: water - range))
                    .blendMode(.plusLighter)
                    .opacity(glow)

                    // The lake, holding the lit sky: teal near the shore, deepening below.
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.22, blue: 0.25), Color(red: 0.02, green: 0.07, blue: 0.1)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: geo.size.height - water)
                    .offset(y: water)
                    AuroraSky(isFlowing: true, strength: 0.75)
                        .frame(height: water)
                        .scaleEffect(x: 1, y: -0.55, anchor: .top)
                        .offset(y: water)
                        .blur(radius: 5)
                        .opacity(0.8)
                    // The airglow's sheen on the water near the shore.
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [Color(red: 0.3, green: 0.95, blue: 0.65).opacity(0.35), .clear],
                            center: .center, startRadius: 0, endRadius: geo.size.width * 0.6
                        ))
                        .frame(width: geo.size.width * 1.4, height: (geo.size.height - water) * 0.45)
                        .offset(y: water)
                        .blur(radius: 24)
                        .blendMode(.plusLighter)
                        .opacity(glow)
                    RockyMountains()
                        .frame(height: range)
                        .scaleEffect(x: 1, y: -0.6, anchor: .top)
                        .offset(y: water)
                        .opacity(0.35)
                        .blur(radius: 2)
                    WaterShimmer()
                        .frame(height: geo.size.height - water)
                        .offset(y: water)
                }
                // Leaves come to rest on the lake and float.
                if showsLeaves {
                    FallingLeaves(count: 18, landing: (Lotus.waterLine + 0.02)...0.95)
                }
            }

            Lotus(openness: openness, time: time)
        }
    }
}

// MARK: - Lotus

/// A lotus on still water, drawn to look like the real flower: three rows of
/// cupped petals placed in 3D around the receptacle, cream at the base blushing to pink at the tips, each shaded for
/// its curve and traced with fine veins; a golden seed pod ringed with stamens at
/// the heart; lily pads with their notches floating around it. `openness` 0 is a
/// closed bud, 1 fully open. Its reflection lies in the water, and slow ripples
/// spread from it.
private struct Lotus: View {
    var openness: Double
    var time: Double

    /// Where the lake's surface sits, as a fraction of the screen height.
    static let waterLine = 0.62

    // Natural lotus colors.
    private static let cream = Color(red: 1.0, green: 0.96, blue: 0.94)
    private static let blush = Color(red: 0.98, green: 0.7, blue: 0.79)
    private static let rose = Color(red: 0.86, green: 0.34, blue: 0.53)

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let water = h * Self.waterLine
            let base = CGPoint(x: w / 2, y: water + h * 0.02)
            // A small flower in a wide lake.
            let length = min(w * 0.13, h * 0.085)
            let pad = w * 0.1

            // Ripples rolling out from the flower: a bright crest and a dark trough
            // each, flattened by the angle of view, fading as they widen.
            for i in 0..<5 {
                let phase = (time / 9 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                drawRipple(in: &context, center: base, radius: length * 0.7 + phase * w * 0.55, fade: 1 - phase, strength: 1)
            }

            // Lily pads scattered across the water, larger as they come closer.
            drawPad(in: &context, center: CGPoint(x: base.x, y: base.y + length * 0.08), radius: pad * 0.95, notch: 1.4)
            drawPad(in: &context, center: CGPoint(x: w * 0.14, y: water + h * 0.06), radius: pad * 1.4, notch: 0.4)
            drawPad(in: &context, center: CGPoint(x: w * 0.86, y: water + h * 0.1), radius: pad * 1.25, notch: 2.6)
            drawPad(in: &context, center: CGPoint(x: w * 0.68, y: water + h * 0.025), radius: pad * 0.6, notch: 1.9)
            drawPad(in: &context, center: CGPoint(x: w * 0.3, y: water + h * 0.02), radius: pad * 0.5, notch: 2.2)
            drawPad(in: &context, center: CGPoint(x: w * 0.22, y: water + h * 0.2), radius: pad * 1.8, notch: 1.0)

            // Maple leaves that have fallen onto the lake, drifting, each stirring a
            // small ripple of its own.
            var rng = SeededGenerator(seed: 1531)
            for _ in 0..<7 {
                let depth = Double.random(in: 0...1, using: &rng)
                let y = water + h * (0.03 + depth * 0.3)
                let x0 = Double.random(in: 0.08...0.92, using: &rng) * w
                let drift = Double.random(in: 6...18, using: &rng)
                let phase = Double.random(in: 0...(2 * .pi), using: &rng)
                let x = x0 + sin(time * 0.12 + phase) * drift
                let size = 10 + depth * 16
                let turn = Double.random(in: -1.2...1.2, using: &rng) + sin(time * 0.08 + phase) * 0.15
                let color = MapleLeaf.fallColors[Int.random(in: 0..<MapleLeaf.fallColors.count, using: &rng)]
                let ripplePhase = (time / 5 + phase).truncatingRemainder(dividingBy: 1)
                drawRipple(in: &context, center: CGPoint(x: x, y: y), radius: size * (0.7 + ripplePhase * 1.8), fade: 1 - ripplePhase, strength: 0.6)
                drawFloatingLeaf(in: &context, at: CGPoint(x: x, y: y), size: size, angle: turn, color: color)
            }

            // Reflection of the flower in the water.
            context.drawLayer { reflection in
                reflection.clip(to: Path(CGRect(x: 0, y: water, width: w, height: h - water)))
                reflection.opacity = 0.22
                reflection.addFilter(.blur(radius: 2.5))
                reflection.translateBy(x: 0, y: base.y)
                reflection.scaleBy(x: 1, y: -0.55)
                reflection.translateBy(x: 0, y: -base.y)
                drawFlower(in: &reflection, base: base, length: length)
            }

            drawFlower(in: &context, base: base, length: length)
        }
    }

    // MARK: Flower

    /// The flower, built in 3D and projected: each row's petals stand evenly around
    /// a ring on the receptacle, each tilted outward from the center by the same
    /// angle (more as the flower opens), then seen from slightly above. Petals at
    /// the sides show edge-on, front petals lean toward the viewer, and everything
    /// is drawn back to front, so the rows interleave the way a real lotus does.
    private func drawFlower(in context: inout GraphicsContext, base: CGPoint, length: Double) {
        let o = openness
        let elevation = 0.25 // looking down at the flower, in radians

        func project(_ v: SIMD3<Double>) -> CGPoint {
            CGPoint(x: base.x + v.x, y: base.y + v.y * cos(elevation) + v.z * sin(elevation))
        }

        struct Piece {
            let depth: Double
            let draw: (inout GraphicsContext) -> Void
        }
        var pieces: [Piece] = []

        // count, rotation offset, ring radius, length, width, tilt closed → open (degrees)
        let rows: [(count: Int, offset: Double, ring: Double, length: Double, width: Double, closed: Double, open: Double)] = [
            (8, 0.12, 0.16, 1.0, 0.44, 10, 64),
            (8, 0.12 + .pi / 8, 0.1, 0.86, 0.42, 6, 44),
            (6, 0.3, 0.05, 0.66, 0.44, 3, 22),
        ]
        for row in rows {
            let tilt = (row.closed + (row.open - row.closed) * o) * .pi / 180
            let petalLength = length * row.length
            for i in 0..<row.count {
                let phi = row.offset + Double(i) * 2 * .pi / Double(row.count)
                let root = SIMD3(cos(phi) * length * row.ring, 0, sin(phi) * length * row.ring)
                let direction = SIMD3(sin(tilt) * cos(phi), -cos(tilt), sin(tilt) * sin(phi))
                let tip = root + direction * petalLength
                let start = project(root), end = project(tip)
                let dx = end.x - start.x, dy = end.y - start.y
                let projectedLength = max((dx * dx + dy * dy).squareRoot(), petalLength * 0.12)
                let angle = atan2(dx, -dy)
                // A petal's broad face points outward, so side petals read edge-on.
                let width = length * row.width * (0.35 + 0.65 * abs(sin(phi)))
                let shade = (1 - sin(phi)) / 2
                pieces.append(Piece(depth: (root.z + tip.z) / 2) { ctx in
                    drawPetal(in: &ctx, base: start, length: projectedLength, width: width, angle: angle, depth: shade)
                })
            }
        }

        // The seed pod and stamens sit at the center, between the back and front petals.
        if o > 0.1 {
            let reveal = min((o - 0.1) / 0.6, 1)
            let pod = project(SIMD3(0, -length * 0.22, 0))
            pieces.append(Piece(depth: 0) { ctx in
                drawPod(in: &ctx, center: pod, length: length, reveal: reveal)
            })
        }

        for piece in pieces.sorted(by: { $0.depth < $1.depth }) {
            piece.draw(&context)
        }
    }

    /// A golden seed pod ringed with stamens.
    private func drawPod(in context: inout GraphicsContext, center pod: CGPoint, length: Double, reveal: Double) {
        for i in 0..<22 {
            let a = Double(i) / 22 * 2 * .pi
            var stamen = Path()
            stamen.move(to: CGPoint(x: pod.x + cos(a) * length * 0.05, y: pod.y + length * 0.05))
            stamen.addLine(to: CGPoint(x: pod.x + cos(a) * length * 0.17, y: pod.y - length * 0.03 + sin(a) * length * 0.025))
            context.stroke(stamen, with: .color(Color(red: 1, green: 0.82, blue: 0.3).opacity(0.85 * reveal)), lineWidth: 0.8)
        }
        let podRect = CGRect(x: pod.x - length * 0.11, y: pod.y - length * 0.04, width: length * 0.22, height: length * 0.09)
        context.fill(Path(ellipseIn: podRect), with: .linearGradient(
            Gradient(colors: [Color(red: 0.95, green: 0.88, blue: 0.45).opacity(reveal), Color(red: 0.72, green: 0.7, blue: 0.25).opacity(reveal)]),
            startPoint: CGPoint(x: podRect.midX, y: podRect.minY), endPoint: CGPoint(x: podRect.midX, y: podRect.maxY)
        ))
        for i in 0..<7 {
            let a = Double(i) / 7 * 2 * .pi
            let dot = CGPoint(x: pod.x + cos(a) * length * 0.06, y: pod.y + sin(a) * length * 0.016)
            context.fill(Path(ellipseIn: CGRect(x: dot.x - 1.2, y: dot.y - 0.9, width: 2.4, height: 1.8)),
                                      with: .color(Color(red: 0.45, green: 0.42, blue: 0.12).opacity(reveal)))
        }
    }

    /// One petal: blush gradient from base to tip, shaded across its width for the
    /// cupped curve, with fine veins and a soft edge. `depth` 1 sits furthest back
    /// and is a little deeper in color.
    private func drawPetal(in context: inout GraphicsContext, base: CGPoint, length: Double, width: Double, angle: Double, depth: Double) {
        let petal = petalPath(length: length, width: width, angle: angle, base: base)
        let tip = point(at: 1, across: 0, length: length, width: width, angle: angle, base: base)
        let tipColor = Self.rose.opacity(0.85 + 0.15 * depth)

        context.fill(petal, with: .linearGradient(
            Gradient(stops: [
                .init(color: Self.cream, location: 0),
                .init(color: Self.blush, location: 0.55 - 0.15 * depth),
                .init(color: tipColor, location: 1),
            ]),
            startPoint: base, endPoint: tip
        ))

        // Curvature: shadow on one side, light catching the other.
        let left = point(at: 0.5, across: -1, length: length, width: width, angle: angle, base: base)
        let right = point(at: 0.5, across: 1, length: length, width: width, angle: angle, base: base)
        context.fill(petal, with: .linearGradient(
            Gradient(colors: [.black.opacity(0.22 + 0.1 * depth), .clear, .white.opacity(0.18)]),
            startPoint: left, endPoint: right
        ))

        // Veins fanning from the base.
        for across in [-0.55, -0.25, 0.0, 0.25, 0.55] {
            var vein = Path()
            vein.move(to: base)
            vein.addQuadCurve(
                to: point(at: 0.9, across: across * 0.4, length: length, width: width, angle: angle, base: base),
                control: point(at: 0.45, across: across, length: length, width: width, angle: angle, base: base)
            )
            context.stroke(vein, with: .color(Self.rose.opacity(0.16)), lineWidth: 0.5)
        }

        context.stroke(petal, with: .color(Self.rose.opacity(0.35)), lineWidth: 0.7)
    }

    /// A cupped lotus petal: broad belly, pointed tip, base at the origin pointing
    /// up, turned by `angle` (0 is straight up) and placed at `base`.
    private func petalPath(length: Double, width: Double, angle: Double, base: CGPoint) -> Path {
        var petal = Path()
        petal.move(to: .zero)
        petal.addCurve(to: CGPoint(x: 0, y: -length),
                                      control1: CGPoint(x: width * 1.05, y: -length * 0.22),
                                      control2: CGPoint(x: width * 0.5, y: -length * 0.88))
        petal.addCurve(to: .zero,
                                      control1: CGPoint(x: -width * 0.5, y: -length * 0.88),
                                      control2: CGPoint(x: -width * 1.05, y: -length * 0.22))
        petal.closeSubpath()
        return petal.applying(
            CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: base.x, y: base.y))
        )
    }

    /// A point on the petal: `along` 0 at the base to 1 at the tip, `across`
    /// -1 (left edge) to 1 (right edge) of the belly.
    private func point(at along: Double, across: Double, length: Double, width: Double, angle: Double, base: CGPoint) -> CGPoint {
        let x = across * width * 0.55 * sin(.pi * min(along, 0.95))
        let y = -length * along
        return CGPoint(x: base.x + x * cos(angle) - y * sin(angle), y: base.y + x * sin(angle) + y * cos(angle))
    }

    // MARK: Water

    /// One ring of a ripple seen at a low angle: a light crest with a darker trough
    /// just inside it.
    private func drawRipple(in context: inout GraphicsContext, center: CGPoint, radius: Double, fade: Double, strength: Double) {
        let squash = 0.16
        let crest = CGRect(x: center.x - radius, y: center.y - radius * squash, width: radius * 2, height: radius * 2 * squash)
        let trough = crest.insetBy(dx: 3, dy: 3 * squash)
        context.stroke(Path(ellipseIn: trough), with: .color(.black.opacity(0.25 * fade * strength)), lineWidth: 2)
        context.stroke(Path(ellipseIn: crest), with: .color(Color(red: 0.75, green: 0.9, blue: 1).opacity(0.22 * fade * strength)), lineWidth: 1.2)
    }

    /// A maple leaf lying on the water, foreshortened by the angle of view.
    private func drawFloatingLeaf(in context: inout GraphicsContext, at point: CGPoint, size: Double, angle: Double, color: Color) {
        var leaf = context
        leaf.translateBy(x: point.x, y: point.y)
        leaf.scaleBy(x: 1, y: 0.42)
        leaf.rotate(by: .radians(angle))
        let path = MapleLeaf().path(in: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
        leaf.fill(path, with: .color(color.opacity(0.92)))
        leaf.stroke(path, with: .color(.black.opacity(0.25)), lineWidth: 0.5)
    }

    // MARK: Pads

    /// A lily pad lying flat on the water, seen in perspective, with its notch.
    private func drawPad(in context: inout GraphicsContext, center: CGPoint, radius: Double, notch: Double) {
        var pad = Path()
        pad.move(to: .zero)
        let gap = 0.22
        let steps = 48
        for i in 0...steps {
            let a = notch + gap + (2 * .pi - 2 * gap) * Double(i) / Double(steps)
            pad.addLine(to: CGPoint(x: cos(a) * radius, y: sin(a) * radius))
        }
        pad.closeSubpath()
        let squash = CGAffineTransform(scaleX: 1, y: 0.24).concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        let shape = pad.applying(squash)
        context.fill(shape, with: .linearGradient(
            Gradient(colors: [Color(red: 0.16, green: 0.38, blue: 0.22), Color(red: 0.05, green: 0.17, blue: 0.1)]),
            startPoint: CGPoint(x: center.x, y: center.y - radius * 0.24), endPoint: CGPoint(x: center.x, y: center.y + radius * 0.24)
        ))
        for i in 0..<9 {
            let a = notch + gap + (2 * .pi - 2 * gap) * Double(i) / 8
            var vein = Path()
            vein.move(to: center)
            vein.addLine(to: CGPoint(x: center.x + cos(a) * radius * 0.92, y: center.y + sin(a) * radius * 0.92 * 0.24))
            context.stroke(vein, with: .color(Color(red: 0.3, green: 0.55, blue: 0.35).opacity(0.35)), lineWidth: 0.5)
        }
        context.stroke(shape, with: .color(Color(red: 0.3, green: 0.6, blue: 0.38).opacity(0.5)), lineWidth: 0.7)
    }
}

// MARK: - Night sky and water

/// A still field of stars, fewer and fainter toward the horizon.
struct Stars: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: 4242)
            for _ in 0..<160 {
                let y = pow(Double.random(in: 0...1, using: &rng), 1.6) * size.height
                let x = Double.random(in: 0...size.width, using: &rng)
                let r = Double.random(in: 0.4...1.6, using: &rng)
                let alpha = Double.random(in: 0.15...0.8, using: &rng) * (1 - y / size.height * 0.7)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Glints of light drifting across the lake's surface.
struct WaterShimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)
            Canvas { context, size in
                var rng = SeededGenerator(seed: 777)
                for _ in 0..<70 {
                    let depth = pow(Double.random(in: 0...1, using: &rng), 1.4)
                    let y = depth * size.height
                    let x0 = Double.random(in: 0...size.width, using: &rng)
                    let drift = Double.random(in: 4...12, using: &rng)
                    let phase = Double.random(in: 0...(2 * .pi), using: &rng)
                    let width = (6 + depth * 30) * Double.random(in: 0.6...1.2, using: &rng)
                    let twinkle = 0.5 + 0.5 * sin(time * Double.random(in: 0.6...1.4, using: &rng) + phase)
                    let x = x0 + sin(time * 0.3 + phase) * drift
                    let green = Double.random(in: 0...1, using: &rng) > 0.6
                    let color = green ? Color(red: 0.45, green: 1, blue: 0.75) : Color(red: 0.75, green: 0.85, blue: 1)
                    var streak = Path()
                    streak.move(to: CGPoint(x: x - width / 2, y: y))
                    streak.addLine(to: CGPoint(x: x + width / 2, y: y))
                    context.stroke(streak, with: .color(color.opacity(0.18 * twinkle * (1 - depth * 0.5))), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("Aurora Lake") {
    AuroraLakeScene(openness: 0.8, time: 2).ignoresSafeArea()
}
