import CoreGraphics
import Foundation
import Testing
@testable import Nikki

@MainActor
struct SettingsExportPDFGeneratorTests {
    @Test("PDF 書き出しは 1 日記 1 ページの PDF データになる(#95)")
    func makesOnePagePerEntry() throws {
        let entries = [
            JournalEntry(
                date: SampleData.date(2026, 7, 16),
                title: "何もない日",
                bodyMarkdown: "# 見出し\n\n特別なことは何もなかった。\n\n- [ ] 散歩\n- [x] 買い物",
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
        let data = SettingsExportPDFGenerator.makeData(entries: entries, paperColor: .inkPaper)
        let document = try #require(CGDataProvider(data: data as CFData).flatMap(CGPDFDocument.init))
        #expect(document.numberOfPages == 2)
    }
}
