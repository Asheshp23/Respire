//
//  OpeningGenerator.swift
//  Respire
//
//  The seam between the opening experience and whatever writes it. Every writer
//  runs entirely on device and emits *finished* lines in order, so the view can
//  animate each one without it ever rewriting itself mid-sentence.
//
//  Writers, in order of preference:
//  - `FoundationModelOpeningGenerator`: Apple's on-device system language model
//    (Apple Intelligence). Never Private Cloud Compute: the prompt stays on device.
//  - `TemplateOpeningGenerator`: a deterministic composer for devices without
//    Apple Intelligence, or when the model is still downloading or declines.
//
//  An MLX-backed writer (an open-weights small model bundled or downloaded
//  on first use) would conform to the same protocol without touching the UI.
//

import Foundation

enum OpeningSource: Equatable {
    case onDeviceModel
    case template
}

protocol OpeningGenerator {
    var source: OpeningSource { get }

    /// Loads anything slow (model weights, instruction prefix) ahead of `lines(for:)`.
    /// Call it at least a second before generating.
    func prepare()

    /// Streams complete lines of the opening, in order.
    func lines(for context: SomaticContext) -> AsyncThrowingStream<String, Error>
}

extension OpeningGenerator {
    func prepare() {}
}

enum OpeningGenerators {
    /// The best writer available on this device right now.
    static func preferred() -> any OpeningGenerator {
        FoundationModelOpeningGenerator.isAvailable ? FoundationModelOpeningGenerator() : TemplateOpeningGenerator()
    }
}
