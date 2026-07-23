import Foundation

// MARK: - markdown → [Block]

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
        return .image(label: attributeValue("alt", in: line) ?? attributeValue("src", in: line) ?? "")
    }

    /// <details> タグの行。<summary> の中身を要約に、open 属性の有無を開閉状態に読む。
    private static func details(fromLine line: String) -> Block? {
        if !line.hasPrefix("<details") {
            return nil
        }
        return .details(
            summary: firstMatch(pattern: "<summary>(.*?)</summary>", in: line) ?? "",
            isCollapsed: !line.hasPrefix("<details open")
        )
    }

    /// name="値" 形式の HTML 属性値を取り出す。
    private static func attributeValue(_ name: String, in line: String) -> String? {
        firstMatch(pattern: "\(name)=\"([^\"]*)\"", in: line)
    }

    /// pattern の最初のキャプチャグループにマッチした文字列を返す。
    private static func firstMatch(pattern: String, in line: String) -> String? {
        let source = line as NSString
        let regex = try? NSRegularExpression(pattern: pattern)
        let match = regex?.firstMatch(in: line, range: NSRange(location: 0, length: source.length))
        guard let match, match.numberOfRanges > 1 else {
            return nil
        }
        return source.substring(with: match.range(at: 1))
    }

    // MARK: - [Block] → markdown

    /// ブロック列を markdown 文字列にする。ブロック間は空行で区切り、blocks(fromMarkdown:) と往復できる形にする。
    static func markdown(from blocks: [Block]) -> String {
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
}
