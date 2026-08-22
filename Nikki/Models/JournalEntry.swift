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
