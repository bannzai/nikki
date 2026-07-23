import Foundation

/// チェックリスト1項目。Block と同じく表示用の値型で、SwiftData には保存されない。
struct ChecklistItem: Identifiable, Hashable {
    var id: UUID = UUID()
    var text: String
    var done: Bool
}

/// 日記本文を構成するブロック。マークダウン互換の見出し / 段落 / チェックリストと、
/// サポートする HTML タグ(img / details)を表現する。
///
/// 表示用の値型であり、SwiftData には保存されない。associated value 付きの enum は
/// SwiftData の @Model として型情報ごと永続化できないため、本文は
/// JournalEntry.bodyMarkdown(markdown 文字列)として保存し、表示時にこの型へパースして使う。
/// この type-safe な構造がないと、各 View が生の markdown 文字列を都度解釈することになり不便なため必要。
enum Block: Identifiable, Hashable {
    case heading(id: UUID = UUID(), level: Int, text: String)
    case paragraph(id: UUID = UUID(), text: String)
    case checklist(id: UUID = UUID(), items: [ChecklistItem])
    case image(id: UUID = UUID(), label: String)
    case details(id: UUID = UUID(), summary: String, isCollapsed: Bool)

    var id: UUID {
        switch self {
        case .heading(let id, _, _): return id
        case .paragraph(let id, _): return id
        case .checklist(let id, _): return id
        case .image(let id, _): return id
        case .details(let id, _, _): return id
        }
    }
}

// MARK: - markdown ⇔ [Block]

// 状態を持たない純粋関数のため nonisolated にし、nonisolated な @Model のプロパティからも呼べるようにする。
nonisolated extension Block {
    /// markdown 文字列を行単位で [Block] にパースする。
    /// サポートするのは見出し(#〜###)・チェックリスト(- [ ] / - [x])・img・details・段落のみで、
    /// どれにも当てはまらない行はそのまま段落として扱う。空行はブロックの区切りとして読み飛ばす。
    static func blocks(fromMarkdown markdown: String) -> [Block] {
        var blocks: [Block] = []
        // 連続するチェックリスト行を 1 つの checklist ブロックにまとめるためのバッファ。
        var checklistItems: [ChecklistItem] = []

        func flushChecklist() {
            if !checklistItems.isEmpty {
                blocks.append(.checklist(items: checklistItems))
                checklistItems = []
            }
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushChecklist()
                continue
            }
            if let item = checklistItem(fromLine: line) {
                checklistItems.append(item)
                continue
            }
            flushChecklist()
            if let heading = heading(fromLine: line) {
                blocks.append(heading)
            } else if let image = image(fromLine: line) {
                blocks.append(image)
            } else if let details = details(fromLine: line) {
                blocks.append(details)
            } else {
                blocks.append(.paragraph(text: line))
            }
        }
        flushChecklist()
        return blocks
    }

    /// ブロック列を markdown 文字列にする。ブロック間は空行で区切り、blocks(fromMarkdown:) と往復できる形にする。
    static func markdown(blocks: [Block]) -> String {
        blocks.map { block -> String in
            switch block {
            case .heading(_, let level, let text):
                return String(repeating: "#", count: level) + " " + text
            case .paragraph(_, let text):
                return text
            case .checklist(_, let items):
                return items.map { "- [\($0.done ? "x" : " ")] \($0.text)" }.joined(separator: "\n")
            case .image(_, let label):
                return "<img alt=\"\(label)\">"
            case .details(_, let summary, let isCollapsed):
                return isCollapsed
                    ? "<details><summary>\(summary)</summary></details>"
                    : "<details open><summary>\(summary)</summary></details>"
            }
        }
        .joined(separator: "\n\n")
    }

    /// 「# 」〜「### 」で始まる見出し行。「#### 」以上はサポート外として nil を返し、段落に落とす。
    private static func heading(fromLine line: String) -> Block? {
        for level in 1...3 {
            let prefix = String(repeating: "#", count: level) + " "
            if line.hasPrefix(prefix) {
                return .heading(
                    level: level,
                    text: String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                )
            }
        }
        return nil
    }

    /// 「- [ ] 」「- [x] 」で始まるチェックリスト行。
    private static func checklistItem(fromLine line: String) -> ChecklistItem? {
        if line.hasPrefix("- [ ] ") {
            return ChecklistItem(text: String(line.dropFirst("- [ ] ".count)), done: false)
        }
        if line.lowercased().hasPrefix("- [x] ") {
            return ChecklistItem(text: String(line.dropFirst("- [x] ".count)), done: true)
        }
        return nil
    }

    /// <img> タグの行。表示ラベルは alt 属性、無ければ src 属性から取る。
    private static func image(fromLine line: String) -> Block? {
        if !line.hasPrefix("<img") {
            return nil
        }
        return .image(label: attributeValue(name: "alt", line: line) ?? attributeValue(name: "src", line: line) ?? "")
    }

    /// <details> タグの行。<summary> の中身を要約に、open 属性の有無を開閉状態に読む。
    private static func details(fromLine line: String) -> Block? {
        if !line.hasPrefix("<details") {
            return nil
        }
        return .details(
            summary: firstMatch(pattern: "<summary>(.*?)</summary>", line: line) ?? "",
            isCollapsed: !line.hasPrefix("<details open")
        )
    }

    /// name="値" 形式の HTML 属性値を取り出す。
    private static func attributeValue(name: String, line: String) -> String? {
        firstMatch(pattern: "\(name)=\"([^\"]*)\"", line: line)
    }

    /// pattern の最初のキャプチャグループにマッチした文字列を返す。
    private static func firstMatch(pattern: String, line: String) -> String? {
        let source = line as NSString
        let regex = try? NSRegularExpression(pattern: pattern)
        let match = regex?.firstMatch(in: line, range: NSRange(location: 0, length: source.length))
        guard let match, match.numberOfRanges > 1 else {
            return nil
        }
        return source.substring(with: match.range(at: 1))
    }
}

// MARK: - ブロックの取り出し

// エディタ各画面が本文ブロックから必要な要素を取り出すためのヘルパー。
nonisolated extension [Block] {
    /// 段落のテキストを出現順に取り出す。
    var paragraphTexts: [String] {
        compactMap { if case .paragraph(_, let text) = $0 { return text } else { return nil } }
    }

    /// 見出しのテキストを出現順に取り出す。
    var headingTexts: [String] {
        compactMap { if case .heading(_, _, let text) = $0 { return text } else { return nil } }
    }

    /// 最初のチェックリストの項目。チェックリストが無ければ空配列。
    var firstChecklistItems: [ChecklistItem] {
        compactMap { if case .checklist(_, let items) = $0 { return items } else { return nil } }.first ?? []
    }

    /// 最初の img ブロックのラベル。
    var firstImageLabel: String? {
        compactMap { if case .image(_, let label) = $0 { return label } else { return nil } }.first
    }

    /// 最初の details ブロックの要約。
    var firstDetailsSummary: String? {
        compactMap { if case .details(_, let summary, _) = $0 { return summary } else { return nil } }.first
    }
}
