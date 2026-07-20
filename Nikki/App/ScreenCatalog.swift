import SwiftUI

/// デザイン画面 ID(1a〜1r)と各画面 View の対応表。
/// 環境変数 NIKKI_SCREEN="1a" を渡すと該当画面を直接起動できる。
/// 日付依存の画面には SampleData.referenceToday(2026-07-18)を「今日」として渡す。
enum Screen: String, CaseIterable, Identifiable {
    case welcome = "1a"
    case encryption = "1b"
    case phraseBackup = "1c"
    case phraseConfirm = "1d"
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
    case restore = "1p"
    case paywall = "1q"
    case settings = "1r"

    var id: String { rawValue }

    @ViewBuilder
    var view: some View {
        switch self {
        case .welcome:
            OnboardingWelcomeView()
        case .encryption:
            OnboardingEncryptionView()
        case .phraseBackup:
            OnboardingPhraseBackupView(phrase: SampleData.mnemonic)
        case .phraseConfirm:
            OnboardingPhraseConfirmView(phrase: SampleData.mnemonic)
        case .biometric:
            OnboardingBiometricView()
        case .lock:
            LockScreenView()
        case .entryList:
            EntryListView(entries: SampleData.entries, today: SampleData.referenceToday)
        case .calendar:
            CalendarMonthView(entries: SampleData.entries, today: SampleData.referenceToday)
        case .editorWriting:
            EditorView(entry: SampleData.sampleEntry)
        case .editorSelection:
            EditorSelectionToolbarView(entry: SampleData.sampleEntry)
        case .editorReorder:
            EditorBlockReorderView(entry: SampleData.sampleEntry)
        case .templateList:
            TemplateListView(templates: SampleData.templates)
        case .templateVariable:
            TemplateVariableSheetView(template: SampleData.reflectionTemplate, today: SampleData.referenceToday)
        case .theme:
            ThemeSettingsView(selected: .ecru)
        case .restore:
            RestoreView(suggestions: SampleData.restoreSuggestions)
        case .paywall:
            PaywallView()
        case .settings:
            SettingsView()
        }
    }
}
