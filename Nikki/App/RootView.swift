import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.onboardingCompleted {
            HomeView(entries: SampleData.entries, today: SampleData.referenceToday)
        } else {
            OnboardingWelcomeView()
        }
    }
}
