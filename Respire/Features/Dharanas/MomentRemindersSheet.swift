//
//  MomentRemindersSheet.swift
//  Respire
//
//  Turn on a gentle daily reminder for waking, between tasks, or before bed, each
//  with the gate written for that moment, and choose its time.
//

import SwiftUI
import UIKit

struct MomentRemindersSheet: View {
    @Environment(MomentReminders.self) private var reminders
    @Environment(DharanaLibrary.self) private var gates
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    Text("A quiet nudge at the thresholds of the day, each carrying the gate written for that moment. Scheduled on this device; tap one to open its gate.")
                        .font(Theme.Typography.meta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if reminders.authorization == .denied {
                        VStack(alignment: .leading, spacing: Theme.Space.xs) {
                            Label("Notifications are off for Respire", systemImage: "bell.slash")
                                .font(Theme.Typography.label)
                                .foregroundStyle(Theme.Palette.ink)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                            }
                            .font(Theme.Typography.label)
                            .foregroundStyle(Theme.Palette.accent)
                            .frame(minHeight: Theme.minTapTarget)
                        }
                        .card(padding: Theme.Space.m)
                    }

                    ForEach(Moment.allCases) { moment in
                        row(for: moment)
                    }
                }
                .padding(Theme.Space.page)
            }
            .background(Theme.Palette.paper)
            .navigationTitle("Moments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await reminders.refreshAuthorization() }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(for moment: Moment) -> some View {
        let gate = gates.dharana(number: moment.gate)
        let setting = reminders.setting(for: moment)

        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            Toggle(isOn: Binding(
                get: { setting.isEnabled },
                set: { isOn in Task { await reminders.setEnabled(isOn, for: moment, gate: gate) } }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(moment.title, systemImage: moment.symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    if let gate {
                        Text("Gate \(gate.number) · \(gate.title)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.prism[5])
                    }
                    Text(moment.explanation)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.prism[3])

            if setting.isEnabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { reminders.time(for: moment) },
                        set: { date in Task { await reminders.setTime(date, for: moment, gate: gate) } }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card(padding: Theme.Space.m)
        .animation(.easeInOut(duration: 0.25), value: setting.isEnabled)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            MomentRemindersSheet()
        }
        .environment(MomentReminders(defaults: UserDefaults(suiteName: "preview.moments")!))
        .environment(DharanaLibrary())
        .preferredColorScheme(.dark)
}
