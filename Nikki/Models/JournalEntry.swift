import Foundation

struct JournalEntry: Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var blocks: [Block]
    var createdAt: Date
    var updatedAt: Date

    /// 一覧の抜粋に使う、本文段落を連結したプレーンテキスト。
    var excerpt: String {
        blocks.compactMap { block -> String? in
            switch block {
            case .paragraph(_, let text): return text
            case .heading(_, _, let text): return text
            default: return nil
            }
        }
        .joined(separator: " ")
    }
}
