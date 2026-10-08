//
//  CymaticsScene.swift
//  Respire
//
//  Cymatics: sound made visible. A dark bowl of water seen from above, its
//  surface standing in a mandala of waves. Built for awe: a figure far more
//  intricate than its cause, slowly revealed.
//
//  - The breath unfolds the figure from the center to the rim, and back.
//  - At each turn of the breath, and in holds, its lines draw fine and settle.
//  - The solfeggio tone chooses the figure: each tone has its own symmetry and
//    color, and changing it morphs the water from one figure into the next.
//
//  Drawn by the `cymatics` shader in PrismShaders.metal.
//

import SwiftUI

struct CymaticsScene: View {
    var openness: Double
    var time: Double
    /// 1 when the breath is still (its turns and holds), 0 at its fastest.
    var stillness: Double = 1

    @AppStorage(SolfeggioTone.storageKey) private var tone: SolfeggioTone = .off

    /// Which of the nine figures the water holds. With no tone playing, the world's own: 528 Hz.
    private var figure: Int {
        let hertz = tone.frequency(for: .cymatics)
        return SolfeggioTone.tones.firstIndex { $0.hertz == hertz }
            ?? SolfeggioTone.tones.firstIndex(of: SolfeggioTone.tone(for: .cymatics))
            ?? 4
    }

    var body: some View {
        ZStack {
            Color.black
            CymaticFigure(figure: figure, openness: openness, time: time, stillness: stillness)
                .id(figure)
                .transition(.opacity)
        }
        // A slow crossfade reads as the water reshaping itself to the new tone.
        .animation(.easeInOut(duration: 2.4), value: figure)
    }
}

/// One figure in the bowl.
private struct CymaticFigure: View {
    let figure: Int
    var openness: Double
    var time: Double
    var stillness: Double

    /// Low tones give simple, crystalline figures; high tones, many-petalled ones.
    private static let folds: [Double] = [3, 4, 5, 6, 7, 8, 9, 10, 12]

    var body: some View {
        let position = Double(figure) / Double(Self.folds.count - 1)
        GeometryReader { geo in
            Rectangle()
                .colorEffect(ShaderLibrary.cymatics(
                    .float2(geo.size.width, geo.size.height),
                    .float(openness),
                    .float(time),
                    .float(Self.folds[min(max(figure, 0), Self.folds.count - 1)]),
                    // Higher tones, finer waves.
                    .float(0.85 + 0.35 * position),
                    .float(stillness),
                    // Low tones warm, high tones cool, as in the tone picker.
                    .float(0.02 + 0.76 * position)
                ))
        }
    }
}

#Preview("Cymatics, breathing in") {
    CymaticsScene(openness: 0.85, time: 12, stillness: 1).ignoresSafeArea()
}

#Preview("Cymatics, breathed out") {
    CymaticsScene(openness: 0.15, time: 12, stillness: 1).ignoresSafeArea()
}

#Preview("The nine figures, 174 to 963 Hz") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
        ForEach(0..<9, id: \.self) { figure in
            CymaticFigure(figure: figure, openness: 0.8, time: 12, stillness: 1)
                .aspectRatio(1, contentMode: .fit)
        }
    }
    .background(.black)
}
