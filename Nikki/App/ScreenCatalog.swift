import SwiftUI

/// デザイン画面 ID(1a〜1r)と各画面 View の対応表。
/// 環境変数 NIKKI_SCREEN="1a" を渡すと該当画面を直接起動できる。
/// 日付依存の画面には SampleData.referenceToday(2026-07-18)を「今日」として渡す。
enum Screen: String, CaseIterable, Identifiable {
    case welcome = "1a"
    case encryption = "1b"
    case biometric = "1e"
    case lock = "1f"
    case entryList = "1g"
    case calendar = "1h"
    case editorWriting = "1i"
    case editorSelection = "1j"
    case editorReorder = "1k"
    case templateList = "1l"
    case templateVariable = "1m"
    case theme = "1n"
    case paywall = "1q"
    case settings = "1r"

    var id: String { rawValue }
}

/// Screen に対応する画面を描画する。環境変数 NIKKI_SCREEN での直接起動に使う。
struct ScreenContent: View {
    let screen: Screen

    var body: some View {
        switch screen {
        case .welcome:
            OnboardingWelcomePage()
        case .encryption:
            OnboardingEncryptionPage()
        case .biometric:
            OnboardingBiometricPage()
        case .lock:
            LockPage()
        case .entryList:
            HomePage(entries: SampleData.entries, today: SampleData.referenceToday, initialMode: .list)
        case .calendar:
            HomePage(entries: SampleData.entries, today: SampleData.referenceToday, initialMode: .calendar)
        case .editorWriting:
            EditorPage(entry: SampleData.sampleEntry)
        case .editorSelection:
            EditorSelectionPage(entry: SampleData.sampleEntry)
        case .editorReorder:
            EditorReorderPage(entry: SampleData.sampleEntry)
        case .templateList:
            TemplateListPage(templates: SampleData.templates)
        case .templateVariable:
            TemplateVariablePage(template: SampleData.reflectionTemplate, today: SampleData.referenceToday)
        case .theme:
            ThemePage(selected: .ecru)
        case .paywall:
            PaywallPage()
        case .settings:
            SettingsPage()
        }
    }
}
