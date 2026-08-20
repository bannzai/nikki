import Foundation

extension Date {
    /// String Catalog で言語ごとに用意した DateFormatter のパターンで日付を表記する。
    /// 日本語はデザイン見本の表記(「7月18日 土曜日」等)を保ち、英語は App Store スクリーンショットの表記に合わせるため、
    /// ロケール標準の書式ではなくパターンそのものを翻訳する。
    /// 暦は Calendar.display(グレゴリオ暦・端末のタイムゾーン)に合わせ、月名・曜日名は端末の言語に追従させる。
    func formatted(localizedPattern: String.LocalizationValue) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = Calendar.display
        formatter.timeZone = Calendar.display.timeZone
        formatter.dateFormat = String(localized: localizedPattern)
        return formatter.string(from: self)
    }
}
