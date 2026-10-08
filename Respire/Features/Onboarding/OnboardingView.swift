//
//  OnboardingView.swift
//  Respire
//
//  Three short screens on first launch: what you'd like help with, how sessions
//  work with your eyes closed, and one optional daily reminder. Every choice can be
//  changed later in Settings.
//

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(MomentReminders.self) private var reminders
    @Environment(DharanaLibrary.self) private var gates
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(SessionFocus.storageKey) private var focus: SessionFocus = .calmAnxiety
    @AppStorage(VoiceGuide.storageKey) private var spokenGuidance = true
    @AppStorage(Soundscape.guideKey) private var breathSound = true

    @State private var page = 0
    @State private var moment: Moment?
    @State private var start = Date.now

    private static let pageCount = 3

    var body: some View {
        ZStack {
            // The aurora, swaying slowly, behind a deep shade so the words read.
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSince(start)
                BreathWorldScene(theme: .aurora, openness: 0.35 + 0.15 * sin(time * 0.4), time: time)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Space.l) {
                PageDots(page: page, count: Self.pageCount)
                    .padding(.top, Theme.Space.l)
                Spacer(minLength: 0)
                Group {
                    switch page {
                    case 0: focusPage
                    case 1: eyesClosedPage
                    default: reminderPage
                    }
                }
                .id(page)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
                Spacer(minLength: 0)
                footer
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, Theme.Space.page)
            .padding(.bottom, Theme.Space.l)
        }
        .animation(.easeInOut(duration: 0.4), value: page)
    }

    // MARK: - Pages

    private var focusPage: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            heading("Welcome to Respire.",
                    "Short guided breathing and meditation. What would you like help with?")
            VStack(spacing: Theme.Space.xs) {
                ForEach(SessionFocus.allCases) { option in
                    choice(option.title, detail: option.recommendedPattern.summary, symbol: option.symbol,
                           isSelected: option == focus) { focus = option }
                }
            }
        }
    }

    private var reminderPage: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            heading("A daily reminder?",
                    "One gentle nudge a day helps make it a habit. Choose a time, or skip this.")
            VStack(spacing: Theme.Space.xs) {
                ForEach(Moment.allCases) { option in
                    choice(option.title, detail: option.explanation, symbol: option.symbol,
                           isSelected: option == moment) { moment = option == moment ? nil : option }
                }
            }
        }
    }

    private var eyesClosedPage: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            heading("You can close your eyes.",
                    "A calm voice settles you in, then a soft breath sound guides you: breathe in as it rises, and out as it fades. At the end, a bell and the voice bring you back.")
            choice("Spoken guidance", detail: "A voice at the start and end, and a few quiet words along the way.",
                   symbol: "person.wave.2", isSelected: spokenGuidance) { spokenGuidance.toggle() }
            choice("Breath sound", detail: "Soft air that follows each breath. No music, no beats.",
                   symbol: "wind", isSelected: breathSound) { breathSound.toggle() }
        }
    }

    // MARK: - Pieces

    private var footer: some View {
        HStack(spacing: Theme.Space.s) {
            if page > 0 {
                Button("Back") { page -= 1 }
                    .font(Theme.Typography.label)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
            }
            Spacer()
            Button {
                advance()
            } label: {
                Text(page == Self.pageCount - 1 ? "Start" : "Continue")
            }
            .buttonStyle(.pill)
            .spectralEdge()
        }
    }

    private func advance() {
        if page == 2, let moment {
            let gate = gates.collection?.dharana(number: moment.gate)
            Task { await reminders.setEnabled(true, for: moment, gate: gate) }
        }
        if page < Self.pageCount - 1 {
            page += 1
        } else {
            onFinish()
        }
    }

    private func heading(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(title)
                .font(Theme.Typography.instruction)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(Theme.Typography.note)
                .lineSpacing(Theme.Typography.noteLineSpacing)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// A row of glass with an icon, a title, a line of detail, and a check when chosen.
    private func choice(_ title: String, detail: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        return Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 32)
                    .foregroundStyle(Theme.Palette.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(detail)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.inkTertiary)
            }
            .multilineTextAlignment(.leading)
            .padding(Theme.Space.s)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
            .background {
                IceGlass(shape: shape, frost: false)
                shape.fill(Theme.Palette.card.opacity(0.82))
            }
            .overlay {
                if isSelected { shape.strokeBorder(Theme.Palette.ink.opacity(0.6), lineWidth: 1.5) }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Where you are among the onboarding screens.
private struct PageDots: View {
    let page: Int
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(index == page ? 0.95 : 0.35))
                    .frame(width: index == page ? 22 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: page)
        .accessibilityElement()
        .accessibilityLabel("Step \(page + 1) of \(count)")
    }
}

#Preview {
    OnboardingView { }
        .environment(SessionViewModel())
        .environment(MomentReminders())
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
