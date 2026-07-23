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
    case templateList
    case templateVariable
    case theme
    case paywall
    case settings

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
            LockPage()
        case .entryList:
            // HomePage は @Query で日記を読むため、in-memory コンテナ(SampleData 投入済み)の下で NavigationStack に載せる。
            NavigationStack {
                HomePage(today: SampleData.referenceToday, selectedIndex: HomePageMode.list.rawValue)
            }
        case .calendar:
            NavigationStack {
                HomePage(today: SampleData.referenceToday, selectedIndex: HomePageMode.calendar.rawValue)
            }
        case .editorWriting:
            EditorWritingPage(entry: SampleData.sampleEntry)
        case .editorSelection:
            EditorSelectionPage(entry: SampleData.sampleEntry)
        case .editorReorder:
            EditorReorderPage(entry: SampleData.sampleEntry)
        case .templateList:
            NavigationStack {
                TemplateListPage()
            }
        case .templateVariable:
            let template = SampleData.reflectionTemplate
            TemplateVariablePage(
                today: SampleData.referenceToday,
                template: template,
                fields: TemplateVariableField.fields(template: template, today: SampleData.referenceToday, includesDemoValues: true)
            )
        case .theme:
            // 見本(1n)の初期選択は生成(プリセット2番目)。
            ThemePage(selectedPaperColor: Color.paperColorPreset[1])
        case .paywall:
            PaywallPage()
        case .settings:
            SettingsPage()
        }
    }
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
