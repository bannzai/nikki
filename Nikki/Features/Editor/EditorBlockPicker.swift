import Foundation

/// エディタ各状態が本文ブロックから必要な要素を取り出すヘルパー。
enum EditorBlockPicker {
    static func paragraphTexts(_ entry: JournalEntry) -> [String] {
        entry.blocks.compactMap { if case .paragraph(_, let text) = $0 { return text } else { return nil } }
    }

    static func headingTexts(_ entry: JournalEntry) -> [String] {
        entry.blocks.compactMap { if case .heading(_, _, let text) = $0 { return text } else { return nil } }
    }

    static func firstChecklist(_ entry: JournalEntry) -> [ChecklistItem] {
        entry.blocks.compactMap { if case .checklist(_, let items) = $0 { return items } else { return nil } }.first ?? []
    }

    static func firstImageLabel(_ entry: JournalEntry) -> String? {
        entry.blocks.compactMap { if case .image(_, let label) = $0 { return label } else { return nil } }.first
    }

    static func firstDetailsSummary(_ entry: JournalEntry) -> String? {
        entry.blocks.compactMap { if case .details(_, let summary, _) = $0 { return summary } else { return nil } }.first
    }
}
