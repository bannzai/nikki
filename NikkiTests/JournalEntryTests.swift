import Foundation
import SwiftData
import Testing
@testable import Nikki

struct JournalEntryTests {
    @Test("テンプレート markdown は先頭見出しも分解せず全文を本文にする")
    func templateMarkdownKeepsWholeBody() {
        let entry = JournalEntry(
            templateMarkdown: "# 2026年7月18日\n天気: 晴れ\n## よかったこと",
            date: .now
        )
        #expect(entry.title == "")
        #expect(entry.bodyMarkdown == "# 2026年7月18日\n天気: 晴れ\n## よかったこと")
    }

    @Test("replace がテンプレート markdown を全文本文にし、タイトルを空へ揃えて updatedAt を進める")
    func replaceOverwritesBodyAndClearsTitle() {
        let entry = JournalEntry(
            date: .now,
            title: "もとのタイトル",
            bodyMarkdown: "もとの本文",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.replace(templateMarkdown: "# 2026年7月18日\n\n天気: 晴れ")
        #expect(entry.title == "")
        #expect(entry.bodyMarkdown == "# 2026年7月18日\n\n天気: 晴れ")
        #expect(entry.updatedAt > .distantPast)
    }

    @Test("setBodyMarkdown が updatedAt を進める")
    func settersBumpUpdatedAt() {
        let entry = JournalEntry(
            date: .now,
            title: "",
            bodyMarkdown: "はじめの本文",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.setBodyMarkdown("あたらしい本文")
        #expect(entry.bodyMarkdown == "あたらしい本文")
        #expect(entry.updatedAt > .distantPast)
    }

    @Test("mergeTitleIntoBodyMarkdown がタイトルを本文先頭の見出しへ移して updatedAt を進める")
    func mergeTitleMovesTitleIntoBody() {
        let entry = JournalEntry(
            date: .now,
            title: "梅雨明け",
            bodyMarkdown: "朝から蝉が鳴いていた。",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.mergeTitleIntoBodyMarkdown()
        #expect(entry.title == "")
        #expect(entry.bodyMarkdown == "# 梅雨明け\n\n朝から蝉が鳴いていた。")
        #expect(entry.updatedAt > .distantPast)
    }

    @Test("mergeTitleIntoBodyMarkdown は本文が空ならタイトルの見出しだけを本文にする")
    func mergeTitleIntoEmptyBody() {
        let entry = JournalEntry(
            date: .now,
            title: "梅雨明け",
            bodyMarkdown: "",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.mergeTitleIntoBodyMarkdown()
        #expect(entry.title == "")
        #expect(entry.bodyMarkdown == "# 梅雨明け")
    }

    @Test("mergeTitleIntoBodyMarkdown はタイトルが空なら何もしない(冪等)")
    func mergeTitleDoesNothingWithoutTitle() {
        let entry = JournalEntry(
            date: .now,
            title: "",
            bodyMarkdown: "# 梅雨明け\n\n本文",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        entry.mergeTitleIntoBodyMarkdown()
        #expect(entry.bodyMarkdown == "# 梅雨明け\n\n本文")
        #expect(entry.updatedAt == .distantPast)
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

    @Test("setNotebook が所属ノートを設定して updatedAt を進める")
    func setNotebookAssignsNotebookAndBumpsUpdatedAt() {
        let entry = JournalEntry(
            date: .now,
            title: "梅雨明け",
            bodyMarkdown: "本文",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
        #expect(entry.notebook == nil)

        let notebook = JournalNotebook(name: "寝る前", reminderFrequency: .daily, sortOrder: 0)
        entry.setNotebook(notebook: notebook)
        #expect(entry.notebook === notebook)
        #expect(entry.updatedAt > .distantPast)
    }

    @Test("deleteAllJournalEntries はアーカイブ済みも含めて日記を全件削除し、ノートとテンプレートは残す")
    @MainActor
    func deleteAllJournalEntriesRemovesAllEntries() throws {
        // SampleData の in-memory コンテナは通常の日記・アーカイブ済みの日記・ノート(テンプレート付き)をシード済み。
        // mainContext だけ取り出すとコンテナが解放されて SwiftData がクラッシュするため、コンテナ自体を保持する。
        let container = SampleData.inMemoryContainer()
        let context = container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<JournalEntry>()) > 0)

        try context.deleteAllJournalEntries()

        #expect(try context.fetchCount(FetchDescriptor<JournalEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<JournalNotebook>()) > 0)
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
