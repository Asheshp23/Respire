//
//  BreathShape.swift
//  Respire
//
//  One breath drawn as a line: up for the in-breath, level for the hold, down for
//  the out-breath, level for the rest. On the chosen rhythm a point of light
//  travels it in real time.
//

import SwiftUI

extension BreathPattern {
    /// Each rhythm takes a hue from the prism, so it's recognizable everywhere it appears.
    var hue: Color {
        switch id {
        case BreathPattern.box.id: Theme.prism[4]
        case BreathPattern.relaxing478.id: Theme.prism[6]
        case BreathPattern.coherent.id: Theme.prism[3]
        default: Theme.prism[1]
        }
    }

    /// Lung volume (0...1) at `t` seconds into one cycle, using the engine's own easing.
    func openness(at t: TimeInterval) -> Double {
        var remaining = min(max(t, 0), cycleDuration)
        for phase in BreathPhase.allCases {
            let duration = duration(of: phase)
            guard duration > 0 else { continue }
            if remaining <= duration {
                return BreathEngine.lungVolume(for: phase, progress: remaining / duration)
            }
            remaining -= duration
        }
        return 0
    }
}

struct BreathShape: View {
    let pattern: BreathPattern
    var isLive = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: !isLive || reduceMotion)) { timeline in
            Canvas { context, size in
                let inset = 6.0
                let width = size.width - inset * 2
                let top = inset, bottom = size.height - inset
                let cycle = max(pattern.cycleDuration, 0.1)
                let hue = pattern.hue

                func point(at t: Double) -> CGPoint {
                    CGPoint(x: inset + width * t / cycle, y: bottom - (bottom - top) * pattern.openness(at: t))
                }

                var line = Path()
                line.move(to: point(at: 0))
                for step in 1...80 {
                    line.addLine(to: point(at: cycle * Double(step) / 80))
                }
                // A soft glow under the line, then the line itself.
                var fill = line
                fill.addLine(to: CGPoint(x: inset + width, y: bottom))
                fill.addLine(to: CGPoint(x: inset, y: bottom))
                fill.closeSubpath()
                context.fill(fill, with: .linearGradient(Gradient(colors: [hue.opacity(0.25), .clear]),
                                                         startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: bottom)))
                context.stroke(line, with: .color(hue.opacity(0.9)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if isLive {
                    let t = reduceMotion ? pattern.inhale : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
                    let dot = point(at: t)
                    context.fill(Path(ellipseIn: CGRect(x: dot.x - 9, y: dot.y - 9, width: 18, height: 18)),
                                 with: .radialGradient(Gradient(colors: [hue.opacity(0.7), .clear]), center: dot, startRadius: 0, endRadius: 9))
                    context.fill(Path(ellipseIn: CGRect(x: dot.x - 3.5, y: dot.y - 3.5, width: 7, height: 7)), with: .color(.white))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
