import Foundation

// 表記はデザイン見本の日本語形式で固定し、日付の区切りだけ端末のタイムゾーンに追従させる。
private let editorDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.timeZone = .autoupdatingCurrent
    f.dateFormat = "M月d日 EEEE"
    return f
}()

/// 日付を「7月18日 土曜日」形式で表す。
func editorDateText(date: Date) -> String {
    editorDateFormatter.string(from: date)
}
