import SwiftUI

@main
struct NikkiApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NikkiAppContent()
                .environment(appState)
        }
    }
}

/// 起動画面の振り分け。環境変数 NIKKI_SCREEN があれば ScreenCatalog の該当画面、無ければ通常フロー。
private struct NikkiAppContent: View {
    var body: some View {
        if let raw = ProcessInfo.processInfo.environment["NIKKI_SCREEN"],
           let screen = Screen(rawValue: raw) {
            ScreenContent(screen: screen)
        } else {
            RootPage()
        }
    }
}
