//
//  GuidedPracticeView.swift
//  Respire
//
//  A session with a purpose: a Journey day or one of the 112 Gates. It plays the
//  regular session in a given world, rhythm, and focus, sized to a number of
//  cycles. When the session finishes it reports completion and shows a card over
//  the world. The breath engine is restored to open-ended play on the way out.
//

import SwiftUI

struct GuidedPracticeView<Completion: View>: View {
    let pattern: BreathPattern
    let cycles: Int
    let world: BreathTheme
    let focus: SessionFocus
    let title: String
    let guidance: String
    /// The gate being practiced, woven into the opening.
    var gate: Dharana? = nil
    var onComplete: () -> Void
    /// The card shown once the session finishes; it receives an action that leaves the practice.
    @ViewBuilder var completion: (_ leave: @escaping () -> Void) -> Completion

    @Environment(SessionViewModel.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var isComplete = false

    var body: some View {
        SessionView(world: world, focus: focus, title: title, guidance: guidance, gate: gate)
            .overlay {
                if isComplete {
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { dismiss() }
                        completion { dismiss() }
                            .frame(maxWidth: 520)
                            .padding(Theme.Space.page)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                session.select(pattern)
                session.engine.targetCycles = cycles
            }
            .onDisappear {
                session.stop()
                session.engine.targetCycles = nil
            }
            .onChange(of: session.engine.state) { _, state in
                guard state == .finished else { return }
                onComplete()
                withAnimation(.easeInOut(duration: 0.6)) { isComplete = true }
            }
            .sensoryFeedback(.success, trigger: isComplete) { _, done in done }
    }
}

/// The shared look of a completion card: an eyebrow, a title, a few lines, then actions.
struct CompletionCard<Content: View>: View {
    let eyebrow: String
    let hue: Color
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(eyebrow)
                    .font(Theme.Typography.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(hue)
                Text(title)
                    .font(.system(.title, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .card(padding: Theme.Space.l)
    }
}
