//
//  OpeningPlayer.swift
//  Respire
//
//  Runs one personalized opening from start to finish:
//
//    gather context → compose (streaming) → play each line at a speaking pace → done
//
//  Generation and playback overlap. The first line plays as soon as it's written,
//  and later lines arrive while earlier ones are read. Each line gets time in
//  proportion to its length, which brings five lines to about thirty seconds.
//
//  Resilience: the model is prepared while context is gathered (well over the
//  one second prewarming needs). If it hasn't produced a first line within 8 s,
//  or declines, the template writes the whole opening. If it stops partway, the
//  template's closing line still invites the first breath.
//

import Foundation
import Observation
import os

@Observable
final class OpeningPlayer {
    enum Stage: Equatable {
        case gathering
        case composing
        case playing
        case finished
    }

    static let expectedLines = 5
    /// Typing speed in glyphs per second; unhurried, close to a slow speaking voice.
    static let typingRate: Double = 24
    /// How long each line takes to dissolve before the next appears.
    static let fadeOutDuration: TimeInterval = 0.9
    private static let firstLineDeadline: Duration = .seconds(8)
    private static let logger = Logger(subsystem: "Respire", category: "Opening")

    private(set) var stage: Stage = .gathering
    private(set) var lines: [String] = []
    private(set) var currentIndex = 0
    private(set) var lineStartedAt = Date.now
    private(set) var currentLineDuration: TimeInterval = 6
    private(set) var source: OpeningSource?
    private(set) var weatherCredit: WeatherCredit?

    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var isGenerationFinished = false

    var currentLine: String? {
        lines.indices.contains(currentIndex) ? lines[currentIndex] : nil
    }

    /// Time each line stays on screen: long enough to type, read, and breathe with it.
    static func duration(for line: String) -> TimeInterval {
        min(max(1.6 + Double(line.count) / 16, 4.5), 8)
    }

    // MARK: - Control

    func start(
        focus: SessionFocus,
        baseline: PulseReading?,
        sceneTitle: String,
        pattern: BreathPattern,
        gate: SomaticContext.Gate? = nil,
        contextService: DeviceContextService
    ) {
        task?.cancel()
        task = Task {
            await run(focus: focus, baseline: baseline, sceneTitle: sceneTitle, pattern: pattern, gate: gate, contextService: contextService)
        }
    }

    /// Ends the opening now and moves on to breathing.
    func skip() {
        finish()
    }

    /// Ends the opening without starting the session (e.g. the view went away).
    func cancel() {
        onFinish = nil
        task?.cancel()
        task = nil
    }

    // MARK: - Flow

    private func run(
        focus: SessionFocus,
        baseline: PulseReading?,
        sceneTitle: String,
        pattern: BreathPattern,
        gate: SomaticContext.Gate?,
        contextService: DeviceContextService
    ) async {
        let generator = OpeningGenerators.preferred()
        // Model assets load while location and weather resolve.
        generator.prepare()

        stage = .gathering
        let gathered = await contextService.gather(focus: focus, baseline: baseline, sceneTitle: sceneTitle, pattern: pattern, gate: gate)
        guard !Task.isCancelled else { return }
        weatherCredit = gathered.weatherCredit

        stage = .composing
        let production = Task { await produce(with: generator, context: gathered.context) }
        defer { production.cancel() }

        var index = 0
        while !Task.isCancelled {
            // Wait for the next line to be written, or for writing to end.
            while lines.count <= index, !isGenerationFinished {
                try? await Task.sleep(for: .milliseconds(80))
                if Task.isCancelled { return }
            }
            guard lines.count > index else { break }

            stage = .playing
            currentIndex = index
            currentLineDuration = Self.duration(for: lines[index])
            lineStartedAt = .now
            try? await Task.sleep(for: .seconds(currentLineDuration))
            index += 1
        }
        if !Task.isCancelled { finish() }
    }

    private func produce(with primary: any OpeningGenerator, context: SomaticContext) async {
        source = primary.source

        let generation = Task { () -> Bool in
            do {
                for try await line in primary.lines(for: context) {
                    lines.append(line)
                }
                return true
            } catch {
                Self.logger.info("Opening generation stopped: \(String(describing: error))")
                return false
            }
        }
        // Don't keep someone waiting on a slow or still-loading model.
        let watchdog = Task {
            try? await Task.sleep(for: Self.firstLineDeadline)
            if !Task.isCancelled, lines.isEmpty { generation.cancel() }
        }
        let completed = await generation.value
        watchdog.cancel()
        guard !Task.isCancelled else { return }

        if lines.isEmpty {
            source = .template
            lines = TemplateOpeningGenerator.compose(for: context)
        } else if !completed {
            lines.append(TemplateOpeningGenerator.closing(for: context))
        }
        isGenerationFinished = true
    }

    private func finish() {
        guard stage != .finished else { return }
        stage = .finished
        task?.cancel()
        task = nil
        let onFinish = onFinish
        self.onFinish = nil
        onFinish?()
    }
}

#if DEBUG
extension OpeningPlayer {
    /// A player frozen partway through a line, for previews.
    static func preview(lines: [String], index: Int = 0, elapsed: TimeInterval = 1.6, source: OpeningSource = .onDeviceModel) -> OpeningPlayer {
        let player = OpeningPlayer()
        player.lines = lines
        player.currentIndex = index
        player.stage = .playing
        player.source = source
        player.currentLineDuration = duration(for: lines[index])
        player.lineStartedAt = Date.now.addingTimeInterval(-elapsed)
        return player
    }
}
#endif
