import SwiftUI
import SwiftData
import RevenueCat

@main
struct NikkiApp: App {
    /// カタログモードはサンプルデータ入りの in-memory ストア、通常起動は CloudKit 同期つきの永続ストアを使う。
    let modelContainer: ModelContainer

    init() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        // カタログモードと、ユニットテストがホストアプリとして起動したときは、
        // CloudKit の本番ストアに触れない(シードもしない)よう in-memory ストアを使う。
        // RevenueCat もネットワークに触れないよう configure しない(参照側は Purchases.isConfigured で分岐する)。
        if environment["NIKKI_SCREEN"] != nil
            || environment["XCTestSessionIdentifier"] != nil
            || environment["XCTestConfigurationFilePath"] != nil {
            modelContainer = SampleData.inMemoryContainer()
        } else {
            modelContainer = Self.defaultContainer()
            Purchases.configure(withAPIKey: Const.revenueCatAPIKey)
        }
        #else
        modelContainer = Self.defaultContainer()
        Purchases.configure(withAPIKey: Const.revenueCatAPIKey)
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        // WindowGroup は File > New Window の ⌘N を自動で提供し、新規日記の ⌘N (HomePage) と衝突するため、
        // iOS(UIApplicationSupportsMultipleScenes = false)と同じ1ウィンドウ構成の Window を使う。
        Window("Nikki", id: "main") {
            NikkiAppContent()
                .defaultAppStorage(.appGroups)
                // 縦長1カラムのデザインが崩れない範囲で自由リサイズを許す下限。幅は iPhone 標準(375pt)、高さはロック画面の要素が収まる実用下限。
                .frame(minWidth: 375, minHeight: 600)
        }
        .modelContainer(modelContainer)
        // 書き物アプリとして一覧・本文が読みやすい縦長の初期サイズ。
        .defaultSize(width: 520, height: 800)
        #else
        WindowGroup {
            NikkiAppContent()
                .defaultAppStorage(.appGroups)
        }
        .modelContainer(modelContainer)
        #endif
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
            if ((try? container.mainContext.fetchCount(FetchDescriptor<JournalTemplate>())) ?? 0) == 0 {
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

/// 起動画面の振り分け。環境変数 NIKKI_SCREEN が画面名ならその画面、それ以外の値ならカタログ一覧、無ければ通常フロー。
private struct NikkiAppContent: View {
    var body: some View {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["NIKKI_SCREEN"] {
            if let screen = Screen(rawValue: raw) {
                ScreenContent(screen: screen)
            } else {
                ScreenCatalogPage()
            }
        } else {
            RootPage()
        }
        #else
        RootPage()
        #endif
    }
}
