import SwiftUI

@main
struct NikkiApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            content
                .environment(appState)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let raw = ProcessInfo.processInfo.environment["NIKKI_SCREEN"],
           let screen = Screen(rawValue: raw) {
            screen.view
        } else {
            RootView()
        }
    }
}
