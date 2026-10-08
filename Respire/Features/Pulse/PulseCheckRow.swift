//
//  PulseCheckRow.swift
//  Respire
//
//  After a session: an optional second pulse reading, set beside the one taken
//  before ("84 → 76 BPM"), so the body's response is something you can see.
//  Described plainly, never judged.
//

import SwiftUI

struct PulseCheckRow: View {
    @Environment(SessionViewModel.self) private var session
    @State private var isMeasuring = false

    var body: some View {
        Button {
            isMeasuring = true
        } label: {
            HStack(spacing: Theme.Space.s) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.Palette.pulse)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.ink)
                        .monospacedDigit()
                    Text(detail)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer(minLength: 0)
                if session.afterReading == nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
            }
            .frame(minHeight: Theme.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(session.afterReading != nil)
        .sheet(isPresented: $isMeasuring) {
            PulseCaptureView { reading in
                session.afterReading = reading
            }
        }
    }

    private var title: String {
        switch (session.baseline, session.afterReading) {
        case let (before?, after?): "\(before.beatsPerMinute) → \(after.beatsPerMinute) BPM"
        case let (nil, after?): "\(after.beatsPerMinute) BPM now"
        default: "Check your pulse now"
        }
    }

    private var detail: String {
        switch (session.baseline, session.afterReading) {
        case let (before?, after?):
            let change = after.beatsPerMinute - before.beatsPerMinute
            return change < 0 ? "Your pulse settled by \(-change) beats a minute." :
                (change == 0 ? "Your pulse held steady." : "Your pulse is \(change) beats quicker; that's fine too.")
        case (_, .some): return "Measure before your next session to compare."
        case let (before?, nil): return "Compare with \(before.beatsPerMinute) BPM before you began."
        case (nil, nil): return "Five seconds with a fingertip on the camera."
        }
    }
}
