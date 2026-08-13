import Foundation
import SwiftData
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

    @Test("新規作成の日記はアーカイブされていない状態で始まる")
    func newEntryStartsUnarchived() {
        let entry = JournalEntry(templateMarkdown: "# タイトル\n本文", date: .now)
        #expect(!entry.isArchived)
    }

    @Test("setArchived が isArchived を切り替えて updatedAt を進める")
    func setArchivedTogglesAndBumpsUpdatedAt() {
        let entry = JournalEntry(
            date: .now,
            title: "梅雨明け",
            bodyMarkdown: "本文",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.setArchived(true)
        #expect(entry.isArchived)
        #expect(entry.updatedAt > .distantPast)

        entry.setArchived(false)
        #expect(!entry.isArchived)
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

    @Test("matches はタイトルと本文を大文字小文字を区別せず照合する")
    func matchesSearchesTitleAndBody() {
        let entry = JournalEntry(
            date: .now,
            title: "梅雨明け",
            bodyMarkdown: "朝から蝉が鳴いていた。Iced Coffee を淹れた。",
            createdAt: .now,
            updatedAt: .now
        )
        #expect(entry.matches(searchText: "梅雨"))
        #expect(entry.matches(searchText: "蝉"))
        #expect(entry.matches(searchText: "iced coffee"))
        #expect(!entry.matches(searchText: "雪"))
    }

    @Test("deleteAllJournalEntries はアーカイブ済みも含めて日記を全件削除し、テンプレートは残す")
    @MainActor
    func deleteAllJournalEntriesRemovesAllEntries() throws {
        // SampleData の in-memory コンテナは通常の日記・アーカイブ済みの日記・テンプレートをシード済み。
        // mainContext だけ取り出すとコンテナが解放されて SwiftData がクラッシュするため、コンテナ自体を保持する。
        let container = SampleData.inMemoryContainer()
        let context = container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<JournalEntry>()) > 0)

        try context.deleteAllJournalEntries()

        #expect(try context.fetchCount(FetchDescriptor<JournalEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<JournalTemplate>()) > 0)
    }

    @Test("exportMarkdown は日付見出し + 本文を水平線で区切って連結する")
    func exportMarkdownJoinsEntries() {
        let entries = [
            JournalEntry(
                date: SampleData.date(2026, 7, 16),
                title: "何もない日",
                bodyMarkdown: "特別なことは何もなかった。",
                createdAt: .now,
                updatedAt: .now
            ),
            JournalEntry(
                date: SampleData.date(2026, 7, 18),
                title: "",
                bodyMarkdown: "タイトルのない日。",
                createdAt: .now,
                updatedAt: .now
            ),
        ]
        #expect(entries.exportMarkdown == """
        # 2026-07-16 何もない日

        特別なことは何もなかった。

        ---

        # 2026-07-18

        タイトルのない日。
        """)
    }
}
