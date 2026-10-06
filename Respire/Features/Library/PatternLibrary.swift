//
//  PatternLibrary.swift
//  Respire
//

import Foundation
import Observation

/// What the sidebar can show in the detail area.
enum SidebarItem: Hashable {
    case gates
    case journey(Journey.ID)
    case pattern(BreathPattern.ID)
}

/// Source of truth for available rhythms and the sidebar's current selection.
@Observable
final class PatternLibrary {
    let presets: [BreathPattern] = BreathPattern.presets
    var custom: BreathPattern = .customDefault
    var selection: SidebarItem? = .pattern(BreathPattern.box.id)
    /// Gates pushed inside the 112 Gates library (gate numbers).
    var gatePath: [Int] = []

    var allPatterns: [BreathPattern] { presets + [custom] }

    var selectedPattern: BreathPattern? {
        guard case .pattern(let id) = selection else { return nil }
        return allPatterns.first { $0.id == id }
    }

    var selectedJourneyID: Journey.ID? {
        guard case .journey(let id) = selection else { return nil }
        return id
    }
}
