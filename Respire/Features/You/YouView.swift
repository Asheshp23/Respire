//
//  YouView.swift
//  Respire
//
//  Your practice, opened from the week strip on the home: the last seven days as quiet
//  dots, sessions and minutes, and what you've breathed lately. No streaks to break; a
//  missed day is just a day.
//

import SwiftUI

struct YouView: View {
    @Environment(SessionViewModel.self) private var session

    private var history: SessionHistory { session.history }

    var body: some View {
        List {
            Section {
                WeekSummary(history: history)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section("Recently") {
                if history.entries.isEmpty {
                    Text("Your sessions will appear here.")
                        .font(Theme.Typography.note)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                } else {
                    ForEach(history.entries.prefix(6)) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Theme.Palette.ink)
                                Text(entry.date.formatted(.relative(presentation: .named)))
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Palette.inkSecondary)
                            }
                            Spacer()
                            Text("\(entry.minutes) min")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Theme.Palette.inkSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

        }
        .scrollContentBackground(.hidden)
        .paperBackground()
        .navigationTitle("Your practice")
    }
}

/// The last seven days: a dot for each, filled when you breathed, and the week's totals.
private struct WeekSummary: View {
    let history: SessionHistory

    var body: some View {
        let week = history.week()
        let totals = history.lastSevenDays()
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)

        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("This week")
                .font(Theme.Typography.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.inkTertiary)

            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.l) {
                stat(totals.sessions, totals.sessions == 1 ? "session" : "sessions")
                stat(totals.minutes, totals.minutes == 1 ? "minute" : "minutes")
            }

            HStack(spacing: 0) {
                ForEach(week, id: \.day) { day in
                    VStack(spacing: Theme.Space.xs) {
                        Circle()
                            .fill(day.practiced ? Theme.prism[3] : Theme.Palette.inkTertiary.opacity(0.25))
                            .frame(width: 14, height: 14)
                        Text(day.day.formatted(.dateTime.weekday(.narrow)))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Palette.inkTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.day.formatted(.dateTime.weekday(.wide))), \(day.practiced ? "breathed" : "rest")")
                }
            }

            Text(totals.sessions == 0
                 ? "Whenever you're ready. A minute is enough."
                 : "Every breath counts. There's no streak to keep.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .padding(Theme.Space.l)
        .background { IceGlass(shape: shape, frost: false) }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)")
                .font(.system(.largeTitle, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.ink)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { YouView() }
        .environment(SessionViewModel())
        .environment(MomentReminders())
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
