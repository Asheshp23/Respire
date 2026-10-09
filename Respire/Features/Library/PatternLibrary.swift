//
//  PatternLibrary.swift
//  Respire
//

import Observation
import SwiftUI

/// The three tabs: Breathe (the home, two zones), Library (everything else), Settings.
enum AppTab: Hashable {
    case breathe
    case library
    case settings
}

/// Everywhere a stack can go. The 112 practices are pushed by number.
enum ExploreRoute: Hashable {
    case practice(Practice.ID)
    case place(Place.ID)
    case course(Journey.ID)
    case rhythm(BreathPattern.ID)
    case places
    case practices
}

/// The breathing rhythms, and where in the app you are: the tab, and each tab's stack.
@Observable
final class PatternLibrary {
    let presets: [BreathPattern] = BreathPattern.presets
    var custom: BreathPattern = .customDefault

    var tab: AppTab = .breathe
    /// The home's stack: sessions started with one tap.
    var homePath = NavigationPath()
    /// The library's stack: everything browsed.
    var libraryPath = NavigationPath()

    var allPatterns: [BreathPattern] { presets + [custom] }

    func pattern(id: BreathPattern.ID) -> BreathPattern? {
        allPatterns.first { $0.id == id }
    }

    /// Starts something from the home with one tap: it opens already beginning.
    func start(_ route: ExploreRoute, in session: SessionViewModel) {
        if case .rhythm(let id) = route, let pattern = pattern(id: id) { session.select(pattern) }
        session.beginsOnArrival = true
        homePath.append(route)
    }

    /// Opens a rhythm in the Library; `beginsAtOnce` starts breathing as it appears.
    func open(_ pattern: BreathPattern, beginsAtOnce: Bool = false, in session: SessionViewModel) {
        session.select(pattern)
        session.beginsOnArrival = beginsAtOnce
        show(.rhythm(pattern.id))
    }

    func openCourse(_ id: Journey.ID) {
        show(.course(id))
    }

    /// Opens one of the 112 practices, inside the library.
    func openPractice(_ number: Int) {
        var path = NavigationPath()
        path.append(ExploreRoute.practices)
        path.append(number)
        libraryPath = path
        tab = .library
    }

    /// Shows a route on its own in the Library.
    func show(_ route: ExploreRoute) {
        var path = NavigationPath()
        path.append(route)
        libraryPath = path
        tab = .library
    }

    /// Back to the home.
    func goHome() {
        homePath = NavigationPath()
        tab = .breathe
    }
}
