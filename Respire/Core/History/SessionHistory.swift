//
//  SessionHistory.swift
//  Respire
//
//  A quiet record of finished sessions: what, when, and for how long. It feeds the You
//  tab's week at a glance. Kept on device; nothing leaves it.
//

import Foundation
import Observation

@Observable
final class SessionHistory {
    struct Entry: Codable, Identifiable, Hashable {
        var id = UUID()
        var date: Date
        var title: String
        var seconds: Double

        var minutes: Int { max(1, Int((seconds / 60).rounded())) }
    }

    private(set) var entries: [Entry]

    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "history.sessions"
    /// Enough for a long look back without growing forever.
    private static let limit = 300

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = stored
        } else {
            entries = []
        }
    }

    /// Records a finished session. Anything shorter than a few breaths isn't counted.
    func record(title: String, seconds: Double, at date: Date = .now) {
        guard seconds >= 20 else { return }
        entries.insert(Entry(date: date, title: title, seconds: seconds), at: 0)
        if entries.count > Self.limit { entries.removeLast(entries.count - Self.limit) }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    /// The last seven days, oldest first, and whether you breathed on each.
    func week(ending date: Date = .now, calendar: Calendar = .current) -> [(day: Date, practiced: Bool)] {
        let today = calendar.startOfDay(for: date)
        return (0..<7).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return (day, entries.contains { calendar.isDate($0.date, inSameDayAs: day) })
        }
    }

    /// Sessions and minutes over the last seven days.
    func lastSevenDays(from date: Date = .now, calendar: Calendar = .current) -> (sessions: Int, minutes: Int) {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: date)) ?? date
        let recent = entries.filter { $0.date >= start }
        return (recent.count, Int((recent.reduce(0) { $0 + $1.seconds } / 60).rounded()))
    }
}
