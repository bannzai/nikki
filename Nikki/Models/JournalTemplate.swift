import Foundation

struct JournalTemplate: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// {{date}} {{weather}} 等の変数を含むマークダウン本文。
    var markdown: String

    /// markdown 中の {{variable}} を出現順・重複なしで抽出する。
    var variableNames: [String] {
        var result: [String] = []
        var seen: Set<String> = []
        let scanner = markdown as NSString
        let pattern = try? NSRegularExpression(pattern: "\\{\\{\\s*([a-zA-Z0-9_]+)\\s*\\}\\}")
        pattern?.enumerateMatches(in: markdown, range: NSRange(location: 0, length: scanner.length)) { match, _, _ in
            guard let match, match.numberOfRanges > 1 else { return }
            let name = scanner.substring(with: match.range(at: 1))
            if !seen.contains(name) {
                seen.insert(name)
                result.append(name)
            }
        }
        return result
    }
}
