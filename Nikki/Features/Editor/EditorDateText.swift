import Foundation

/// 日付を「7月18日 土曜日」形式で表す。
enum EditorDateText {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        // 表記はデザイン見本の日本語形式で固定し、日付の区切りだけ端末のタイムゾーンに追従させる。
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = .autoupdatingCurrent
        f.dateFormat = "M月d日 EEEE"
        return f
    }()

    static func caption(for date: Date) -> String { formatter.string(from: date) }
}
