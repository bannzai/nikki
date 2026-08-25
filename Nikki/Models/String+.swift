import Foundation

// 状態を持たない純粋関数のため nonisolated にし、nonisolated な @Model のプロパティ(JournalEntry.bodyMarkdown 等)
// から派生した文字列にも、Block.swift の nonisolated extension と同じ文脈で呼べるようにする。
nonisolated extension String {
    /// HTML 書き出し(#95)用に、5つの予約文字をエンティティへ置き換えた文字列。
    /// 本文がそのままタグの一部として解釈されるのを防ぐ。
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
