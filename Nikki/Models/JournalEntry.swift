import Foundation

struct JournalEntry: Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var blocks: [Block]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        blocks: [Block],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.blocks = blocks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

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
