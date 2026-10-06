//
//  JourneyProgressStore.swift
//  Respire
//
//  Which journey days are complete, and what that unlocks. One gate opens per
//  calendar day: a chapter becomes available once the previous one was completed
//  on an *earlier* local day. Nothing expires, and there are no streaks to lose.
//

import Foundation
import Observation

enum ChapterState: Equatable {
    case completed(Date)
    case available
    /// The previous day was completed today; this one opens at local midnight.
    case opensTomorrow
    /// The previous day isn't complete yet.
    case locked

    var isOpen: Bool {
        switch self {
        case .completed, .available: true
        case .opensTomorrow, .locked: false
        }
    }

    var isCompleted: Bool {
        if case .completed = self { true } else { false }
    }
}

@Observable
final class JourneyProgressStore {
    private static let storageKey = "journeys.completions"

    /// Chapter key (`journey/chapter`) → when it was first completed.
    private(set) var completions: [String: Date]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([String: Date].self, from: data) {
            completions = stored
        } else {
            completions = [:]
        }
    }

    // MARK: - Queries

    func state(of chapter: JourneyChapter, in journey: Journey, now: Date = .now) -> ChapterState {
        if let date = completions[journey.key(for: chapter)] {
            return .completed(date)
        }
        guard let index = journey.chapters.firstIndex(of: chapter), index > 0 else {
            return .available
        }
        guard let previous = completions[journey.key(for: journey.chapters[index - 1])] else {
            return .locked
        }
        return calendar.isDate(previous, inSameDayAs: now) ? .opensTomorrow : .available
    }

    func states(in journey: Journey, now: Date = .now) -> [ChapterState] {
        journey.chapters.map { state(of: $0, in: journey, now: now) }
    }

    func completedCount(in journey: Journey) -> Int {
        journey.chapters.count { completions[journey.key(for: $0)] != nil }
    }

    /// The first day not yet completed, whatever its state; `nil` when the journey is finished.
    func nextChapter(in journey: Journey) -> JourneyChapter? {
        journey.chapters.first { completions[journey.key(for: $0)] == nil }
    }

    // MARK: - Updates

    /// Records the first completion. Practicing a day again keeps its original date,
    /// so repeat practice never delays the next unlock.
    func complete(_ chapter: JourneyChapter, in journey: Journey, at date: Date = .now) {
        let key = journey.key(for: chapter)
        guard completions[key] == nil else { return }
        completions[key] = date
        save()
    }

    func reset(_ journey: Journey) {
        for chapter in journey.chapters {
            completions[journey.key(for: chapter)] = nil
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(completions) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
