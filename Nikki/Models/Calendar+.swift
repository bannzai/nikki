import Foundation

extension Calendar {
    /// 画面表示に使う暦。日付の区切りが端末の設定に追従するようタイムゾーンは autoupdating にし、
    /// 暦種はデザイン見本の「2026年7月」表記を保つためグレゴリオ暦に固定する(端末が和暦設定でも年表記を崩さない)。
    /// 曜日の記号がアプリの表示言語に揃うようロケールは Locale.appLanguage にする。
    static let display: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .autoupdatingCurrent
        c.locale = .appLanguage
        return c
    }()
}
