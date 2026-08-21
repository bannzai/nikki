import SwiftUI

#if DEBUG
/// デザインカタログの画面と各画面 View の対応表。
/// 環境変数 NIKKI_SCREEN="welcome" のように画面名を渡すと該当画面を直接起動できる。
/// 日付依存の画面には SampleData.referenceToday(2026-07-18)を「今日」として渡す。
enum Screen: String, CaseIterable, Identifiable {
    case welcome
    case encryption
    case biometric
    case lock
    case entryList
    case calendar
    case editorWriting
    case editorSelection
    case editorReorder
    case notebookList
    case templateVariable
    case theme
    case paywall
    case settings
    case archive
    // App Store スクリーンショット(appstore-screenshot-builder パイプラインの撮影対象)。
    // 言語は環境変数 NIKKI_APPSTORE_LANG(ja / en)で切り替える。
    case appstore1
    case appstore2
    case appstore3
    case appstore4
    case appstore5
    case appstore6

    var id: String { rawValue }
}

/// Screen に対応する画面を描画する。カタログ一覧と NIKKI_SCREEN での直接起動の両方から使う。
struct ScreenContent: View {
    let screen: Screen

    var body: some View {
        switch screen {
        case .welcome:
            OnboardingWelcomePage(onboardingStep: .constant(.welcome))
        case .encryption:
            OnboardingEncryptionPage(onboardingStep: .constant(.encryption))
        case .biometric:
            OnboardingBiometricPage(onboardingCompleted: .constant(false))
        case .lock:
            LockPage(locked: .constant(true))
        case .entryList:
            // HomePage は @Query で日記を読むため、in-memory コンテナ(SampleData 投入済み)の下で NavigationStack に載せる。
            NavigationStack {
                HomePage()
            }
            .environment(\.today, SampleData.referenceToday)
            .defaultAppStorage(homePageModeDefaults(mode: .list))
        case .calendar:
            NavigationStack {
                HomePage()
            }
            .environment(\.today, SampleData.referenceToday)
            .defaultAppStorage(homePageModeDefaults(mode: .calendar))
        case .editorWriting:
            EditorWritingPage(entry: SampleData.sampleEntry)
        case .editorSelection:
            EditorSelectionPage(entry: SampleData.sampleEntry)
        case .editorReorder:
            EditorReorderPage(entry: SampleData.sampleEntry)
        case .notebookList:
            // NotebookListPage は @Query でノートを読むため、in-memory コンテナ(SampleData 投入済み)の下で NavigationStack に載せる。
            NavigationStack {
                NotebookListPage(entry: SampleData.sampleEntry)
            }
        case .templateVariable:
            let template = SampleData.reflectionTemplate
            TemplateVariablePage(
                today: SampleData.referenceToday,
                template: template,
                fields: TemplateVariableField.fields(template: template, today: SampleData.referenceToday, includesDemoValues: true)
            )
        case .theme:
            ThemePage()
        case .paywall:
            PaywallPage()
        case .settings:
            // SettingsPage はノート管理・テーマ等へ navigationDestination で遷移するため、NavigationStack に載せる。
            NavigationStack {
                SettingsPage()
            }
        case .archive:
            // ArchivePage は @Query でアーカイブ済みの日記を読むため、NavigationStack に載せる。
            NavigationStack {
                ArchivePage()
            }
        case .appstore1:
            AppStoreScreenshot1Page(language: .fromEnvironment(), canvas: .fromDevice())
        case .appstore2:
            AppStoreScreenshot2Page(language: .fromEnvironment(), canvas: .fromDevice())
        case .appstore3:
            AppStoreScreenshot3Page(language: .fromEnvironment(), canvas: .fromDevice())
        case .appstore4:
            AppStoreScreenshot4Page(language: .fromEnvironment(), canvas: .fromDevice())
        case .appstore5:
            AppStoreScreenshot5Page(language: .fromEnvironment(), canvas: .fromDevice())
        case .appstore6:
            AppStoreScreenshot6Page(language: .fromEnvironment(), canvas: .fromDevice())
        }
    }
}

/// カタログの list / calendar 画面用に、ホームの表示モードを固定した UserDefaults suite を返す。
/// 実利用(.appGroups)の保存値を汚さないよう専用 suite に毎回書き込む(冪等)。
private func homePageModeDefaults(mode: HomePageMode) -> UserDefaults {
    let defaults = UserDefaults(suiteName: "screen-catalog-home-\(mode.rawValue)")!
    defaults.set(mode.rawValue, forKey: UserDefaults.IntEnumKey.homePageMode.key)
    return defaults
}

/// Focus の Preview 一覧と同様に、カタログの全画面を一覧から開ける確認用ページ。
/// 各画面は自前のナビ構成を持つため、push ではなく sheet で全画面をそのまま表示する。
struct ScreenCatalogPage: View {
    /// 一覧から開いている画面。nil のときは一覧のみ表示。
    @State var screen: Screen?

    var body: some View {
        NavigationStack {
            List(Screen.allCases) { screen in
                Button(screen.rawValue) {
                    self.screen = screen
                }
                .foregroundStyle(Color.ink)
            }
            .navigationTitle("Screens")
        }
        .sheet(item: $screen) { screen in
            ScreenContent(screen: screen)
        }
    }
}
#endif
