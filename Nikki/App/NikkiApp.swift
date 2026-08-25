import SwiftUI
import SwiftData
import RevenueCat

@main
struct NikkiApp: App {
    /// カタログモードはサンプルデータ入りの in-memory ストア、DEBUG の通常起動は開発用の永続ストア、
    /// Release は CloudKit 同期つきの普段使い用ストアを使う。
    let modelContainer: ModelContainer
    /// 現在の modelContainer が実際に CloudKit と同期しているかどうか(#93)。environment で配下へ配る。
    let cloudSyncActive: Bool

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
            cloudSyncActive = false
        } else {
            modelContainer = Self.developmentContainer()
            cloudSyncActive = false
            Purchases.configure(withAPIKey: Const.revenueCatAPIKey)
        }
        #else
        // 直近キャッシュされた Plus 加入状態で同期の有無を決める(effectiveCloudKitDatabase 参照)。
        cloudSyncActive = UserDefaults.appGroups.bool(forKey: UserDefaults.BoolKey.cloudSyncPlusActiveCache.key)
        modelContainer = Self.defaultContainer(plusActive: cloudSyncActive)
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
        .environment(\.cloudSyncActive, cloudSyncActive)
        // 書き物アプリとして一覧・本文が読みやすい縦長の初期サイズ。
        .defaultSize(width: 520, height: 800)
        #else
        WindowGroup {
            NikkiAppContent()
                .defaultAppStorage(.appGroups)
        }
        .modelContainer(modelContainer)
        .environment(\.cloudSyncActive, cloudSyncActive)
        #endif
    }

    /// CloudKit private database と同期する、普段使い用の永続ストアを作る。
    /// 同期は Nikki Plus 限定(#93)。plusActive は起動時にキャッシュされた値で、実行中の加入状態変化は
    /// 反映されない(ModelContainer は起動時に一度だけ構成されるため。次回起動で新しいキャッシュ値が使われる)。
    private static func defaultContainer(plusActive: Bool) -> ModelContainer {
        persistentContainer(configuration: ModelConfiguration(cloudKitDatabase: effectiveCloudKitDatabase(plusActive: plusActive)))
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
            renameLegacyBlankPageNotebooks(context: container.mainContext)
            return container
        } catch {
            fatalError("ModelContainer の生成に失敗: \(error)")
        }
    }

    /// 旧バージョンがシードした既定テンプレート「白紙」を、issue #92 の改名に合わせて「日記」へ移行する(冪等)。
    /// 一度シードを終えた端末では起動時シードが走らず改名が届かないため、シードとは別の移行として行う。
    /// 対象は、旧既定名のままで書き出しも既定の "# {{date}}" のままのノートに限り、
    /// ユーザーが名前や書き出しを変えたノートには触らない。
    /// 移行後に別端末から旧名のノートが同期されてくると取りこぼすが、シードの重複と同じ既知の割り切りとする。
    /// 完了の目印は、移行(または対象が無いことの確認)に成功したときだけ残し、取得・保存の一時失敗は次回起動で再試行する。
    private static func renameLegacyBlankPageNotebooks(context: ModelContext) {
        if UserDefaults.appGroups.bool(forKey: UserDefaults.BoolKey.blankPageRenamedToJournal.key) {
            return
        }
        guard let notebooks = try? context.fetch(FetchDescriptor<JournalNotebook>()) else {
            return
        }
        // 旧既定名は改名前のバージョンが永続化した値で、現在の String Catalog にはもう存在しない歴史的定数のため直書きする。
        let legacyNames: Set<String> = ["Blank page", "白紙"]
        let renamed = notebooks.filter { legacyNames.contains($0.name) && $0.template?.markdown == "# {{date}}" }
        for notebook in renamed {
            notebook.setName(name: String(localized: "Journal"))
        }
        if renamed.isEmpty || (try? context.save()) != nil {
            UserDefaults.appGroups.set(true, forKey: UserDefaults.BoolKey.blankPageRenamedToJournal.key)
        }
    }

    /// ノートが1件もないときだけ、既定の4冊(日記・朝の3行・1日の振り返り・旅の記録)を用意する(冪等)。
    /// 先頭の「日記」が新規日記の既定の所属先になる(issue #92)。
    /// ノート導入前に作られたストアにはどのノートにも属さないテンプレートが残っているため、
    /// その場合は既定ノートを入れ直さず、テンプレート1件につきノート1件を作って引き継ぐ。
    /// 判定はローカルの件数だけで行うため、同期前の複数端末が同時に初回起動すると重複し得る(既知の割り切り)。
    /// 一度シード(または既存データの確認)を終えた端末では、「すべてのテンプレートを削除」で空にした状態を
    /// 次回起動が勝手に復活させないよう何もしない。消したテンプレートは設定 > テンプレート の
    /// 「既定のテンプレートを復元」で戻せる。UserDefaults(.appGroups)の目印は DEBUG の開発用ストアと
    /// Release ストアで共有される割り切りがあるが、1台の端末で両ストアを使い分けるのは開発機だけに留まる。
    /// 完了の目印は、既存データの確認またはシードの保存に成功したときだけ残す。取得・保存の一時失敗でも
    /// 目印が残ると、既定テンプレートがないまま次回以降の起動が何もしなくなるため、失敗時は次回起動で再試行する。
    private static func seedNotebooks(context: ModelContext) {
        if UserDefaults.appGroups.bool(forKey: UserDefaults.BoolKey.notebooksSeeded.key) {
            return
        }
        guard let notebookCount = try? context.fetchCount(FetchDescriptor<JournalNotebook>()) else {
            return
        }
        if notebookCount > 0 {
            UserDefaults.appGroups.set(true, forKey: UserDefaults.BoolKey.notebooksSeeded.key)
            return
        }
        guard let templates = try? context.fetch(FetchDescriptor<JournalTemplate>(sortBy: [SortDescriptor(\.sortOrder)])) else {
            return
        }
        if templates.isEmpty {
            context.insert(notebooks: SampleData.seedNotebooks(sortOrder: 0))
        } else {
            for template in templates {
                // 引き継いだノートのリマインドは、ユーザーが設定していない挙動を勝手に足さないよう「なし」で始める。
                let notebook = JournalNotebook(name: template.name, reminderFrequency: .none, sortOrder: template.sortOrder)
                context.insert(notebook)
                notebook.add(template: template)
            }
        }
        if (try? context.save()) != nil {
            UserDefaults.appGroups.set(true, forKey: UserDefaults.BoolKey.notebooksSeeded.key)
        }
    }
}

/// 普段使い用ストアが同期する CloudKit private database。Plus 未加入(またはキャッシュ未取得)では同期しない(#93)。
/// plusActive は NikkiApp.init が UserDefaults から読む、直近の customerInfo 由来のキャッシュ値。
func effectiveCloudKitDatabase(plusActive: Bool) -> ModelConfiguration.CloudKitDatabase {
    plusActive ? .private("iCloud.com.bannzai.Nikki") : .none
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
