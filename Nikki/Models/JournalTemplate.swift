import Foundation
import SwiftData

/// 日記のテンプレート。markdown 本文に {{date}} 等の変数を含められる。
/// CloudKit 同期の制約(unique 制約不可・全プロパティに既定値または Optional が必要)に合わせ、
/// 全プロパティに既定値を持たせ、unique 制約は付けない。
@Model
final class JournalTemplate {
    private(set) var id: UUID = UUID()
    private(set) var name: String = ""
    /// {{date}} {{weather}} 等の変数を含むマークダウン本文。
    private(set) var markdown: String = ""
    /// ノート内での表示順。CloudKit 同期はレコードの取得順を保証しないため明示的に持つ。
    private(set) var sortOrder: Int = 0

    /// このテンプレートが属するノート。inverse は JournalNotebook.templates 側で宣言する。
    private(set) var notebook: JournalNotebook?

    // notebook は JournalNotebook.add(template:) から紐付けるため、引数から受け取らない。
    init(name: String, markdown: String, sortOrder: Int) {
        self.name = name
        self.markdown = markdown
        self.sortOrder = sortOrder
    }

    /// 名前を変更する。
    func setName(name: String) {
        self.name = name
    }

    /// markdown 本文を変更する。
    func setMarkdown(markdown: String) {
        self.markdown = markdown
    }

    /// markdown 中の {{variable}} を出現順・重複なしで抽出する。
    var variableNames: [String] {
        var result: [String] = []
        var seen: Set<String> = []
        let scanner = markdown as NSString
        let pattern = try? NSRegularExpression(pattern: "\\{\\{\\s*([a-zA-Z0-9_]+)\\s*\\}\\}")
        pattern?.enumerateMatches(in: markdown, range: NSRange(location: 0, length: scanner.length)) { match, _, _ in
            guard let match, match.numberOfRanges > 1 else {
                return
            }
            let name = scanner.substring(with: match.range(at: 1))
            if !seen.contains(name) {
                seen.insert(name)
                result.append(name)
            }
        }
        return result
    }
}
