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
    // img / details の rawMarkdown は本文にあった元の行そのもの。表示は label / summary で行い、
    // 書き戻しは rawMarkdown を使うことで、パースが解釈しない属性(src 等)や書き方を失わない。
    case image(id: UUID = UUID(), label: String, rawMarkdown: String)
    case details(id: UUID = UUID(), summary: String, isCollapsed: Bool, rawMarkdown: String)

    // 編集ヘルパー(下の「編集」セクション)が nonisolated な純粋関数からブロックを探せるようにする。
    nonisolated var id: UUID {
        switch self {
        case .heading(let id, _, _): return id
        case .paragraph(let id, _): return id
        case .checklist(let id, _): return id
        case .image(let id, _, _): return id
        case .details(let id, _, _, _): return id
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
            if rawLine.trimmingCharacters(in: .whitespaces).isEmpty {
                flushChecklist()
                continue
            }
            // 記法の判定は行頭 (インデントなし) に限る。インデントされた「- [ ] 」等をブロックに
            // 変換すると、書き戻しでインデントが失われて元のテキストを壊すため、段落として raw のまま持つ。
            if let item = checklistItem(fromLine: rawLine) {
                checklistItems.append(item)
                continue
            }
            flushChecklist()
            if let heading = heading(fromLine: rawLine) {
                blocks.append(heading)
            } else if let image = image(rawLine: rawLine) {
                blocks.append(image)
            } else if let details = details(rawLine: rawLine) {
                blocks.append(details)
            } else {
                // 書き戻しで行内の空白まで元のまま残るよう、トリムせず元の行を持つ。
                blocks.append(.paragraph(text: rawLine))
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
            case .image(_, _, let rawMarkdown):
                return rawMarkdown
            case .details(_, _, _, let rawMarkdown):
                return rawMarkdown
            }
        }
        .joined(separator: "\n\n")
    }

    /// サポートする見出しの記法。並び順が見出しレベル(先頭が「# 」)にあたる。
    static let headingPrefixes: [String] = (1...3).map { String(repeating: "#", count: $0) + " " }

    /// 未完了のチェックリスト項目の記法。
    static let uncheckedPrefix = "- [ ] "

    /// 完了したチェックリスト項目の記法。
    static let checkedPrefix = "- [x] "

    /// 「# 」〜「### 」で始まる見出し行。「#### 」以上はサポート外として nil を返し、段落に落とす。
    private static func heading(fromLine line: String) -> Block? {
        for (index, prefix) in headingPrefixes.enumerated() {
            if line.hasPrefix(prefix) {
                return .heading(
                    level: index + 1,
                    text: String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                )
            }
        }
        return nil
    }

    /// 「- [ ] 」「- [x] 」で始まるチェックリスト行。
    private static func checklistItem(fromLine line: String) -> ChecklistItem? {
        if line.hasPrefix(uncheckedPrefix) {
            return ChecklistItem(text: String(line.dropFirst(uncheckedPrefix.count)), done: false)
        }
        if line.lowercased().hasPrefix(checkedPrefix) {
            return ChecklistItem(text: String(line.dropFirst(checkedPrefix.count)), done: true)
        }
        return nil
    }

    /// <img> タグの行。表示ラベルは alt 属性、無ければ src 属性から取り、書き戻し用に元の行を保持する。
    private static func image(rawLine: String) -> Block? {
        if !rawLine.hasPrefix("<img") {
            return nil
        }
        return .image(
            label: attributeValue(name: "alt", line: rawLine) ?? attributeValue(name: "src", line: rawLine) ?? "",
            rawMarkdown: rawLine
        )
    }

    /// <details> タグの行。<summary> の中身を要約に、open 属性の有無を開閉状態に読み、書き戻し用に元の行を保持する。
    private static func details(rawLine: String) -> Block? {
        if !rawLine.hasPrefix("<details") {
            return nil
        }
        return .details(
            // summary の開始タグは属性付き (<summary class="…">) も許す。
            summary: firstMatch(pattern: "<summary\\b[^>]*>(.*?)</summary>", line: rawLine) ?? "",
            isCollapsed: !detailsIsOpen(line: rawLine),
            rawMarkdown: rawLine
        )
    }

    /// details の開始タグ内の open 属性。値なし (open) と値付き (open="…" / open='…' / open=xxx、
    /// = の前後の空白も許す) の両方にマッチし、前の空白ごと取り除ける形にしている。
    /// Regex は Sendable でなく static に持てないため、都度生成する。
    private static func detailsOpenAttribute() -> Regex<Substring> {
        #/\s+open(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]*))?(?=\s|$)/#
    }

    /// details 行の開始タグ (最初の > まで) に open 属性があるかどうか。属性の位置を問わず判定し、
    /// summary の文中に「open」とあっても反応しない。
    private static func detailsIsOpen(line: String) -> Bool {
        guard let tagEnd = line.firstIndex(of: ">") else {
            return false
        }
        return line[..<tagEnd].contains(detailsOpenAttribute())
    }

    /// details 行の開始タグの open 属性を付け外しした行。opens が true なら追加、false なら除去する。
    /// summary 以外の属性や書き方は元の行のまま保ち、open が先頭以外の位置にあっても重複させない。
    static func togglingDetailsOpenAttribute(rawMarkdown: String, opens: Bool) -> String {
        if opens {
            // 既に open が付いている行はそのまま返す(冪等)。
            if detailsIsOpen(line: rawMarkdown) {
                return rawMarkdown
            }
            return rawMarkdown.replacing("<details", with: "<details open", maxReplacements: 1)
        }
        guard let tagEnd = rawMarkdown.firstIndex(of: ">") else {
            return rawMarkdown
        }
        // 除去は開始タグの中だけを対象にし、summary の文中の「open」を巻き込まない。値付きの open 属性も丸ごと外す。
        return String(rawMarkdown[..<tagEnd]).replacing(detailsOpenAttribute(), with: "", maxReplacements: 1) + String(rawMarkdown[tagEnd...])
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
        compactMap { if case .image(_, let label, _) = $0 { return label } else { return nil } }.first
    }

    /// 最初の details ブロックの要約。
    var firstDetailsSummary: String? {
        compactMap { if case .details(_, let summary, _, _) = $0 { return summary } else { return nil } }.first
    }
}

// MARK: - 編集

// エディタがブロックを直接書き換えるためのヘルパー。View から切り離した純粋関数として置き、
// 書き換えた結果が markdown と往復することをユニットテストで確かめられるようにする。
nonisolated extension Block {
    /// 入力欄で編集できる本文。チェックリスト・img・details は項目や属性が中身にあたるため nil。
    var editableText: String? {
        switch self {
        case .heading(_, _, let text): return text
        case .paragraph(_, let text): return text
        case .checklist, .image, .details: return nil
        }
    }

    /// このブロックで最初に文字を入力できる欄の id。見出し・段落はブロック自身、チェックリストは先頭の項目。
    /// 文字を入力できる欄が無ければ nil。
    var firstEditableFieldID: UUID? {
        switch self {
        case .heading(let id, _, _): return id
        case .paragraph(let id, _): return id
        case .checklist(_, let items): return items.first?.id
        case .image, .details: return nil
        }
    }

    /// 本文を差し替えたブロック。id は保ち、入力欄の同一性(フォーカスと日本語入力の変換中テキスト)を壊さない。
    func replacing(editableText: String) -> Block {
        switch self {
        case .heading(let id, let level, _): return .heading(id: id, level: level, text: editableText)
        case .paragraph(let id, _): return .paragraph(id: id, text: editableText)
        case .checklist, .image, .details: return self
        }
    }

    /// 改行で分けたブロック列。Return が入力欄に改行として入るプラットフォームでは、改行をブロックの
    /// 区切りとして扱い、2つ目以降を段落にする。改行が無ければ nil を返し、分割しないことを示す。
    var splitByNewlines: [Block]? {
        if let editableText, editableText.contains("\n") {
            let texts = editableText.components(separatedBy: "\n")
            return [replacing(editableText: texts[0])] + texts.dropFirst().map { Block.paragraph(text: $0) }
        }
        return nil
    }

    /// 記法だけを打ち終えた段落が変わる先のブロック。変わらなければ nil。
    /// 「# 」「- [ ] 」まで入力した時点で見出し・チェックリストへ変え、記法を書いたまま編集を続けさせない。
    /// 記法に続く本文まで入力された状態では変換しない。日本語入力の変換中にブロックを差し替えると
    /// 組み立て中の文字が失われるため(issue #86)、変換が始まっていない記法だけの状態に限る。
    static func converted(paragraphText: String) -> Block? {
        if let level = headingPrefixes.firstIndex(of: paragraphText) {
            return .heading(level: level + 1, text: "")
        }
        if paragraphText == uncheckedPrefix {
            return .checklist(items: [ChecklistItem(text: "", done: false)])
        }
        if paragraphText.lowercased() == checkedPrefix {
            return .checklist(items: [ChecklistItem(text: "", done: true)])
        }
        return nil
    }
}

nonisolated extension [Block] {
    /// 先頭の入力欄の id。文字を入力できるブロックが無ければ nil。
    var firstEditableFieldID: UUID? {
        compactMap(\.firstEditableFieldID).first
    }

    /// 本文が空の見出し・段落と、本文が空のチェックリスト項目を落としたブロック列。
    /// 空の本文を markdown にすると記法の断片(「# 」「- [ ] 」)だけが残り、読み直したときに
    /// 別のブロックとして解釈されてしまうため、日記へ書き戻す前に取り除く。
    var withoutEmptyText: [Block] {
        compactMap { block -> Block? in
            switch block {
            case .heading(_, _, let text), .paragraph(_, let text):
                return text.trimmingCharacters(in: .whitespaces).isEmpty ? nil : block
            case .checklist(let id, let items):
                let remaining = items.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
                return remaining.isEmpty ? nil : Block.checklist(id: id, items: remaining)
            case .image, .details:
                return block
            }
        }
    }

    /// 見出し・段落の本文を書き換える。記法だけを打ち終えたブロックは見出し・チェックリストへ変え、
    /// 改行が入力されたブロックはそこで分ける。入力欄が変わったときだけ、続けて入力する欄の id を返す。
    mutating func updateEditableText(blockID: UUID, text: String) -> UUID? {
        if let index = firstIndex(where: { $0.id == blockID }) {
            if case .paragraph = self[index], let converted = Block.converted(paragraphText: text) {
                self[index] = converted
                return converted.firstEditableFieldID
            }
            let updated = self[index].replacing(editableText: text)
            if let split = updated.splitByNewlines {
                replaceSubrange(index...index, with: split)
                return split.last?.id
            }
            self[index] = updated
        }
        return nil
    }

    /// 見出し・段落の直後に空の段落を足す。Return が改行ではなく確定として届くプラットフォームで、
    /// 次のブロックを書きはじめられるようにする。続けて入力する欄の id を返す。
    mutating func insertParagraph(afterBlockID blockID: UUID) -> UUID? {
        if let index = firstIndex(where: { $0.id == blockID }) {
            let paragraph = Block.paragraph(text: "")
            insert(paragraph, at: index + 1)
            return paragraph.id
        }
        return nil
    }

    /// チェックリスト項目の本文を書き換える。改行が入力された項目はそこで分けて次の項目にし、
    /// 本文の無い項目で改行したときはリストから抜けて段落にする。
    /// 入力欄が変わったときだけ、続けて入力する欄の id を返す。
    mutating func updateChecklistItem(itemID: UUID, text: String) -> UUID? {
        if let indexes = checklistIndexes(itemID: itemID), case .checklist(let id, var items) = self[indexes.blockIndex] {
            if text.contains("\n") {
                let texts = text.components(separatedBy: "\n")
                if texts.allSatisfy(\.isEmpty) {
                    return exitChecklist(blockIndex: indexes.blockIndex, itemIndex: indexes.itemIndex)
                }
                items[indexes.itemIndex].text = texts[0]
                let addedItems = texts.dropFirst().map { ChecklistItem(text: $0, done: false) }
                items.insert(contentsOf: addedItems, at: indexes.itemIndex + 1)
                self[indexes.blockIndex] = .checklist(id: id, items: items)
                return addedItems.last?.id
            }
            items[indexes.itemIndex].text = text
            self[indexes.blockIndex] = .checklist(id: id, items: items)
        }
        return nil
    }

    /// チェックリスト項目の直後に空の項目を足す。本文の無い項目からはリストを抜けて段落にする。
    /// Return が改行ではなく確定として届くプラットフォーム用。続けて入力する欄の id を返す。
    mutating func insertChecklistItem(afterItemID itemID: UUID) -> UUID? {
        if let indexes = checklistIndexes(itemID: itemID), case .checklist(let id, var items) = self[indexes.blockIndex] {
            if items[indexes.itemIndex].text.isEmpty {
                return exitChecklist(blockIndex: indexes.blockIndex, itemIndex: indexes.itemIndex)
            }
            let addedItem = ChecklistItem(text: "", done: false)
            items.insert(addedItem, at: indexes.itemIndex + 1)
            self[indexes.blockIndex] = .checklist(id: id, items: items)
            return addedItem.id
        }
        return nil
    }

    /// チェックリスト項目の完了を設定する。
    mutating func setChecklistItemDone(itemID: UUID, done: Bool) {
        if let indexes = checklistIndexes(itemID: itemID), case .checklist(let id, var items) = self[indexes.blockIndex] {
            items[indexes.itemIndex].done = done
            self[indexes.blockIndex] = .checklist(id: id, items: items)
        }
    }

    /// details の開閉を反転する。書き戻し用の rawMarkdown 側も open 属性を付け外しして裏返す。
    mutating func toggleDetails(blockID: UUID) {
        if let index = firstIndex(where: { $0.id == blockID }), case .details(let id, let summary, let isCollapsed, let rawMarkdown) = self[index] {
            self[index] = .details(
                id: id,
                summary: summary,
                isCollapsed: !isCollapsed,
                rawMarkdown: Block.togglingDetailsOpenAttribute(rawMarkdown: rawMarkdown, opens: isCollapsed)
            )
        }
    }

    /// 項目を持つチェックリストの位置と、その中の項目の位置。
    private func checklistIndexes(itemID: UUID) -> (blockIndex: Int, itemIndex: Int)? {
        for (blockIndex, block) in enumerated() {
            if case .checklist(_, let items) = block, let itemIndex = items.firstIndex(where: { $0.id == itemID }) {
                return (blockIndex, itemIndex)
            }
        }
        return nil
    }

    /// チェックリストから項目を取り除き、その項目があった位置に空の段落を置く。
    /// 途中の項目から抜けたときは前後の項目を別々のチェックリストに分け、その間に段落を挟む
    /// (段落をリスト全体の後ろへ動かすと、入力位置と項目の順序が変わってしまうため)。
    /// 前後に項目が無い側のチェックリストは作らない。続けて入力する段落の id を返す。
    private mutating func exitChecklist(blockIndex: Int, itemIndex: Int) -> UUID? {
        if case .checklist(let id, let items) = self[blockIndex] {
            let paragraph = Block.paragraph(text: "")
            var replacement: [Block] = []
            // この extension 内で Array と書くと Array<Block> に束縛されるため、要素型を明示する。
            if itemIndex > 0 {
                replacement.append(.checklist(id: id, items: Array<ChecklistItem>(items[..<itemIndex])))
            }
            replacement.append(paragraph)
            if itemIndex + 1 < items.count {
                replacement.append(.checklist(items: Array<ChecklistItem>(items[(itemIndex + 1)...])))
            }
            replaceSubrange(blockIndex...blockIndex, with: replacement)
            return paragraph.id
        }
        return nil
    }
}
