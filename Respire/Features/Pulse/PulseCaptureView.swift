//
//  PulseCaptureView.swift
//  Respire
//

import SwiftUI

/// Guides the user through a 5-second fingertip pulse reading before a session.
struct PulseCaptureView: View {
    var onComplete: (PulseReading) -> Void

    @State private var model = PulseCaptureModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer(minLength: 0)
                indicator
                instructions
                Spacer(minLength: 0)
                actions
            }
            .padding(Theme.Space.xl)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paperBackground()
            .navigationTitle("Resting Pulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear { model.begin() }
        .onDisappear { model.cancel() }
        .sensoryFeedback(trigger: model.stage) { _, newStage in
            switch newStage {
            case .result: .success
            case .failed: .error
            case .measuring: .impact(weight: .light)
            default: nil
            }
        }
    }

    // MARK: - Sections

    private var indicator: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .background { IceGlass(shape: Circle(), frost: false) }
            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(Theme.Palette.pulse, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .shadow(color: Theme.Palette.pulse.opacity(0.6), radius: 8)
                .padding(3)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: model.progress)

            switch model.stage {
            case .result(let reading):
                VStack(spacing: 0) {
                    Text(reading.beatsPerMinute.formatted())
                        .font(.system(size: 64, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.ink)
                    Text("BPM")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.pulse)
                }
            case .measuring:
                PulseWaveform(samples: model.liveWaveform)
                    .stroke(Theme.Palette.pulse, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .padding(40)
            default:
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .symbolEffect(.pulse, isActive: model.stage == .placeFinger)
            }
        }
        .frame(width: 220, height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Measurement progress")
        .accessibilityValue(Text(model.progress, format: .percent.precision(.fractionLength(0))))
    }

    private var instructions: some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.system(.title, design: .serif))
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(Theme.Typography.note)
                .lineSpacing(Theme.Typography.noteLineSpacing)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var actions: some View {
        switch model.stage {
        case .result(let reading):
            VStack(spacing: Theme.Space.xs) {
                Button {
                    onComplete(reading)
                    dismiss()
                } label: {
                    Text("Use as baseline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)

                Button("Measure again") { model.begin() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
            }
        case .failed:
            Button {
                model.begin()
            } label: {
                Text("Try again")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pill)
        default:
            EmptyView()
        }
    }

    // MARK: - Copy

    private var headline: String {
        switch model.stage {
        case .idle, .requestingAccess: "Preparing camera"
        case .placeFinger: "Cover the camera"
        case .measuring: "Hold still"
        case .result(let reading): reading.confidence < PulseSignalAnalyzer.highConfidence ? "Approximate reading" : "Baseline captured"
        case .failed: "No reading"
        }
    }

    private var detail: String {
        switch model.stage {
        case .idle, .requestingAccess:
            "Respire uses the rear camera and flash to see the color change in your fingertip with each heartbeat."
        case .placeFinger:
            "Rest a fingertip lightly over the rear camera and flash. Don't press — just cover it completely."
        case .measuring:
            "Breathe normally. Measuring for \(Int(model.measurementDuration)) seconds…"
        case .result:
            "This is a resting estimate for tracking calm over time, not a medical measurement."
        case .failed(let message):
            message
        }
    }
}

/// Draws a normalized (-1...1) waveform across its bounds.
struct PulseWaveform: Shape {
    var samples: [Double]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard samples.count > 1 else { return }
            let step = rect.width / CGFloat(samples.count - 1)
            for (index, sample) in samples.enumerated() {
                let point = CGPoint(
                    x: rect.minX + CGFloat(index) * step,
                    y: rect.midY - CGFloat(sample) * rect.height / 2
                )
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PulseCaptureView { _ in }
        }
        .preferredColorScheme(.dark)
}
