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

    @Test("既定ノートはノートごとにテンプレートを1件持ち、設定から全件を選べる件数に収まる")
    func seedNotebooksHaveTemplateAndFitInSettingsDialog() {
        let notebooks = SampleData.notebooks
        #expect(notebooks.allSatisfy { $0.templates?.count == 1 })
        // 設定「既定のノート」の confirmationDialog は macOS(NSAlert)でボタン4個までしか出せない。
        #expect(notebooks.count <= 4)
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
