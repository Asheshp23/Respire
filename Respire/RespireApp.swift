//
//  RespireApp.swift
//  Respire
//
//  Created by Ashesh Patel on 2026-10-06.
//

import SwiftUI

@main
struct RespireApp: App {
    @State private var library = PatternLibrary()
    @State private var session = SessionViewModel()
    @State private var journeys = JourneyLibrary()
    @State private var journeyProgress = JourneyProgressStore()
    @State private var gates = DharanaLibrary()
    /// Created at launch so it becomes the notification delegate before any reminder is tapped.
    @State private var reminders = MomentReminders()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(session)
                .environment(journeys)
                .environment(journeyProgress)
                .environment(gates)
                .environment(reminders)
                // A dark room, so the light of each breath world has something to shine against.
                .preferredColorScheme(.dark)
        }
    }
}
