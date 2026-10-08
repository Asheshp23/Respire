//
//  PatternLibrary.swift
//  Respire
//

import Observation
import SwiftUI

/// The app's four tabs.
enum AppTab: Hashable {
    case today
    case breathe
    case courses
    case settings
}

/// What the Breathe tab can open.
enum BreatheRoute: Hashable {
    case rhythm(BreathPattern.ID)
    case places
}

/// What the Courses tab can open. Practices in the library are pushed by number.
enum CoursesRoute: Hashable {
    case course(Journey.ID)
    case practices
}

/// The breathing rhythms, and where in the app you are: the tab, and each tab's stack.
@Observable
final class PatternLibrary {
    let presets: [BreathPattern] = BreathPattern.presets
    var custom: BreathPattern = .customDefault

    var tab: AppTab = .today
    var breathePath = NavigationPath()
    var coursesPath = NavigationPath()

    var allPatterns: [BreathPattern] { presets + [custom] }

    func pattern(id: BreathPattern.ID) -> BreathPattern? {
        allPatterns.first { $0.id == id }
    }

    /// Opens a rhythm in the Breathe tab; `beginsAtOnce` starts breathing as it appears.
    func open(_ pattern: BreathPattern, beginsAtOnce: Bool = false, in session: SessionViewModel) {
        session.select(pattern)
        session.beginsOnArrival = beginsAtOnce
        var path = NavigationPath()
        path.append(BreatheRoute.rhythm(pattern.id))
        breathePath = path
        tab = .breathe
    }

    func openCourse(_ id: Journey.ID) {
        var path = NavigationPath()
        path.append(CoursesRoute.course(id))
        coursesPath = path
        tab = .courses
    }

    /// Opens one of the 112 practices, inside the library.
    func openPractice(_ number: Int) {
        var path = NavigationPath()
        path.append(CoursesRoute.practices)
        path.append(number)
        coursesPath = path
        tab = .courses
    }
}
