//
//  MomentReminders.swift
//  Respire
//
//  Gentle daily reminders tied to everyday thresholds, each carrying the gate made
//  for that moment: waking (gate 87), between tasks (gate 90), and before bed (gate 85).
//  They're local notifications scheduled on device; nothing is sent anywhere.
//  Permission is requested only when the first one is turned on, and tapping a
//  reminder opens its gate in the library.
//

import Foundation
import Observation
import os
import UserNotifications

enum Moment: String, CaseIterable, Identifiable, Codable {
    case waking
    case betweenTasks
    case bedtime

    var id: String { rawValue }

    /// The gate written for this moment.
    var gate: Int {
        switch self {
        case .waking: 87
        case .betweenTasks: 90
        case .bedtime: 85
        }
    }

    var title: String {
        switch self {
        case .waking: "On waking"
        case .betweenTasks: "Between tasks"
        case .bedtime: "Before bed"
        }
    }

    var symbol: String {
        switch self {
        case .waking: "sunrise"
        case .betweenTasks: "arrow.left.arrow.right"
        case .bedtime: "moon.stars"
        }
    }

    var explanation: String {
        switch self {
        case .waking: "A nudge to pause before the first notification of the day."
        case .betweenTasks: "A midday reminder to take thirty still seconds before the next thing."
        case .bedtime: "A reminder to put the screen down and let the mind dim before sleep."
        }
    }

    var defaultTime: DateComponents {
        switch self {
        case .waking: DateComponents(hour: 7, minute: 30)
        case .betweenTasks: DateComponents(hour: 14, minute: 0)
        case .bedtime: DateComponents(hour: 22, minute: 0)
        }
    }

    fileprivate var identifier: String { "moment.\(rawValue)" }
}

@Observable
final class MomentReminders: NSObject, UNUserNotificationCenterDelegate {
    struct Setting: Codable, Equatable {
        var isEnabled = false
        var hour: Int
        var minute: Int
    }

    private(set) var settings: [Moment: Setting]
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// Set when a reminder is tapped; the root view routes to the gate and clears it.
    var openedGate: Int?

    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "reminders.moments"
    private static let logger = Logger(subsystem: "Respire", category: "Reminders")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.data(forKey: Self.storageKey).flatMap { try? JSONDecoder().decode([Moment: Setting].self, from: $0) } ?? [:]
        settings = Dictionary(uniqueKeysWithValues: Moment.allCases.map { moment in
            (moment, stored[moment] ?? Setting(hour: moment.defaultTime.hour ?? 9, minute: moment.defaultTime.minute ?? 0))
        })
        super.init()
        // Set at launch so a reminder tapped while Respire wasn't running still routes here.
        center.delegate = self
    }

    func setting(for moment: Moment) -> Setting {
        settings[moment] ?? Setting(hour: 9, minute: 0)
    }

    func time(for moment: Moment) -> Date {
        let setting = setting(for: moment)
        return Calendar.current.date(from: DateComponents(hour: setting.hour, minute: setting.minute)) ?? .now
    }

    // MARK: - Changes

    func refreshAuthorization() async {
        authorization = await center.notificationSettings().authorizationStatus
    }

    /// Turns a moment on or off, asking for permission the first time one is turned on.
    func setEnabled(_ isEnabled: Bool, for moment: Moment, gate: Dharana?) async {
        if isEnabled {
            await refreshAuthorization()
            if authorization == .notDetermined {
                do {
                    _ = try await center.requestAuthorization(options: [.alert, .sound])
                } catch {
                    Self.logger.info("Notification permission request failed: \(error.localizedDescription)")
                }
                await refreshAuthorization()
            }
            guard authorization == .authorized || authorization == .provisional else { return }
        }
        settings[moment]?.isEnabled = isEnabled
        save()
        await schedule(moment, gate: gate)
    }

    func setTime(_ date: Date, for moment: Moment, gate: Dharana?) async {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        settings[moment]?.hour = parts.hour ?? 9
        settings[moment]?.minute = parts.minute ?? 0
        save()
        await schedule(moment, gate: gate)
    }

    /// Replaces the pending reminder for `moment` to match its current setting.
    func schedule(_ moment: Moment, gate: Dharana?) async {
        center.removePendingNotificationRequests(withIdentifiers: [moment.identifier])
        let setting = setting(for: moment)
        guard setting.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = gate.map { "Gate \($0.number) · \($0.title)" } ?? moment.title
        content.subtitle = moment.title
        content.body = gate?.text ?? moment.explanation
        content.sound = .default
        content.threadIdentifier = "moments"
        content.userInfo = ["gate": moment.gate]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: setting.hour, minute: setting.minute),
            repeats: true
        )
        do {
            try await center.add(UNNotificationRequest(identifier: moment.identifier, content: content, trigger: trigger))
        } catch {
            Self.logger.error("Couldn't schedule \(moment.rawValue): \(error.localizedDescription)")
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let gate = response.notification.request.content.userInfo["gate"] as? Int
        completionHandler()
        guard let gate else { return }
        Task { @MainActor in self.openedGate = gate }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // A reminder that arrives while Respire is open still appears, quietly.
        completionHandler([.banner, .list])
    }
}
