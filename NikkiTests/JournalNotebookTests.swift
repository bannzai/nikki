import Foundation
import SwiftData
import Testing
@testable import Nikki

struct JournalNotebookTests {
    @Test("add はテンプレートを紐付け、同じテンプレートを二度足しても増えない")
    func addTemplateIsIdempotent() {
        let notebook = JournalNotebook(name: "寝る前", reminderFrequency: .daily, sortOrder: 0)
        let template = JournalTemplate(name: "一日の振り返り", markdown: "# {{date}}", sortOrder: 0)

        notebook.add(template: template)
        notebook.add(template: template)

        #expect(notebook.templates?.count == 1)
        #expect(notebook.template === template)
    }

    @Test("template は表示順が先頭のテンプレートを返す")
    func templateUsesLowestSortOrder() {
        let notebook = JournalNotebook(name: "仕事", reminderFrequency: .none, sortOrder: 0)
        notebook.add(template: JournalTemplate(name: "あとの紙", markdown: "# あと", sortOrder: 1))
        notebook.add(template: JournalTemplate(name: "さきの紙", markdown: "# さき", sortOrder: 0))

        #expect(notebook.template?.name == "さきの紙")
    }

    @Test("テンプレートを持たないノートの template は nil になる")
    func templateIsNilWithoutTemplates() {
        #expect(JournalNotebook(name: "育児", reminderFrequency: .weekly, sortOrder: 0).template == nil)
    }

    @Test("reminderFrequency は保存した頻度をそのまま読む")
    func reminderFrequencyRoundTrips() {
        for frequency in JournalReminderFrequency.allCases {
            #expect(JournalNotebook(name: "ノート", reminderFrequency: frequency, sortOrder: 0).reminderFrequency == frequency)
        }
    }

    @Test("初回シードはノートを意識させないよう、{{date}} テンプレートを持つ白紙1冊だけ")
    func seedNotebooksHideNotebookConcept() {
        let notebooks = SampleData.seedNotebooks
        #expect(notebooks.count == 1)
        #expect(notebooks[0].name == String(localized: "Blank page"))
        #expect(notebooks[0].template?.markdown == "# {{date}}")
        #expect(notebooks[0].reminderFrequency == .none)
    }

    @Test("プレビュー用ノートはノートごとにテンプレートを1件持つ")
    func previewNotebooksHaveTemplate() {
        #expect(SampleData.notebooks.allSatisfy { $0.templates?.count == 1 })
    }

    @Test("setName はノートの名前と、名前を揃える運用のテンプレートの名前を一緒に変える")
    func setNameRenamesNotebookAndTemplates() {
        let notebook = JournalNotebook(name: "白紙", reminderFrequency: .none, sortOrder: 0)
        notebook.add(template: JournalTemplate(name: "白紙", markdown: "# {{date}}", sortOrder: 0))

        notebook.setName(name: "夜のノート")

        #expect(notebook.name == "夜のノート")
        #expect(notebook.template?.name == "夜のノート")
    }

    @Test("setMarkdown はテンプレートの書き出しを置き換える")
    func setMarkdownReplacesTemplateMarkdown() {
        let template = JournalTemplate(name: "白紙", markdown: "# {{date}}", sortOrder: 0)

        template.setMarkdown(markdown: "# {{date}} の夜")

        #expect(template.markdown == "# {{date}} の夜")
    }

    @Test("ノートを削除するとテンプレートも消え、日記は残る")
    @MainActor
    func deletingNotebookCascadesTemplatesAndKeepsEntries() throws {
        // mainContext だけ取り出すとコンテナが解放されて SwiftData がクラッシュするため、コンテナ自体を保持する。
        let container = SampleData.inMemoryContainer()
        let context = container.mainContext
        let notebook = try #require(try context.fetch(FetchDescriptor<JournalNotebook>()).first)
        let entry = try #require(try context.fetch(FetchDescriptor<JournalEntry>()).first)
        entry.setNotebook(notebook: notebook)
        try context.save()

        let templateCount = try context.fetchCount(FetchDescriptor<JournalTemplate>())
        context.delete(notebook)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<JournalTemplate>()) == templateCount - 1)
        #expect(try context.fetchCount(FetchDescriptor<JournalEntry>()) > 0)
        #expect(entry.notebook == nil)
    }
}
