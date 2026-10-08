//
//  DharanaLibrary.swift
//  Respire
//
//  Loads the bundled gates and remembers which ones have been practiced.
//

import Foundation
import Observation
import os

@Observable
final class DharanaLibrary {
    private(set) var collection: DharanaCollection?
    /// Gate number → when it was last practiced to completion.
    private(set) var practiced: [Int: Date]

    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "dharanas.practiced"
    private static let logger = Logger(subsystem: "Respire", category: "Dharanas")

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        collection = Self.load(from: bundle)
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([Int: Date].self, from: data) {
            practiced = stored
        } else {
            practiced = [:]
        }
    }

    func markPracticed(_ dharana: Dharana, at date: Date = .now) {
        practiced[dharana.number] = date
        if let data = try? JSONEncoder().encode(practiced) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    func isPracticed(_ dharana: Dharana) -> Bool {
        practiced[dharana.number] != nil
    }

    /// Today's gate, with beginners kept to the foundations until they've practiced a few.
    func gateOfTheDay(for date: Date = .now) -> Dharana? {
        collection?.dharanaOfTheDay(for: date, practicedCount: practiced.count)
    }

    static func load(from bundle: Bundle) -> DharanaCollection? {
        let url = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .first { $0.lastPathComponent.hasSuffix(".dharanas.json") }
        guard let url else {
            logger.error("No dharana collection in the bundle")
            return nil
        }
        do {
            let collection = try JSONDecoder().decode(DharanaCollection.self, from: Data(contentsOf: url))
            guard collection.schemaVersion <= DharanaCollection.supportedSchemaVersion else {
                logger.info("Skipping \(url.lastPathComponent): schema \(collection.schemaVersion) is newer than supported")
                return nil
            }
            return collection
        } catch {
            logger.error("Couldn't read \(url.lastPathComponent): \(String(describing: error))")
            return nil
        }
    }
}
