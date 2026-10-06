//
//  PatternEditorView.swift
//  Respire
//

import SwiftUI

/// Edits the durations of a custom rhythm. Holds may be zero; inhale and exhale need at least 1 s.
struct PatternEditorView: View {
    @Binding var pattern: BreathPattern
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    durationStepper("Inhale", value: $pattern.inhale, minimum: 1)
                    durationStepper("Hold (full)", value: $pattern.holdFull, minimum: 0)
                    durationStepper("Exhale", value: $pattern.exhale, minimum: 1)
                    durationStepper("Hold (empty)", value: $pattern.holdEmpty, minimum: 0)
                } header: {
                    BreathShape(pattern: pattern, isLive: true)
                        .frame(height: 56)
                        .textCase(nil)
                } footer: {
                    Text("\(pattern.rhythmLabel) — \(pattern.breathsPerMinute.formatted(.number.precision(.fractionLength(1)))) breaths per minute")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.paper)
            .navigationTitle("Custom Rhythm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func durationStepper(_ title: String, value: Binding<TimeInterval>, minimum: TimeInterval) -> some View {
        Stepper(value: value, in: minimum...BreathPattern.durationRange.upperBound, step: 0.5) {
            LabeledContent(title) {
                Text("\(value.wrappedValue.formatted(.number.precision(.fractionLength(0...1)))) s")
                    .monospacedDigit()
            }
        }
    }
}
