import SwiftUI
import SwiftData
import RevenueCat

@main
struct NikkiApp: App {
    /// カタログモードはサンプルデータ入りの in-memory ストア、DEBUG の通常起動は開発用の永続ストア、
    /// Release は CloudKit 同期つきの普段使い用ストアを使う。
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
            modelContainer = Self.developmentContainer()
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

    /// CloudKit private database と同期する、普段使い用の永続ストアを作る。
    private static func defaultContainer() -> ModelContainer {
        persistentContainer(configuration: ModelConfiguration(cloudKitDatabase: .private("iCloud.com.bannzai.Nikki")))
    }

    #if DEBUG
    /// 開発用の永続ストアを作る。
    /// 開発中に作ったデータが普段使いの DB に混ざって普段使いを妨げないよう(issue #40)、
    /// 普段使い用の default.store とは別ファイルに保存し、CloudKit 同期もしない。
    private static func developmentContainer() -> ModelContainer {
        do {
            // 明示 URL のストアは SwiftData が親ディレクトリを作らないため、サンドボックス初回起動に備えて自前で作る。
            try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
            return persistentContainer(
                configuration: ModelConfiguration(
                    url: URL.applicationSupportDirectory.appending(path: "NikkiDev.store"),
                    cloudKitDatabase: .none
                )
            )
        } catch {
            fatalError("開発用ストアのディレクトリ作成に失敗: \(error)")
        }
    }
    #endif

    /// 指定された設定で永続ストアを作る。
    private static func persistentContainer(configuration: ModelConfiguration) -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: JournalEntry.self, JournalNotebook.self, JournalTemplate.self,
                configurations: configuration
            )
            seedNotebooks(context: container.mainContext)
            return container
        } catch {
            fatalError("ModelContainer の生成に失敗: \(error)")
        }
    }

    /// ノートが1件もないときだけ既定ノートを用意する(冪等)。
    /// ノート導入前に作られたストアにはどのノートにも属さないテンプレートが残っているため、
    /// その場合は既定ノートを入れ直さず、テンプレート1件につきノート1件を作って引き継ぐ。
    /// 判定はローカルの件数だけで行うため、同期前の複数端末が同時に初回起動すると重複し得る(既知の割り切り)。
    private static func seedNotebooks(context: ModelContext) {
        if ((try? context.fetchCount(FetchDescriptor<JournalNotebook>())) ?? 0) > 0 {
            return
        }
        let templates = (try? context.fetch(FetchDescriptor<JournalTemplate>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        if templates.isEmpty {
            context.insert(notebooks: SampleData.notebooks)
        } else {
            for template in templates {
                // 引き継いだノートのリマインドは、ユーザーが設定していない挙動を勝手に足さないよう「なし」で始める。
                let notebook = JournalNotebook(name: template.name, reminderFrequency: .none, sortOrder: template.sortOrder)
                context.insert(notebook)
                notebook.add(template: template)
            }
        }
        try? context.save()
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
