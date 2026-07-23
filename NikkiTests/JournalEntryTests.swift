import Foundation
import Testing
@testable import Nikki

struct JournalEntryTests {
    @Test("テンプレート markdown の先頭 H1 をタイトルに取り出す")
    func templateMarkdownSplitsTitle() {
        let entry = JournalEntry(
            templateMarkdown: "# 2026年7月18日\n天気: 晴れ\n## よかったこと",
            date: .now
        )
        #expect(entry.title == "2026年7月18日")
        #expect(entry.bodyMarkdown == "天気: 晴れ\n## よかったこと")
    }

    @Test("H1 直後の空行は本文に含めない")
    func templateMarkdownDropsBlankLinesAfterTitle() {
        let entry = JournalEntry(
            templateMarkdown: "# タイトル\n\n\n本文",
            date: .now
        )
        #expect(entry.title == "タイトル")
        #expect(entry.bodyMarkdown == "本文")
    }

    @Test("先頭が H1 でなければ全文を本文にする")
    func templateMarkdownWithoutHeading() {
        let entry = JournalEntry(templateMarkdown: "ただの本文", date: .now)
        #expect(entry.title == "")
        #expect(entry.bodyMarkdown == "ただの本文")
    }

    @Test("setTitle / setBodyMarkdown が updatedAt を進める")
    func settersBumpUpdatedAt() {
        let entry = JournalEntry(
            date: .now,
            title: "はじめのタイトル",
            bodyMarkdown: "はじめの本文",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.setTitle("あたらしいタイトル")
        #expect(entry.title == "あたらしいタイトル")
        #expect(entry.updatedAt > .distantPast)

        entry.setBodyMarkdown("あたらしい本文")
        #expect(entry.bodyMarkdown == "あたらしい本文")
        #expect(entry.updatedAt > .distantPast)
    }

    @Test("excerpt は段落と見出しのテキストを連結する")
    func excerptJoinsParagraphsAndHeadings() {
        let entry = JournalEntry(
            date: .now,
            title: "梅雨明け",
            bodyMarkdown: "朝から蝉が鳴いていた。\n\n## 買ったもの\n\n- [ ] 麦茶のパック",
            createdAt: .now,
            updatedAt: .now
        )
        #expect(entry.excerpt == "朝から蝉が鳴いていた。 買ったもの")
    }
}
