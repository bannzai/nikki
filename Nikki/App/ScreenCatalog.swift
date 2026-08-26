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
    case editor
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
        case .editor:
            // EditorWritingPage(静的カタログ)と違い、ナビ右端の「テンプレート」ボタンを含む製品のエディタ。
            // EditorPage は @Environment(\.modelContext) で書き戻すため、in-memory コンテナの下に置く。
            ScreenCatalogPushedStack {
                EditorPage(entry: SampleData.sampleEntry)
            }
        case .editorWriting:
            ScreenCatalogPushedStack {
                EditorWritingPage(entry: SampleData.sampleEntry)
            }
        case .editorSelection:
            ScreenCatalogPushedStack {
                EditorSelectionPage(entry: SampleData.sampleEntry)
            }
        case .editorReorder:
            ScreenCatalogPushedStack {
                EditorReorderPage(entry: SampleData.sampleEntry)
            }
        case .notebookList:
            // NotebookListPage は @Query でノートを読むため、in-memory コンテナ(SampleData 投入済み)の下に置く。
            ScreenCatalogPushedStack {
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
            ScreenCatalogPushedStack {
                ThemePage()
            }
        case .paywall:
            PaywallPage()
        case .settings:
            ScreenCatalogPushedStack {
                SettingsPage()
            }
        case .archive:
            // ArchivePage は @Query でアーカイブ済みの日記を読む。
            ScreenCatalogPushedStack {
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

/// 製品では push 先として開く画面を、カタログでも push された状態で表示するスタック。
/// システムの戻るボタンはスタックに戻り先があるときだけ出るため、遷移元の紙地を1枚挟んで
/// 製品と同じ「戻るボタンのあるナビゲーションバー」を再現する。
private struct ScreenCatalogPushedStack<Content: View>: View {
    @ViewBuilder let content: Content

    /// 対象の画面を出しているかどうか。戻るボタンで pop すると遷移元の紙地に戻る。
    @State var contentIsPresented = true

    var body: some View {
        NavigationStack {
            Color.inkPaper
                .ignoresSafeArea()
                // 遷移元に題があると戻るボタンがその題のラベル付きで出る。製品の遷移元(ホーム)は
                // 題を持たずシェブロンだけの戻るボタンになるため、空の題で見た目を揃える。
                .navigationTitle("")
                .navigationDestination(isPresented: $contentIsPresented) {
                    content
                }
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

/// 通常フロー(RootPage)を検証用に起動するときの UserDefaults suite を返す。
/// オンボーディングを完了済みにしてホームから始め、実利用(.appGroups)の設定を汚さないよう
/// 専用 suite に毎回書き込む(冪等)。
func rootFlowDefaults() -> UserDefaults {
    let defaults = UserDefaults(suiteName: "screen-catalog-root-flow")!
    defaults.set(true, forKey: UserDefaults.BoolKey.onboardingCompleted.key)
    return defaults
}

/// Focus の Preview 一覧と同様に、カタログの全画面を一覧から開ける確認用ページ。
/// 各画面は ScreenContent 側でナビゲーションの有無まで含めて組み立てるため、push ではなく sheet で全画面をそのまま表示する。
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
