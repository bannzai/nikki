import Foundation
import SwiftData

/// 日記1件。本文は markdown 文字列(bodyMarkdown)として保存し、表示時に [Block] へパースする。
/// CloudKit 同期の制約(unique 制約不可・全プロパティに既定値または Optional が必要)に合わせ、
/// 全プロパティに既定値を持たせ、unique 制約は付けない。
@Model
final class JournalEntry {
    private(set) var id: UUID = UUID()
    private(set) var date: Date = Date.now
    private(set) var title: String = ""
    private(set) var bodyMarkdown: String = ""
    private(set) var createdAt: Date = Date.now
    private(set) var updatedAt: Date = Date.now

    // createdAt / updatedAt はサンプルデータで参照日時を固定するため引数から受け取る。
    init(date: Date, title: String, bodyMarkdown: String, createdAt: Date, updatedAt: Date) {
        self.date = date
        self.title = title
        self.bodyMarkdown = bodyMarkdown
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// テンプレートから生成した markdown で日記を作る。
    /// 先頭行が「# 」見出しならタイトルとして取り出し、残り(見出し直後の空行は除く)を本文にする。
    convenience init(templateMarkdown: String, date: Date) {
        var lines = templateMarkdown.components(separatedBy: .newlines)
        var title = ""
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        if firstLine.hasPrefix("# ") {
            title = String(firstLine.dropFirst("# ".count))
            lines.removeFirst()
            while let next = lines.first, next.trimmingCharacters(in: .whitespaces).isEmpty {
                lines.removeFirst()
            }
        }
        self.init(
            date: date,
            title: title,
            bodyMarkdown: lines.joined(separator: "\n"),
            createdAt: .now,
            updatedAt: .now
        )
    }

    /// title を更新し、updatedAt も同時に更新する。
    func setTitle(_ title: String) {
        self.title = title
        updatedAt = .now
    }

    /// bodyMarkdown を更新し、updatedAt も同時に更新する。
    func setBodyMarkdown(_ bodyMarkdown: String) {
        self.bodyMarkdown = bodyMarkdown
        updatedAt = .now
    }

    /// 一覧の抜粋に使う、本文段落を連結したプレーンテキスト。
    var excerpt: String {
        Block.blocks(fromMarkdown: bodyMarkdown).compactMap { block -> String? in
            switch block {
            case .paragraph(_, let text): return text
            case .heading(_, _, let text): return text
            default: return nil
            }
        }
        .joined(separator: " ")
    }
}
