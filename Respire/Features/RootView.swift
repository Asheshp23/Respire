//
//  RootView.swift
//  Respire
//

import SwiftUI

/// Adaptive shell: a sidebar + immersive detail on iPad, collapsing automatically into a
/// push-navigation stack on iPhone and in compact iPad multitasking widths.
struct RootView: View {
    @Environment(PatternLibrary.self) private var library
    @Environment(JourneyLibrary.self) private var journeys
    @Environment(MomentReminders.self) private var reminders
    @Environment(SessionViewModel.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        @Bindable var library = library

        NavigationSplitView(columnVisibility: $columnVisibility) {
            PatternListView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            if library.selection == .gates {
                NavigationStack(path: $library.gatePath) {
                    DharanaLibraryView()
                }
            } else if let journeyID = library.selectedJourneyID, let journey = journeys.journey(id: journeyID) {
                // Journeys push their own practice sessions, so they get a stack of their own.
                NavigationStack {
                    JourneyMapView(journey: journey)
                }
                .id(journey.id)
            } else if library.selectedPattern != nil {
                SessionView()
            } else {
                ContentUnavailableView("Choose a rhythm", systemImage: "wind", description: Text("Pick a breathing pattern or a journey to begin."))
                    .paperBackground()
            }
        }
        .onChange(of: library.selectedPattern, initial: true) { _, pattern in
            if let pattern { session.select(pattern) }
        }
        .onChange(of: session.engine.state) { _, state in
            // Let the canvas take over the whole iPad screen while breathing.
            withAnimation(.smooth) {
                columnVisibility = state == .running ? .detailOnly : .automatic
            }
        }
        // A tapped moment reminder opens its gate.
        .onChange(of: reminders.openedGate) { _, gate in
            guard let gate else { return }
            library.selection = .gates
            library.gatePath = [gate]
            reminders.openedGate = nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { session.enterBackground() }
        }
    }
}

#Preview {
    RootView()
        .environment(PatternLibrary())
        .environment(SessionViewModel())
        .environment(JourneyLibrary())
        .environment(JourneyProgressStore())
        .environment(DharanaLibrary())
        .environment(MomentReminders())
        .preferredColorScheme(.dark)
}
