import Foundation

extension Locale {
    /// アプリが表示に使っている言語のロケール。
    /// String Catalog は未対応の言語の端末では英語へフォールバックするため、月名・曜日名もそれに揃うよう
    /// 端末のロケールではなく Bundle が選んだローカライズから作る(フランス語端末で英語 UI にフランス語の日付が混ざるのを防ぐ)。
    /// preferredLocalizations が空になることは実際にはないが、型を満たすためのフォールバックは開発言語 (en) にする。
    static let appLanguage = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
}
