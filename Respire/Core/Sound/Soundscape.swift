//
//  Soundscape.swift
//  Respire
//
//  Plays the world's nature sound and an optional solfeggio tone, breathing with
//  the breath engine. Uses the ambient audio session, so it respects the silent
//  switch and mixes with anything else playing. It fades in and out and never
//  blocks the main thread. Sound is off unless the person turns it on.
//

import AVFoundation
import Foundation
import os

final class Soundscape {
    private let engine = AVAudioEngine()
    private let synth = AmbientSynth()
    private var node: AVAudioSourceNode?
    private var stopTask: Task<Void, Never>?
    private var followTask: Task<Void, Never>?
    private var isActivating = false
    private static let logger = Logger(subsystem: "Respire", category: "Sound")

    private(set) var isPlaying = false

    /// Plays `theme`'s soundscape following `breathEngine`, or fades out when there's nothing to hear.
    func play(theme: BreathTheme, nature: Bool, toneHz: Double, following breathEngine: BreathEngine) {
        synth.theme = BreathTheme.allCases.firstIndex(of: theme) ?? 0
        synth.natureTarget = nature ? 1 : 0
        synth.toneTarget = toneHz
        guard nature || toneHz > 0 else {
            stop()
            return
        }
        follow(breathEngine)
        start()
    }

    /// Fades out, then stops the engine and releases the audio session.
    func stop() {
        guard isPlaying || engine.isRunning else { return }
        isPlaying = false
        synth.targetGain = 0
        followTask?.cancel()
        followTask = nil
        stopTask?.cancel()
        stopTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, engine.isRunning else { return }
            engine.stop()
            // Always mixing with others, so nobody was interrupted and needs telling.
            AVAudioSession.sharedInstance().deactivate { _, _ in }
        }
    }

    // MARK: - Following the breath

    /// Feeds the engine's lung volume to the synth ~30 times a second. Between and
    /// after sessions the sound rests at a gentle, slowly swaying level.
    private func follow(_ breathEngine: BreathEngine) {
        followTask?.cancel()
        followTask = Task { [synth] in
            let start = Date.now
            while !Task.isCancelled {
                let now = Date.now
                let openness: Double
                switch breathEngine.state {
                case .running, .paused:
                    openness = breathEngine.snapshot(at: now).lungVolume
                case .idle, .finished:
                    openness = 0.3 + 0.1 * sin(now.timeIntervalSince(start) * 0.5)
                }
                synth.opennessTarget = Float(openness)
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }

    // MARK: - Engine

    private func start() {
        stopTask?.cancel()
        stopTask = nil
        isPlaying = true
        synth.targetGain = 1
        guard !engine.isRunning, !isActivating else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        } catch {
            Self.logger.info("Audio session unavailable: \(error.localizedDescription)")
            return // Sound is a nicety; the breath carries on in silence.
        }
        // Activate asynchronously so the breath never stutters, then start on the main actor.
        isActivating = true
        // A brief strong capture is fine: the soundscape lives as long as the session view model.
        AVAudioSession.sharedInstance().activate { isActive, _ in
            Task { @MainActor in
                self.isActivating = false
                guard isActive, self.isPlaying else { return }
                self.startEngine()
            }
        }
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        let rate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        synth.sampleRate = rate > 0 ? rate : 48_000
        do {
            if node == nil {
                let format = AVAudioFormat(standardFormatWithSampleRate: synth.sampleRate, channels: 2)
                let source = Self.makeNode(synth: synth)
                engine.attach(source)
                try engine.connectNode(source, to: engine.mainMixerNode, format: format)
                node = source
            }
            try engine.start()
        } catch {
            Self.logger.info("Audio engine didn't start: \(error.localizedDescription)")
        }
    }

    nonisolated private static func makeNode(synth: AmbientSynth) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            synth.render(frames: Int(frameCount), into: UnsafeMutableAudioBufferListPointer(bufferList))
            return noErr
        }
    }
}
