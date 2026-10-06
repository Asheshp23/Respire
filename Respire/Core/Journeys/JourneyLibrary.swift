//
//  JourneyLibrary.swift
//  Respire
//
//  Loads every `*.journey.json` in the app bundle. A file that fails to decode, or
//  uses a newer schema version, is skipped and logged rather than crashing, so new
//  content can ship before the app understands it.
//

import Foundation
import Observation
import os

@Observable
final class JourneyLibrary {
    private(set) var journeys: [Journey]

    private static let logger = Logger(subsystem: "Respire", category: "Journeys")

    init(bundle: Bundle = .main) {
        journeys = Self.load(from: bundle)
    }

    init(journeys: [Journey]) {
        self.journeys = journeys
    }

    func journey(id: Journey.ID) -> Journey? {
        journeys.first { $0.id == id }
    }

    static func load(from bundle: Bundle) -> [Journey] {
        let urls = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasSuffix(".journey.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let journeys: [Journey] = urls.compactMap { url in
            do {
                let journey = try JSONDecoder().decode(Journey.self, from: Data(contentsOf: url))
                guard journey.schemaVersion <= Journey.supportedSchemaVersion else {
                    logger.info("Skipping \(url.lastPathComponent): schema \(journey.schemaVersion) is newer than supported")
                    return nil
                }
                return journey
            } catch {
                logger.error("Couldn't read \(url.lastPathComponent): \(String(describing: error))")
                return nil
            }
        }
        return journeys.sorted { ($0.order ?? .max, $0.title) < ($1.order ?? .max, $1.title) }
    }
}
