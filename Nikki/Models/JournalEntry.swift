import Foundation
import SwiftData

/// 日記1件。本文は markdown 文字列(bodyMarkdown)として保存し、表示時に [Block] へパースする。
/// CloudKit 同期の制約(unique 制約不可・全プロパティに既定値または Optional が必要)に合わせ、
/// 全プロパティに既定値を持たせ、unique 制約は付けない。
@Model
final class JournalEntry {
    private(set) var id: UUID = UUID()
    private(set) var date: Date = Date.now
    // 日記の中身は CloudKit の encrypted field として保存し、「開発者からも見えない」を担保する。
    // date / createdAt / updatedAt はソートや日付表示のクエリに使うため暗号化しない。
    @Attribute(.allowsCloudEncryption) private(set) var title: String = ""
    @Attribute(.allowsCloudEncryption) private(set) var bodyMarkdown: String = ""
    private(set) var createdAt: Date = Date.now
    private(set) var updatedAt: Date = Date.now
    /// アーカイブ済みかどうか。ホームの一覧・カレンダー・検索から外し、アーカイブ一覧(設定 > アーカイブした日記)にだけ出す。
    /// ホームの @Query の絞り込み条件に使うため暗号化しない。
    private(set) var isArchived: Bool = false

    /// この日記が属するノート。inverse は JournalNotebook.entries 側で宣言する。
    /// ノートを決める前に日記を作れる作成フローのため、未所属(nil)を許す。
    private(set) var notebook: JournalNotebook?

    // createdAt / updatedAt はサンプルデータで参照日時を固定するため引数から受け取る。
    // isArchived はサンプルデータでアーカイブ済みの日記を作るため引数から受け取る。
    // 新規作成の日記はアーカイブされていない状態で始まるため false を既定にする。
    init(date: Date, title: String, bodyMarkdown: String, createdAt: Date, updatedAt: Date, isArchived: Bool = false) {
        self.date = date
        self.title = title
        self.bodyMarkdown = bodyMarkdown
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    /// テンプレートから生成した markdown で日記を作る。
    /// タイトル入力の廃止に伴い、テンプレートの先頭見出しも分解せず全文をそのまま本文にする。
    convenience init(templateMarkdown: String, date: Date) {
        self.init(
            date: date,
            title: "",
            bodyMarkdown: templateMarkdown,
            createdAt: .now,
            updatedAt: .now
        )
    }

    /// 本文をテンプレートから生成した markdown の内容で置き換え、updatedAt も同時に更新する。
    /// タイトル入力の廃止後もタイトル付きの過去データが残るため、置き換え時にタイトルも空へ揃える。
    func replace(templateMarkdown: String) {
        title = ""
        bodyMarkdown = templateMarkdown
        updatedAt = .now
    }

    /// タイトル入力の廃止に伴い、過去に入力されたタイトルを本文先頭の見出しへ移す(エディタを開いたときに呼ぶ)。
    /// タイトルが空なら何もしない(冪等)。
    func mergeTitleIntoBodyMarkdown() {
        if title.isEmpty {
            return
        }
        bodyMarkdown = bodyMarkdown.isEmpty ? "# \(title)" : "# \(title)\n\n\(bodyMarkdown)"
        title = ""
        updatedAt = .now
    }

    /// bodyMarkdown を更新し、updatedAt も同時に更新する。
    func setBodyMarkdown(_ bodyMarkdown: String) {
        self.bodyMarkdown = bodyMarkdown
        updatedAt = .now
    }

    /// isArchived を更新し、updatedAt も同時に更新する。
    func setArchived(_ isArchived: Bool) {
        self.isArchived = isArchived
        updatedAt = .now
    }

    /// 所属するノートを更新し、updatedAt も同時に更新する。
    func setNotebook(notebook: JournalNotebook) {
        self.notebook = notebook
        updatedAt = .now
    }

    /// 本文 markdown をパースした表示用のブロック列。
    /// パーサ呼び出しだけの getter だが、使用側が毎回 Block.blocks(fromMarkdown:) を書かずに済むよう
    /// データの所有者側で導出を提供する(レビュー指示による規約からの逸脱)。
    var blocks: [Block] {
        Block.blocks(fromMarkdown: bodyMarkdown)
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

    /// ホーム検索の照合。タイトルまたは本文 markdown に検索語が含まれるか(大文字小文字は区別しない)。
    func matches(searchText: String) -> Bool {
        title.localizedCaseInsensitiveContains(searchText)
            || bodyMarkdown.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - 全削除

extension ModelContext {
    /// アーカイブ済みも含むすべての日記を削除して保存する。設定「すべての日記を削除」から呼ぶ。
    /// delete(model:) のストアレベル一括削除は context を経由せず CloudKit へ削除が伝播しないため、1件ずつ削除する。
    func deleteAllJournalEntries() throws {
        for entry in try fetch(FetchDescriptor<JournalEntry>()) {
            delete(entry)
        }
        try save()
    }
}

// MARK: - Markdown 書き出し

extension [JournalEntry] {
    /// 設定「Markdown で書き出す」用に、全件を1つの markdown 文書へ連結したテキスト。
    /// 日付(+ タイトル)の H1 見出しに本文を続け、日記ごとに水平線で区切る。
    var exportMarkdown: String {
        let formatter = DateFormatter()
        // 表記は README の {{date}} と同じ 2026-07-19 形式に合わせ、日付の区切りは端末のタイムゾーンに追従させる。
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return map { entry in
            let heading = entry.title.isEmpty
                ? "# \(formatter.string(from: entry.date))"
                : "# \(formatter.string(from: entry.date)) \(entry.title)"
            return "\(heading)\n\n\(entry.bodyMarkdown)"
        }
        .joined(separator: "\n\n---\n\n")
    }
}

// MARK: - HTML 書き出し

extension [JournalEntry] {
    /// 設定「Export as HTML」用に、全件を1つの装飾付き HTML 文書へ連結したテキスト(#95、Plus 限定)。
    /// テーマの紙色を背景に反映し、見出し・段落・チェックリストは構造化したタグで書き出す。
    /// img / details は編集時の元 markdown 行をそのまま <pre> で書き出し、内容を失わない(装飾は最小限)。
    /// languageCode は html 要素の lang 属性に入れる言語コード("en" / "ja" 等)で、書き出した時の表示言語を渡す。
    func exportHTML(paperColorHex: String, languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        let articles = map { entry -> String in
            let heading = entry.title.isEmpty
                ? formatter.string(from: entry.date)
                : "\(formatter.string(from: entry.date)) \(entry.title)"
            return """
            <article>
            <h1>\(heading.htmlEscaped)</h1>
            \(entry.blocks.exportHTMLBody)
            </article>
            """
        }
        .joined(separator: "\n<hr>\n")
        return """
        <!doctype html>
        <html lang="\(languageCode)">
        <head>
        <meta charset="utf-8">
        <title>Nikki</title>
        <style>
        body { background: \(paperColorHex); color: #1C1B1A; font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif; max-width: 640px; margin: 0 auto; padding: 32px 24px; line-height: 1.8; }
        h1 { font-size: 20px; margin-top: 48px; }
        h1:first-child { margin-top: 0; }
        h2, h3, h4 { margin-top: 24px; }
        p { margin: 12px 0; white-space: pre-wrap; }
        ul.checklist { list-style: none; padding-left: 0; }
        ul.checklist li.done { color: #6E6D69; text-decoration: line-through; }
        pre { white-space: pre-wrap; font-family: inherit; background: rgba(28,27,26,0.05); padding: 8px 12px; border-radius: 8px; }
        hr { border: none; border-top: 1px solid rgba(28,27,26,0.12); margin: 40px 0; }
        </style>
        </head>
        <body>
        \(articles)
        </body>
        </html>
        """
    }
}

nonisolated extension [Block] {
    /// [Block] を exportHTML の本文タグへ変換したもの。
    var exportHTMLBody: String {
        map { block -> String in
            switch block {
            case .heading(_, let level, let text):
                // 日記自体の見出し(h1)と重ならないよう、本文の見出しは h2 から始める。
                let tag = "h\(Swift.min(level + 1, 6))"
                return "<\(tag)>\(text.htmlEscaped)</\(tag)>"
            case .paragraph(_, let text):
                return "<p>\(text.htmlEscaped)</p>"
            case .checklist(_, let items):
                let itemTags = items.map { item in
                    "<li class=\"\(item.done ? "done" : "")\"><input type=\"checkbox\" \(item.done ? "checked" : "") disabled> \(item.text.htmlEscaped)</li>"
                }
                .joined()
                return "<ul class=\"checklist\">\(itemTags)</ul>"
            case .image(_, _, let rawMarkdown), .details(_, _, _, let rawMarkdown):
                return "<pre>\(rawMarkdown.htmlEscaped)</pre>"
            }
        }
        .joined(separator: "\n")
    }
}
