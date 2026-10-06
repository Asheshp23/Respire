//
//  AmbientSynth.swift
//  Respire
//
//  Nature sound for each breath world, synthesized live with no audio files
//  (ported from Mindful Prism). One render callback makes noise, filters, and tones:
//
//    Aurora Lake    a soft major-seventh drone with a faint airy hiss
//    Ocean Tide     surf that swells as you breathe in and draws back
//    Sakura Moon    a light breeze and occasional wind chimes
//    Desert Stars   a whisper of wind and a crackling candle
//    Hidden Falls   steady falling water
//    Ember Peak     a deep rumble that grows with the in-breath, and crackle
//    Rain Pond      rain hiss and droplets, softening on the out-breath
//    Prairie Wind   gusts that rise with the in-breath
//    Distant Storm  rain, and thunder rolling every so often
//
//  Under or instead of the world, an optional solfeggio tone: a soft sine at one of
//  the nine traditional frequencies, swelling slightly with the breath.
//
//  In Respire the breath engine is the clock: `opennessTarget` follows its lung
//  volume, so sound, picture, and haptics all breathe together, and pause together.
//

import Foundation
import AVFoundation

// MARK: - Synth (audio thread)

/// All DSP state. Touched only from the render callback, apart from a few
/// plain parameter writes (theme, gain target, openness target) that are safe
/// to race: each is a single word, read once per block, and smoothed.
nonisolated final class AmbientSynth: @unchecked Sendable {
    var sampleRate: Double = 48_000
    var theme = 0
    var targetGain: Float = 0
    /// 1 to hear the world's nature sound, 0 for the tone alone.
    var natureTarget: Float = 1
    /// The solfeggio tone in Hz; 0 for none.
    var toneTarget: Double = 0
    /// The breath engine's lung volume (0 empty … 1 full), written ~30 times a second
    /// from the main actor. The render loop glides toward it, so updates never click.
    var opennessTarget: Float = 0.3

    private var frame: Double = 0
    private var gain: Float = 0
    private var seed: UInt32 = 0x9E3779B9

    // Noise colors.
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0
    private var brown: Float = 0
    // Filter states.
    private var lp1: Float = 0, lp2: Float = 0, lp3: Float = 0, lp4: Float = 0
    // Tones.
    private var phases: [Double] = [0, 0, 0, 0]
    private var chimeEnv: Float = 0, chimeFreq: Double = 660, chimePhase: Double = 0, chimeWait: Double = 48_000
    // Events.
    private var crackleEnv: Float = 0
    private var dropEnv: Float = 0
    private var rumbleEnv: Float = 0
    private var lastStormSlot = -1
    private var openness: Float = 0.3
    // Nature level and the solfeggio tone, both faded smoothly.
    private var natureLevel: Float = 1
    private var toneFreq: Double = 0
    private var toneLevel: Float = 0
    private var tonePhase: Double = 0
    private var toneShimmer: Double = 0


    private func white() -> Float {
        seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
        return Float(seed) / Float(UInt32.max) * 2 - 1
    }

    private func pink(_ w: Float) -> Float {
        b0 = 0.99765 * b0 + w * 0.0990460
        b1 = 0.96300 * b1 + w * 0.2965164
        b2 = 0.57000 * b2 + w * 1.0526913
        return (b0 + b1 + b2 + w * 0.1848) * 0.18
    }

    private func brownNoise(_ w: Float) -> Float {
        brown = (brown + 0.02 * w) / 1.02
        return brown * 3.5
    }

    private func lowpass(_ x: Float, _ state: inout Float, _ cutoff: Float) -> Float {
        let a = min(1, 2 * Float.pi * cutoff / Float(sampleRate))
        state += a * (x - state)
        return state
    }

    private func chance(_ p: Float) -> Bool { (white() + 1) * 0.5 < p }

    func render(frames: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        let sr = sampleRate
        for i in 0..<frames {
            if i % 64 == 0 {
                // About 1/750 s per block; a ~40 ms glide toward the engine's latest value.
                openness += (opennessTarget - openness) * 0.03
            }
            let o = openness
            let t = frame / sr
            let w = white()
            var s: Float = 0

            switch theme {
            case 0: // Aurora: a soft drone, Cmaj7, slowly breathing.
                let freqs: [Double] = [130.81, 196.0, 246.94, 329.63]
                for k in 0..<4 {
                    phases[k] += 2 * .pi * freqs[k] / sr
                    if phases[k] > 2 * .pi { phases[k] -= 2 * .pi }
                    s += Float(sin(phases[k])) * 0.035 * Float(0.75 + 0.25 * sin(t * 0.2 + Double(k)))
                }
                s += lowpass(pink(w), &lp1, 2500) * 0.05 * (0.6 + 0.4 * o)
            case 1: // Ocean: surf swelling with the breath.
                let swell = 0.2 + 0.8 * o
                s = lowpass(brownNoise(w), &lp1, 400 + 1600 * o) * 0.45 * swell
                s += (pink(w) - lowpass(pink(w), &lp2, 3000)) * 0.08 * swell
            case 2: // Sakura: breeze and wind chimes.
                s = lowpass(pink(w), &lp1, 500) * 0.12
                chimeWait -= 1
                if chimeWait <= 0 {
                    let notes: [Double] = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
                    chimeFreq = notes[Int((white() + 1) * 0.5 * Float(notes.count - 1))]
                    chimeEnv = 1; chimePhase = 0
                    chimeWait = sr * Double(1.6 + (white() + 1) * 1.6)
                }
                chimePhase += 2 * .pi * chimeFreq / sr
                s += (Float(sin(chimePhase)) * 0.07 + Float(sin(chimePhase * 2.76)) * 0.025) * chimeEnv
                chimeEnv *= 0.99993
            case 3: // Desert: wind whisper and candle crackle.
                s = lowpass(pink(w), &lp1, 300) * 0.1 * (0.7 + 0.3 * o)
                if chance(0.0004) { crackleEnv = 1 }
                s += (w - lowpass(w, &lp2, 2000)) * crackleEnv * 0.18
                crackleEnv *= 0.992
            case 4: // Waterfall: steady falling water.
                s = pink(w) * 0.4 + lowpass(w, &lp1, 6000) * 0.06
                s *= 0.85 + 0.15 * o
            case 5: // Volcano: deep rumble and crackle.
                s = lowpass(lowpass(brownNoise(w), &lp1, 140), &lp2, 140) * 1.4 * (0.35 + 0.65 * o)
                if chance(0.0012) { crackleEnv = 1 }
                s += (w - lowpass(w, &lp3, 1500)) * crackleEnv * 0.2
                crackleEnv *= 0.99
            case 6: // Rain: hiss and droplets, softer on the out-breath.
                let hiss = lowpass(w, &lp1, 7000) - lowpass(w, &lp2, 900)
                s = hiss * 0.16 * (0.45 + 0.55 * o)
                if chance(0.003) { dropEnv = 1 }
                s += (w - lowpass(w, &lp3, 3000)) * dropEnv * 0.25
                dropEnv *= 0.95
            case 7: // Wind: gusts rising with the in-breath.
                s = lowpass(pink(w), &lp1, 180 + 1200 * o) * 0.9 * (0.25 + 0.75 * o)
            default: // Storm: rain, and thunder rolling after each flash (every 11 s).
                let hiss = lowpass(w, &lp1, 6000) - lowpass(w, &lp2, 800)
                s = hiss * 0.12
                let slot = Int(t / 11)
                if t.truncatingRemainder(dividingBy: 11) > 0.6, slot != lastStormSlot {
                    lastStormSlot = slot
                    rumbleEnv = 1
                }
                s += lowpass(lowpass(brownNoise(w), &lp3, 90), &lp4, 90) * 2.2 * rumbleEnv
                rumbleEnv *= 0.99996
            }

            natureLevel += (natureTarget - natureLevel) * 0.0003
            s *= natureLevel

            // The tone: when it changes, fade the old one out before the new one in.
            let wantsTone = toneTarget > 0 && abs(toneTarget - toneFreq) < 0.01
            toneLevel += ((wantsTone ? 1 : 0) - toneLevel) * 0.00025
            if !wantsTone, toneLevel < 0.001 {
                toneFreq = toneTarget
                tonePhase = 0
            }
            if toneFreq > 0, toneLevel > 0.0001 {
                tonePhase += 2 * .pi * toneFreq / sr
                if tonePhase > 2 * .pi { tonePhase -= 2 * .pi }
                toneShimmer += 2 * .pi * 0.07 / sr
                // Higher tones sound louder, so they are drawn back to keep an even calm.
                let loudness = Float(pow(220 / toneFreq, 0.35)) * 0.07
                let swell = 0.7 + 0.3 * o
                let shimmer = Float(0.92 + 0.08 * sin(toneShimmer))
                s += Float(sin(tonePhase)) * loudness * swell * shimmer * toneLevel
            }

            gain += (targetGain - gain) * 0.0004
            let out = max(-1, min(1, s * gain))
            for buffer in buffers {
                buffer.mData?.assumingMemoryBound(to: Float.self)[i] = out
            }
            frame += 1
        }
    }
}
