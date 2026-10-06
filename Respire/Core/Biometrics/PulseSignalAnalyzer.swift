//
//  PulseSignalAnalyzer.swift
//  Respire
//

import Foundation

/// One camera frame reduced to its mean color, normalized to 0...1.
nonisolated struct PPGSample: Sendable {
    let time: TimeInterval
    let red: Double
    let green: Double
    let blue: Double

    /// With the torch shining through a fingertip, the frame is saturated deep red and nearly
    /// devoid of green/blue. Anything else means the lens isn't fully covered.
    var isFingerCovering: Bool {
        red > 0.35 && green < red * 0.5 && blue < red * 0.5
    }
}

nonisolated struct PulseReading: Sendable, Equatable {
    let beatsPerMinute: Int
    /// Strength of the periodic signal, 0...1. See `PulseSignalAnalyzer.highConfidence`.
    let confidence: Double
    /// Normalized, cleaned pulse waveform (-1...1) for display.
    let waveform: [Double]
    let date: Date
}

/// Pure signal processing for photoplethysmography (PPG) from camera frames.
///
/// Each heartbeat pushes a pulse of blood into the fingertip capillaries, which absorbs more light
/// and slightly darkens the red channel. The pipeline is:
/// 1. resample to a uniform rate (frame timestamps jitter),
/// 2. invert so systole points up, and high-pass (remove the ~1 s moving average) to strip drift
///    from pressure changes and auto-exposure,
/// 3. low-pass with a short moving average to suppress sensor noise,
/// 4. find the dominant period with normalized autocorrelation in the 40–180 BPM band.
///
/// Autocorrelation is more robust than peak counting on a short 5 s window because it uses every
/// sample rather than relying on a handful of individually detected peaks.
nonisolated enum PulseSignalAnalyzer {
    static let sampleRate: Double = 30
    static let bpmRange: ClosedRange<Double> = 40...180
    /// Low-pass-filtered noise alone autocorrelates up to ~0.5, so anything below is rejected.
    static let minimumConfidence: Double = 0.5
    /// Readings between `minimumConfidence` and this are shown as approximate.
    static let highConfidence: Double = 0.65

    static func analyze(_ samples: [PPGSample]) -> PulseReading? {
        let signal = filteredSignal(from: samples)
        guard signal.count >= Int(sampleRate * 3) else { return nil }

        guard let (lag, correlation) = dominantPeriod(in: signal), correlation >= minimumConfidence else {
            return nil
        }

        let bpm = 60 * sampleRate / lag
        return PulseReading(
            beatsPerMinute: Int(bpm.rounded()),
            confidence: min(correlation, 1),
            waveform: normalizedToUnitRange(signal),
            date: .now
        )
    }

    /// Cleaned, display-ready waveform (-1...1) for live feedback while measuring.
    static func displayWaveform(from samples: [PPGSample]) -> [Double] {
        normalizedToUnitRange(filteredSignal(from: samples))
    }

    // MARK: - Pipeline stages

    static func filteredSignal(from samples: [PPGSample]) -> [Double] {
        let uniform = resample(samples)
        guard uniform.count > 10 else { return [] }

        let inverted = uniform.map { -$0 }
        let baseline = movingAverage(inverted, window: Int(sampleRate))
        let detrended = zip(inverted, baseline).map { $0 - $1 }
        let smoothed = movingAverage(detrended, window: 5)
        return zScore(smoothed)
    }

    /// Linearly interpolates the red channel onto a uniform `sampleRate` grid.
    static func resample(_ samples: [PPGSample]) -> [Double] {
        guard let first = samples.first, let last = samples.last, last.time > first.time else { return [] }

        let step = 1 / sampleRate
        let count = Int((last.time - first.time) / step) + 1
        var output: [Double] = []
        output.reserveCapacity(count)

        var j = 0
        for i in 0..<count {
            let t = first.time + Double(i) * step
            while j < samples.count - 2 && samples[j + 1].time < t { j += 1 }
            let a = samples[j], b = samples[min(j + 1, samples.count - 1)]
            let span = b.time - a.time
            let fraction = span > 0 ? min(max((t - a.time) / span, 0), 1) : 0
            output.append(a.red + (b.red - a.red) * fraction)
        }
        return output
    }

    /// Centered moving average; edges use a shrinking window so the output length matches the input.
    static func movingAverage(_ values: [Double], window: Int) -> [Double] {
        guard window > 1, !values.isEmpty else { return values }
        let half = window / 2
        var prefix = [0.0]
        prefix.reserveCapacity(values.count + 1)
        for value in values { prefix.append(prefix[prefix.count - 1] + value) }

        return values.indices.map { i in
            let lower = max(0, i - half)
            let upper = min(values.count, i + half + 1)
            return (prefix[upper] - prefix[lower]) / Double(upper - lower)
        }
    }

    static func zScore(_ values: [Double]) -> [Double] {
        guard !values.isEmpty else { return [] }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        let deviation = variance.squareRoot()
        guard deviation > .ulpOfOne else { return values.map { _ in 0 } }
        return values.map { ($0 - mean) / deviation }
    }

    /// Returns the (sub-sample) lag of the strongest autocorrelation peak within `bpmRange`,
    /// along with its normalized correlation coefficient.
    static func dominantPeriod(in signal: [Double]) -> (lag: Double, correlation: Double)? {
        let minLag = Int((60 * sampleRate / bpmRange.upperBound).rounded(.down))
        let maxLag = min(Int((60 * sampleRate / bpmRange.lowerBound).rounded(.up)), signal.count / 2)
        guard maxLag > minLag + 2 else { return nil }

        // Signal is z-scored, so dividing by the overlap length yields a Pearson-like coefficient.
        let correlations = (minLag - 1...maxLag + 1).map { lag -> Double in
            var sum = 0.0
            for i in 0..<(signal.count - lag) { sum += signal[i] * signal[i + lag] }
            return sum / Double(signal.count - lag)
        }

        // Only *local maxima* count, so a monotonic slope at the band edge can't win.
        let peaks = (1..<(correlations.count - 1)).filter {
            correlations[$0] > correlations[$0 - 1] && correlations[$0] >= correlations[$0 + 1]
        }
        guard let strongest = peaks.map({ correlations[$0] }).max() else { return nil }

        // A periodic signal correlates almost equally at 2×, 3×… its period. Picking the strongest
        // peak outright halves fast heart rates, so take the shortest lag that is nearly as strong.
        guard let bestIndex = peaks.first(where: { correlations[$0] >= strongest * 0.85 }) else { return nil }
        let best = (index: bestIndex, value: correlations[bestIndex])

        // Parabolic interpolation around the peak for sub-sample precision (~±1 BPM at 30 fps).
        let (y0, y1, y2) = (correlations[best.index - 1], best.value, correlations[best.index + 1])
        let denominator = y0 - 2 * y1 + y2
        let offset = denominator != 0 ? 0.5 * (y0 - y2) / denominator : 0
        let lag = Double(minLag - 1 + best.index) + offset
        return (lag, y1)
    }

    static func normalizedToUnitRange(_ values: [Double]) -> [Double] {
        guard let peak = values.map(abs).max(), peak > 0 else { return values }
        return values.map { $0 / peak }
    }
}
