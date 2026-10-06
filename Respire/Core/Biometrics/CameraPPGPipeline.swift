//
//  CameraPPGPipeline.swift
//  Respire
//

import AVFoundation
import CoreMedia
import os

/// Owns the AVFoundation capture graph used for fingertip PPG: rear wide camera + torch,
/// low resolution, fixed 30 fps. Each frame is reduced to a mean color on a background queue
/// and emitted as a `PPGSample` through an `AsyncStream`.
///
/// All session mutations happen on `sessionQueue` (start/stop block for hundreds of ms and must
/// never run on the main thread); frame analysis happens on `videoQueue`.
nonisolated final class CameraPPGPipeline: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum PipelineError: LocalizedError {
        case cameraUnavailable
        case configurationFailed

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable: "The rear camera isn't available on this device."
            case .configurationFailed: "The camera couldn't be configured for pulse measurement."
            }
        }
    }

    static let framesPerSecond: Int32 = 30
    /// Gentler than full brightness: plenty of light through a fingertip, less heat on the lens.
    private static let torchLevel: Float = 0.7

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.respire.ppg.session")
    private let videoQueue = DispatchQueue(label: "com.respire.ppg.video", qos: .userInitiated)
    private let continuation = OSAllocatedUnfairLock<AsyncStream<PPGSample>.Continuation?>(initialState: nil)

    // Only touched on `sessionQueue`.
    private var device: AVCaptureDevice?
    private var isConfigured = false

    // MARK: - Control

    /// Configures (once), starts the session, and turns the torch on.
    func start() async throws -> AsyncStream<PPGSample> {
        let (stream, newContinuation) = AsyncStream.makeStream(
            of: PPGSample.self,
            bufferingPolicy: .bufferingNewest(Int(Self.framesPerSecond) * 2)
        )
        continuation.withLock { previous in
            previous?.finish()
            previous = newContinuation
        }

        try await withCheckedThrowingContinuation { (resume: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                do {
                    if !isConfigured { try configureSession() }
                    if !session.isRunning { session.startRunning() }
                    // The torch can only be enabled once the session is running.
                    setTorch(on: true)
                    resume.resume()
                } catch {
                    resume.resume(throwing: error)
                }
            }
        }
        return stream
    }

    func stop() async {
        continuation.withLock { current in
            current?.finish()
            current = nil
        }
        await withCheckedContinuation { (resume: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [self] in
                setTorch(on: false)
                if session.isRunning { session.stopRunning() }
                resume.resume()
            }
        }
    }

    // MARK: - Configuration (sessionQueue)

    private func configureSession() throws {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw PipelineError.cameraUnavailable
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // We only need average color, so the smallest preset keeps per-frame work trivial.
        session.sessionPreset = .low

        guard let input = try? AVCaptureDeviceInput(device: camera), session.canAddInput(input) else {
            throw PipelineError.configurationFailed
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else { throw PipelineError.configurationFailed }
        session.addOutput(output)

        try camera.lockForConfiguration()
        defer { camera.unlockForConfiguration() }

        // A steady frame rate keeps the sampling interval uniform for the analyzer.
        let frameDuration = CMTime(value: 1, timescale: Self.framesPerSecond)
        let supportsRate = camera.activeFormat.videoSupportedFrameRateRanges.contains {
            $0.minFrameRate <= Double(Self.framesPerSecond) && Double(Self.framesPerSecond) <= $0.maxFrameRate
        }
        if supportsRate {
            camera.activeVideoMinFrameDuration = frameDuration
            camera.activeVideoMaxFrameDuration = frameDuration
        }
        // Focus hunting against skin adds brightness noise; pin it.
        if camera.isFocusModeSupported(.locked) {
            camera.focusMode = .locked
        }

        device = camera
        isConfigured = true
    }

    private func setTorch(on: Bool) {
        guard let device, device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if on {
                try device.setTorchModeOn(level: Self.torchLevel)
            } else {
                device.torchMode = .off
            }
        } catch {
            // Without the torch the measurement may still work in bright light; carry on.
        }
    }

    // MARK: - Frame processing (videoQueue)

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let sample = Self.meanColor(of: sampleBuffer) else { return }
        continuation.withLock { _ = $0?.yield(sample) }
    }

    /// Averages BGRA pixels over the central region of the frame, sampling every few pixels.
    /// The center avoids vignetting and the edges of the fingertip where ambient light leaks in.
    private static func meanColor(of sampleBuffer: CMSampleBuffer) -> PPGSample? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixels = base.assumingMemoryBound(to: UInt8.self)

        let stride = 2
        var red = 0, green = 0, blue = 0, count = 0
        for y in Swift.stride(from: height / 4, to: height * 3 / 4, by: stride) {
            let row = pixels + y * bytesPerRow
            for x in Swift.stride(from: width / 4, to: width * 3 / 4, by: stride) {
                let pixel = row + x * 4  // BGRA
                blue += Int(pixel[0])
                green += Int(pixel[1])
                red += Int(pixel[2])
                count += 1
            }
        }
        guard count > 0 else { return nil }

        let scale = 1 / (Double(count) * 255)
        return PPGSample(
            time: CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds,
            red: Double(red) * scale,
            green: Double(green) * scale,
            blue: Double(blue) * scale
        )
    }
}
