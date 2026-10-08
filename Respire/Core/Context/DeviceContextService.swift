//
//  DeviceContextService.swift
//  Respire
//
//  Aggregates "this moment" for the session opening: time of day, local weather,
//  and the resting pulse. Privacy by construction:
//
//  - Location is requested only while in use, at reduced accuracy by default
//    (NSLocationDefaultAccuracyReduced), then rounded further to ~1 km before
//    use. It is never stored; only the derived weather words survive.
//  - Weather comes from WeatherKit, Apple's weather service. That is the one
//    network request in this flow, and it carries only the rounded coordinate.
//    Results are cached in memory for 30 minutes so repeat sessions don't ask again.
//  - The pulse comes from the on-device camera baseline and is used only if
//    it was measured in the last 30 minutes.
//  - Every source is optional and time-boxed. A denied permission or a slow
//    network simply leaves that detail out; it never delays the opening.
//

import CoreLocation
import Foundation
import os
import WeatherKit

/// What the opening view needs alongside the model context: the weather credit
/// WeatherKit requires whenever its data is shown or used.
nonisolated struct GatheredContext: Sendable {
    var context: SomaticContext
    var weatherCredit: WeatherCredit?
}

nonisolated struct WeatherCredit: Sendable, Equatable {
    var markURL: URL
    var legalURL: URL
}

actor DeviceContextService {
    private static let weatherLifetime: TimeInterval = 30 * 60
    private static let pulseLifetime: TimeInterval = 30 * 60
    private static let logger = Logger(subsystem: "Respire", category: "Context")

    private var cachedWeather: (weather: SomaticContext.Weather, credit: WeatherCredit?, fetchedAt: Date)?

    func gather(
        focus: SessionFocus,
        baseline: PulseReading?,
        sceneTitle: String,
        pattern: BreathPattern,
        gate: SomaticContext.Gate? = nil,
        now: Date = .now
    ) async -> GatheredContext {
        let (weather, credit) = await currentWeather(now: now)
        let heartRate = baseline.flatMap { reading in
            now.timeIntervalSince(reading.date) < Self.pulseLifetime ? reading.beatsPerMinute : nil
        }

        let context = SomaticContext(
            focus: focus,
            timeOfDay: .init(hour: Calendar.current.component(.hour, from: now)),
            weekday: now.formatted(.dateTime.weekday(.wide)),
            heartRate: heartRate,
            weather: weather,
            sceneTitle: sceneTitle,
            patternName: pattern.name,
            inhaleSeconds: pattern.inhale,
            gate: gate
        )
        return GatheredContext(context: context, weatherCredit: weather == nil ? nil : credit)
    }

    // MARK: - Weather

    private func currentWeather(now: Date) async -> (SomaticContext.Weather?, WeatherCredit?) {
        if let cachedWeather, now.timeIntervalSince(cachedWeather.fetchedAt) < Self.weatherLifetime {
            return (cachedWeather.weather, cachedWeather.credit)
        }
        guard let location = await coarseLocation() else { return (nil, nil) }

        let fetched = await withTimeout(seconds: 5) { () -> (SomaticContext.Weather, WeatherCredit?)? in
            do {
                let current = try await WeatherService.shared.weather(for: location, including: .current)
                let attribution = try? await WeatherService.shared.attribution
                let credit = attribution.map { WeatherCredit(markURL: $0.combinedMarkDarkURL, legalURL: $0.legalPageURL) }
                return (Self.describe(current), credit)
            } catch {
                Self.logger.info("Weather unavailable: \(error.localizedDescription)")
                return nil
            }
        }
        guard let fetched else { return (nil, nil) }
        cachedWeather = (fetched.0, fetched.1, now)
        return fetched
    }

    /// Reduces WeatherKit's rich model to a few sensory words.
    private static func describe(_ current: CurrentWeather) -> SomaticContext.Weather {
        let windy = current.wind.speed.converted(to: .kilometersPerHour).value >= 25
        return SomaticContext.Weather(
            kind: kind(of: current.condition),
            condition: current.condition.description.lowercased(),
            temperature: current.temperature.formatted(.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(0)))),
            isDaylight: current.isDaylight,
            isWindy: windy
        )
    }

    private static func kind(of condition: WeatherCondition) -> SomaticContext.Weather.Kind {
        switch condition {
        case .clear, .mostlyClear, .hot:
            .clear
        case .drizzle, .rain, .heavyRain, .sunShowers, .freezingDrizzle, .freezingRain:
            .rain
        case .flurries, .snow, .heavySnow, .sleet, .wintryMix, .blizzard, .blowingSnow, .sunFlurries, .frigid, .hail:
            .snow
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .tropicalStorm, .hurricane:
            .storm
        case .foggy, .haze, .smoky, .blowingDust:
            .haze
        case .breezy, .windy:
            .wind
        default:
            .cloudy
        }
    }

    // MARK: - Location

    /// Asks for approximate location up front, during onboarding, so the first opening
    /// doesn't wait on the prompt. The location found is discarded.
    func requestLocationAccess() async {
        _ = await coarseLocation()
    }

    /// A one-shot, while-in-use, approximate location, rounded to ~1 km.
    private func coarseLocation() async -> CLLocation? {
        let status = await MainActor.run { CLLocationManager().authorizationStatus }
        switch status {
        case .denied, .restricted:
            return nil
        default:
            break
        }
        // The first time, leave room for the person to answer the permission prompt.
        let timeout: Double = status == .notDetermined ? 20 : 4

        return await withTimeout(seconds: timeout) {
            // Declares the workflow's need; Core Location shows the prompt if it hasn't been answered.
            let session = CLServiceSession(authorization: .whenInUse)
            defer { session.invalidate() }
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if let location = update.location {
                        return Self.rounded(location)
                    }
                    if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                        return nil
                    }
                }
            } catch {
                Self.logger.info("Location unavailable: \(error.localizedDescription)")
            }
            return nil
        }
    }

    private static func rounded(_ location: CLLocation) -> CLLocation {
        func round(_ degrees: CLLocationDegrees) -> CLLocationDegrees { (degrees * 100).rounded() / 100 }
        return CLLocation(latitude: round(location.coordinate.latitude), longitude: round(location.coordinate.longitude))
    }
}

/// Runs `operation`, returning `nil` if it doesn't finish within `seconds`.
nonisolated func withTimeout<T: Sendable>(seconds: Double, _ operation: @escaping @Sendable () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask { await operation() }
        group.addTask {
            try? await Task.sleep(for: .seconds(seconds))
            return nil
        }
        let first = await group.next() ?? nil
        group.cancelAll()
        return first
    }
}
