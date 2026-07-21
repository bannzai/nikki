import Foundation

/// 日付を「7月18日 土曜日」形式(JST)で表す。
enum EditorDateText {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        f.dateFormat = "M月d日 EEEE"
        return f
    }()

    static func caption(for date: Date) -> String { formatter.string(from: date) }
}
