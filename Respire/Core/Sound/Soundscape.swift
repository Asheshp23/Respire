//
//  Soundscape.swift
//  Respire
//
//  Everything you hear in a session, through one audio engine: the world's nature
//  sound, an optional solfeggio tone, the breath sound that guides eyes-closed
//  practice, the phase chime, and the spoken voice. Speech is rendered to buffers and
//  played here too, so voice and sound share one mix and the audio session is never
//  reset mid-session (which made the sound stutter). With eyes closed, sound is the
//  guide, so it plays even with the silent switch on; it always mixes with anything
//  else playing. It fades in and out and never blocks the main thread.
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

    // Voice.
    private let speech = AVSpeechSynthesizer()
    private let voicePlayer = AVAudioPlayerNode()
    private var voiceFormat: AVAudioFormat?
    private var currentLine: SpokenLine?

    private(set) var isPlaying = false
    /// Whether a soft chime marks each change of phase.
    private var cuesEnabled = false
    /// Whether the breath sound plays while breathing.
    private var guideEnabled = false
    /// Whether a soft hum plays on each out-breath, to hum along with.
    private var humEnabled = false

    /// The breath sound's setting; on unless turned off.
    static let guideKey = "sound.guide"

    /// Plays `theme`'s soundscape following `breathEngine`, or fades out when there's nothing to hear.
    /// `cues`, `guide`, and `voice` keep the engine running even with nature and tone off.
    func play(theme: BreathTheme, nature: Bool, toneHz: Double, cues: Bool = false, guide: Bool = false,
              voice: Bool = false, hum: Bool = false, following breathEngine: BreathEngine) {
        humEnabled = hum
        synth.theme = BreathTheme.allCases.firstIndex(of: theme) ?? 0
        synth.natureTarget = nature ? 1 : 0
        synth.toneTarget = toneHz
        cuesEnabled = cues
        guideEnabled = guide
        guard nature || toneHz > 0 || cues || guide || voice || hum else {
            stop()
            return
        }
        follow(breathEngine)
        start()
    }

    /// Rings the chime for a new phase: higher on the in-breath, lower on the out-breath,
    /// in between for holds, so phases can be followed with eyes closed.
    func cue(_ phase: BreathPhase) {
        guard isPlaying, cuesEnabled else { return }
        synth.cueFrequency = switch phase {
        case .inhale: 528
        case .exhale: 396
        case .holdFull, .holdEmpty: 440
        }
        synth.cueToken &+= 1
    }

    /// The session has ended: one bell, and the breath sound falls quiet. The caller
    /// fades everything out once any closing words have been spoken.
    func ringEnd() {
        guard isPlaying else { return }
        synth.airTarget = 0
        synth.cueFrequency = 528
        synth.cueToken &+= 1
    }

    /// Fades out, then stops the engine and releases the audio session.
    func stop() {
        stopVoice()
        guard isPlaying || engine.isRunning else { return }
        isPlaying = false
        synth.targetGain = 0
        synth.airTarget = 0
        synth.humTarget = 0
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

    // MARK: - Voice

    /// Whether a line is being spoken right now.
    var isSpeaking: Bool { currentLine != nil }

    /// Speaks `utterance` through the soundscape and returns once it has been heard
    /// (or cut short by `stopVoice`). The rest of the sound dips a little under it.
    func say(_ utterance: AVSpeechUtterance) async {
        if !isPlaying { start() }
        // One line at a time: a new line ends any line still being spoken.
        stopVoice()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let line = SpokenLine(continuation: continuation)
            currentLine = line
            synth.targetGain = 0.7
            Self.render(utterance, with: speech) { [weak self] buffer in
                self?.receive(buffer, for: line)
            }
        }
    }

    /// Stops speaking at once.
    func stopVoice() {
        guard let line = currentLine else { return }
        speech.stopSpeaking(at: .immediate)
        if voicePlayer.engine != nil { voicePlayer.stop() }
        finish(line)
    }

    /// A buffer of speech, on the main actor. An empty buffer means the line is fully rendered.
    private func receive(_ buffer: AVAudioPCMBuffer?, for line: SpokenLine) {
        guard line === currentLine else { return }
        guard let buffer, buffer.frameLength > 0 else {
            line.isRendered = true
            if line.outstanding == 0 { finish(line) }
            return
        }
        guard connectVoice(format: buffer.format) else {
            finish(line)
            return
        }
        line.outstanding += 1
        voicePlayer.scheduleBuffer(buffer, completionHandler: Self.onMain { [weak self] in
            line.outstanding -= 1
            if line.isRendered, line.outstanding == 0 { self?.finish(line) }
        })
        if engine.isRunning, !voicePlayer.isPlaying { startVoicePlayer() }
    }

    private func startVoicePlayer() {
        do {
            try voicePlayer.playAudio()
        } catch {
            Self.logger.info("Voice couldn't play: \(error.localizedDescription)")
        }
    }

    private func finish(_ line: SpokenLine) {
        guard !line.isFinished else { return }
        line.isFinished = true
        if line === currentLine {
            currentLine = nil
            if isPlaying { synth.targetGain = 1 }
        }
        line.continuation.resume()
    }

    /// Attaches the voice player the first time, and reconnects it if a voice speaks in a new format.
    private func connectVoice(format: AVAudioFormat) -> Bool {
        if voicePlayer.engine == nil {
            engine.attach(voicePlayer)
            voicePlayer.volume = 0.8
        }
        guard voiceFormat != format else { return true }
        do {
            engine.disconnectNodeOutput(voicePlayer)
            try engine.connectNode(voicePlayer, to: engine.mainMixerNode, format: format)
            voiceFormat = format
            return true
        } catch {
            Self.logger.info("Voice couldn't connect: \(error.localizedDescription)")
            return false
        }
    }

    /// Renders speech off the main actor, converting it to the float format the mixer plays,
    /// and hands each buffer back on the main actor (in order). `nil` marks the end.
    nonisolated private static func render(_ utterance: AVSpeechUtterance, with synthesizer: AVSpeechSynthesizer,
                                           deliver: @escaping @MainActor (AVAudioPCMBuffer?) -> Void) {
        var converter: AVAudioConverter?
        synthesizer.write(utterance) { buffer in
            var converted: AVAudioPCMBuffer?
            if let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 {
                converted = Self.floatBuffer(from: pcm, converter: &converter)
                if converted == nil { return }
            }
            nonisolated(unsafe) let delivered = converted
            DispatchQueue.main.async {
                MainActor.assumeIsolated { deliver(delivered) }
            }
        }
    }

    /// Wraps main-actor work for an audio callback that may arrive on any thread.
    nonisolated private static func onMain(_ work: @escaping @MainActor () -> Void) -> @Sendable () -> Void {
        {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { work() }
            }
        }
    }

    nonisolated private static func floatBuffer(from pcm: AVAudioPCMBuffer, converter: inout AVAudioConverter?) -> AVAudioPCMBuffer? {
        if pcm.format.commonFormat == .pcmFormatFloat32, !pcm.format.isInterleaved { return pcm }
        guard let target = AVAudioFormat(standardFormatWithSampleRate: pcm.format.sampleRate, channels: pcm.format.channelCount),
              let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: pcm.frameLength) else { return nil }
        if converter == nil || converter?.inputFormat != pcm.format {
            converter = AVAudioConverter(from: pcm.format, to: target)
        }
        do {
            try converter?.convert(to: output, from: pcm)
            return output
        } catch {
            return nil
        }
    }

    // MARK: - Following the breath

    /// Feeds the breath engine to the synth ~30 times a second: lung volume for the world's
    /// sound, and how much air is moving for the breath sound. Between and after sessions the
    /// sound rests at a gentle, slowly swaying level.
    private func follow(_ breathEngine: BreathEngine) {
        followTask?.cancel()
        followTask = Task { [synth, weak self] in
            let start = Date.now
            while !Task.isCancelled {
                let now = Date.now
                let openness: Double
                var air = 0.0
                switch breathEngine.state {
                case .running, .paused:
                    let snapshot = breathEngine.snapshot(at: now)
                    openness = snapshot.lungVolume
                    // Air moves on the in- and out-breath, swelling early and easing at the turn.
                    if breathEngine.state == .running, self?.guideEnabled == true,
                       snapshot.phase == .inhale || snapshot.phase == .exhale {
                        air = pow(sin(.pi * snapshot.phaseProgress), 0.6)
                    }
                case .idle, .finished:
                    openness = 0.3 + 0.1 * sin(now.timeIntervalSince(start) * 0.5)
                }
                // The hum swells in quickly at the start of each out-breath and fades at its end.
                var hum = 0.0
                if breathEngine.state == .running, self?.humEnabled == true {
                    let snapshot = breathEngine.snapshot(at: now)
                    if snapshot.phase == .exhale { hum = pow(sin(.pi * snapshot.phaseProgress), 0.35) }
                }
                synth.opennessTarget = Float(openness)
                synth.airTarget = Float(air)
                synth.humTarget = Float(hum)
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }

    // MARK: - Engine

    private func start() {
        stopTask?.cancel()
        stopTask = nil
        isPlaying = true
        synth.targetGain = currentLine == nil ? 1 : 0.7
        guard !engine.isRunning, !isActivating else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
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
            // Speech that arrived while the engine was starting.
            if currentLine != nil, voiceFormat != nil { startVoicePlayer() }
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

/// One line being spoken: resumed once it's fully rendered and every buffer has played.
private final class SpokenLine {
    let continuation: CheckedContinuation<Void, Never>
    var outstanding = 0
    var isRendered = false
    var isFinished = false

    init(continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation
    }
}
