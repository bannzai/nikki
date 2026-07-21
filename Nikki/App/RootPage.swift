import SwiftUI

struct RootPage: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.onboardingCompleted {
            HomePage(entries: SampleData.entries, today: SampleData.referenceToday)
        } else {
            OnboardingWelcomePage()
        }
    }
}
