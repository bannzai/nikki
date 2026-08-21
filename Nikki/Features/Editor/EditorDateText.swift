import Foundation

/// 日付を「7月18日 土曜日」(英語では「Saturday, July 18」)形式で表す。
func editorDateText(date: Date) -> String {
    date.formatted(localizedPattern: "EEEE, MMMM d")
}
