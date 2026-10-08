//
//  RootView.swift
//  Respire
//

import SwiftUI

/// Four tabs, as in any app: Today, Breathe, Courses, and Settings. A bottom tab bar on
/// iPhone; on iPad a top tab bar that can open into a sidebar. Each tab keeps its own stack.
struct RootView: View {
    @Environment(PatternLibrary.self) private var library
    @Environment(MomentReminders.self) private var reminders
    @Environment(SessionViewModel.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("onboarding.done") private var onboardingDone = false

    var body: some View {
        @Bindable var library = library

        TabView(selection: $library.tab) {
            Tab("Today", systemImage: "sun.horizon", value: AppTab.today) {
                NavigationStack {
                    TodayView()
                }
            }
            Tab("Breathe", systemImage: "wind", value: AppTab.breathe) {
                NavigationStack(path: $library.breathePath) {
                    BreatheView()
                }
            }
            Tab("Courses", systemImage: "book", value: AppTab.courses) {
                NavigationStack(path: $library.coursesPath) {
                    CoursesView()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: session.engine.state) { _, state in
            // With eyes closed nobody touches the screen, so keep it from locking mid-session.
            UIApplication.shared.isIdleTimerDisabled = state == .running || state == .paused
        }
        // A tapped moment reminder opens its practice.
        .onChange(of: reminders.openedGate) { _, gate in
            guard let gate else { return }
            library.openPractice(gate)
            reminders.openedGate = nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { session.enterBackground() }
        }
        .fullScreenCover(isPresented: Binding(get: { !onboardingDone }, set: { onboardingDone = !$0 })) {
            OnboardingView { onboardingDone = true }
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
