//
//  PulseCaptureModel.swift
//  Respire
//

import AVFoundation
import Foundation
import Observation

/// Drives the pre-session resting-pulse baseline:
/// permission → place fingertip → settle → 5 s of continuous coverage → analyze.
/// Lifting the finger at any point restarts the 5 s window so the reading is never stitched together.
@Observable
final class PulseCaptureModel {
    enum Stage: Equatable {
        case idle
        case requestingAccess
        case placeFinger
        case measuring
        case result(PulseReading)
        case failed(String)
    }

    private(set) var stage: Stage = .idle
    /// 0...1 progress through the measurement window.
    private(set) var progress: Double = 0
    /// Rolling cleaned waveform for live visual feedback.
    private(set) var liveWaveform: [Double] = []

    let measurementDuration: TimeInterval = 5
    /// Auto-exposure and capillary refill need a moment after the finger lands before data is usable.
    private let settleDuration: TimeInterval = 0.8
    private let liveWindow: TimeInterval = 3

    @ObservationIgnored private let pipeline = CameraPPGPipeline()
    @ObservationIgnored private var captureTask: Task<Void, Never>?

    var latestReading: PulseReading? {
        if case .result(let reading) = stage { reading } else { nil }
    }

    // MARK: - Control

    func begin() {
        captureTask?.cancel()
        progress = 0
        liveWaveform = []
        captureTask = Task { await run() }
    }

    func cancel() {
        captureTask?.cancel()
        captureTask = nil
        stage = .idle
        progress = 0
        Task { await pipeline.stop() }
    }

    // MARK: - Measurement

    private func run() async {
        stage = .requestingAccess
        guard await Self.requestCameraAccess() else {
            stage = .failed("Camera access is turned off. Enable it for Respire in Settings to measure your pulse.")
            return
        }

        let stream: AsyncStream<PPGSample>
        do {
            stream = try await pipeline.start()
        } catch {
            stage = .failed(error.localizedDescription)
            return
        }

        stage = .placeFinger
        var window: [PPGSample] = []
        var coverageStart: TimeInterval?
        var frameIndex = 0

        // AsyncStream iteration ends automatically when this task is cancelled.
        for await sample in stream {
            frameIndex += 1

            guard sample.isFingerCovering else {
                // Finger lifted or lens partially exposed: start over.
                coverageStart = nil
                window.removeAll(keepingCapacity: true)
                progress = 0
                if stage != .placeFinger {
                    liveWaveform = []
                    stage = .placeFinger
                }
                continue
            }

            if stage != .measuring { stage = .measuring }
            let start = coverageStart ?? sample.time
            coverageStart = start
            guard sample.time - start >= settleDuration else { continue }

            window.append(sample)
            let measured = sample.time - (window.first?.time ?? sample.time)
            progress = min(measured / measurementDuration, 1)

            // Refreshing the waveform every other frame (15 Hz) is smooth enough and halves the work.
            if frameIndex.isMultiple(of: 2) {
                let recent = window.drop(while: { sample.time - $0.time > liveWindow })
                liveWaveform = PulseSignalAnalyzer.displayWaveform(from: Array(recent))
            }

            if measured >= measurementDuration { break }
        }

        await pipeline.stop()
        guard !Task.isCancelled else { return }

        if let reading = PulseSignalAnalyzer.analyze(window) {
            stage = .result(reading)
        } else {
            stage = .failed("Couldn't find a steady pulse. Rest your fingertip lightly over the camera and flash — pressing hard blocks blood flow — and stay still.")
        }
    }

    private static func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }
}
