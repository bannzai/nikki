import SwiftUI
import SwiftData

@main
struct NikkiApp: App {
    @State private var appState = AppState()

    /// カタログモードはサンプルデータ入りの in-memory ストア、通常起動は CloudKit 同期つきの永続ストアを使う。
    let modelContainer: ModelContainer

    init() {
        if ProcessInfo.processInfo.environment["NIKKI_SCREEN"] != nil {
            modelContainer = SampleData.inMemoryContainer()
        } else {
            modelContainer = Self.defaultContainer()
        }
    }

    var body: some Scene {
        WindowGroup {
            NikkiAppContent()
                .environment(appState)
        }
        .modelContainer(modelContainer)
    }

    /// CloudKit private database と同期する永続ストアを作る。
    /// テンプレートが1件もない初回起動時は既定テンプレートをシードする。
    /// シードはローカルの件数判定のみで行うため、同期前の複数端末が同時に初回起動すると重複し得る(既知の割り切り)。
    private static func defaultContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: JournalEntry.self, JournalTemplate.self,
                configurations: ModelConfiguration(cloudKitDatabase: .private("iCloud.com.bannzai.Nikki"))
            )
            let templateCount = (try? container.mainContext.fetchCount(FetchDescriptor<JournalTemplate>())) ?? 0
            if templateCount == 0 {
                for template in SampleData.templates {
                    container.mainContext.insert(template)
                }
                try? container.mainContext.save()
            }
            return container
        } catch {
            fatalError("ModelContainer の生成に失敗: \(error)")
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
