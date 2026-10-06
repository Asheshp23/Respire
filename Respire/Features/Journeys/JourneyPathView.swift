//
//  JourneyPathView.swift
//  Respire
//
//  The journey as a winding trail: one node per day, swinging left and right down
//  the page, joined by a soft curve that lights up in the prism's colors as days
//  are completed. Each row is one big tap target (node and label together), so
//  it's easy to hit with a thumb or a finger on iPad.
//

import SwiftUI

struct JourneyPathView: View {
    let journey: Journey
    let states: [ChapterState]
    var selectedID: JourneyChapter.ID?
    var onSelect: (JourneyChapter) -> Void

    static let rowHeight: CGFloat = 128
    static let nodeSize: CGFloat = 64
    private static let verticalInset: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            let points = Self.points(count: journey.chapters.count, width: proxy.size.width)

            ZStack(alignment: .topLeading) {
                Trail(points: points, litSegments: litSegments)
                    .allowsHitTesting(false)

                ForEach(Array(journey.chapters.enumerated()), id: \.element.id) { index, chapter in
                    row(for: chapter, at: index, point: points[index], width: proxy.size.width)
                }
            }
        }
        .frame(height: CGFloat(journey.chapters.count) * Self.rowHeight + Self.verticalInset * 2)
    }

    /// Segment `i` joins day `i` and day `i + 1`; it's lit once day `i` is complete.
    private var litSegments: Int {
        states.prefix { $0.isCompleted }.count
    }

    static func hue(for index: Int, in journey: Journey) -> Color {
        Theme.prism[(journey.hue + index) % Theme.prism.count]
    }

    /// Node centers alternate either side of the middle; the swing narrows on slim widths.
    static func points(count: Int, width: CGFloat) -> [CGPoint] {
        let swing = min(width * 0.22, 120)
        return (0..<count).map { index in
            CGPoint(
                x: width / 2 + (index.isMultiple(of: 2) ? -swing : swing),
                y: verticalInset + rowHeight * (CGFloat(index) + 0.5)
            )
        }
    }

    // MARK: - Rows

    private func row(for chapter: JourneyChapter, at index: Int, point: CGPoint, width: CGFloat) -> some View {
        let state = states[index]
        let isLeading = point.x < width / 2
        let node = JourneyNode(
            day: chapter.day,
            state: state,
            hue: Self.hue(for: index, in: journey),
            isSelected: chapter.id == selectedID
        )
        let label = NodeLabel(chapter: chapter, state: state, previousDay: index > 0 ? journey.chapters[index - 1].day : nil, isLeading: isLeading)
            .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)

        return Button {
            onSelect(chapter)
        } label: {
            HStack(spacing: Theme.Space.s) {
                if isLeading {
                    node
                    label
                } else {
                    label
                    node
                }
            }
            // Pin the node's center to its point on the trail.
            .padding(.leading, isLeading ? point.x - Self.nodeSize / 2 : Theme.Space.m)
            .padding(.trailing, isLeading ? Theme.Space.m : width - point.x - Self.nodeSize / 2)
            .frame(width: width, height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(x: width / 2, y: point.y)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(chapter.day), \(chapter.title). \(NodeLabel.status(for: state, previousDay: index > 0 ? journey.chapters[index - 1].day : nil))")
        .accessibilityHint(chapter.tagline)
        .accessibilityAddTraits(chapter.id == selectedID ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Trail

/// The path between nodes: a faint dashed line ahead, prism light behind.
private struct Trail: View {
    let points: [CGPoint]
    let litSegments: Int

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else { return }

            func segment(_ index: Int) -> Path {
                let a = points[index], b = points[index + 1]
                let bend = (b.y - a.y) * 0.55
                var path = Path()
                path.move(to: a)
                path.addCurve(to: b, control1: CGPoint(x: a.x, y: a.y + bend), control2: CGPoint(x: b.x, y: b.y - bend))
                return path
            }

            var ahead = Path()
            var behind = Path()
            for index in 0..<(points.count - 1) {
                if index < litSegments { behind.addPath(segment(index)) } else { ahead.addPath(segment(index)) }
            }

            context.stroke(ahead, with: .color(.white.opacity(0.2)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 9]))

            let light = GraphicsContext.Shading.linearGradient(
                Gradient(colors: Theme.prism),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
            )
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 6))
                glow.opacity = 0.7
                glow.stroke(behind, with: light, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            }
            context.stroke(behind, with: light, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

// MARK: - Node

struct JourneyNode: View {
    let day: Int
    let state: ChapterState
    let hue: Color
    var isSelected = false

    @State private var isBreathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size = JourneyPathView.nodeSize

    var body: some View {
        ZStack {
            if state == .available {
                // The open gate breathes: a prism halo that swells and fades.
                Circle()
                    .stroke(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 3)
                    .scaleEffect(isBreathing ? 1.35 : 1.08)
                    .opacity(isBreathing ? 0 : 0.9)
            }

            switch state {
            case .completed:
                Circle()
                    .fill(hue.gradient)
                    .shadow(color: hue.opacity(0.6), radius: 12)
                Image(systemName: "checkmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            case .available:
                Circle()
                    .fill(Theme.Palette.ink)
                Text("\(day)")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.Palette.onInk)
            case .opensTomorrow:
                IceGlass(shape: Circle(), frost: false)
                Image(systemName: "sunrise")
                    .font(.title3)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            case .locked:
                IceGlass(shape: Circle(), frost: false)
                    .opacity(0.7)
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }

            if isSelected {
                Circle()
                    .strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 2.5)
                    .padding(-7)
            }
        }
        .frame(width: size, height: size)
        .onAppear { startBreathing() }
        .onChange(of: state) { _, _ in startBreathing() }
    }

    private func startBreathing() {
        guard state == .available, !reduceMotion else { return }
        isBreathing = false
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: false)) {
            isBreathing = true
        }
    }
}

// MARK: - Label

private struct NodeLabel: View {
    let chapter: JourneyChapter
    let state: ChapterState
    let previousDay: Int?
    /// Labels beside a left-hand node read left-aligned; beside a right-hand node, right-aligned toward it.
    let isLeading: Bool

    var body: some View {
        VStack(alignment: isLeading ? .leading : .trailing, spacing: 3) {
            Text("Day \(chapter.day) · \(Self.status(for: state, previousDay: previousDay))")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(state == .available ? Theme.Palette.ink : Theme.Palette.inkTertiary)
            Text(chapter.title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(state == .locked ? Theme.Palette.inkSecondary : Theme.Palette.ink)
            Text(chapter.tagline)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .lineLimit(2)
        }
        .multilineTextAlignment(isLeading ? .leading : .trailing)
    }

    static func status(for state: ChapterState, previousDay: Int?) -> String {
        switch state {
        case .completed(let date):
            "Done \(date.formatted(.dateTime.month(.abbreviated).day()))"
        case .available:
            "Open"
        case .opensTomorrow:
            "Opens tomorrow"
        case .locked:
            previousDay.map { "After day \($0)" } ?? "Waiting"
        }
    }
}
