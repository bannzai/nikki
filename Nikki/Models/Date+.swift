import Foundation
import Synchronization

/// パターンごとに DateFormatter を再利用する。一覧が全行を構築するため、行ごとに生成すると件数分の初期化が走る。
/// DateFormatter は Sendable ではないため、生成も文字列化もロックの中で行う。
private let localizedPatternDateFormatters = Mutex<[String: DateFormatter]>([:])

extension Date {
    /// String Catalog で言語ごとに用意した DateFormatter のパターンで日付を表記する。
    /// 日本語はデザイン見本の表記(「7月18日 土曜日」等)を保ち、英語は App Store スクリーンショットの表記に合わせるため、
    /// ロケール標準の書式ではなくパターンそのものを翻訳する。
    /// 暦は Calendar.display(グレゴリオ暦・端末のタイムゾーン)に合わせ、月名・曜日名はアプリの表示言語(Locale.appLanguage)に揃える。
    func formatted(localizedPattern: String.LocalizationValue) -> String {
        let dateFormat = String(localized: localizedPattern)
        return localizedPatternDateFormatters.withLock { formatters in
            if let formatter = formatters[dateFormat] {
                return formatter.string(from: self)
            }
            let formatter = DateFormatter()
            formatter.locale = .appLanguage
            formatter.calendar = Calendar.display
            formatter.timeZone = Calendar.display.timeZone
            formatter.dateFormat = dateFormat
            formatters[dateFormat] = formatter
            return formatter.string(from: self)
        }
    }
}
