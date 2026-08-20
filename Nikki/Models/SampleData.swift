import Foundation
import SwiftData

/// デザインリファレンス(Nikki iOS.dc.html)と一致するサンプルデータ。
/// 日付依存の画面には referenceToday(2026-07-18)を「今日」として渡す。
/// 文言は String Catalog を通し、シード(永続化)・プレビューとも端末の言語で表示する(.claude/rules/coding-rules-entity.md)。
/// JournalEntry / JournalNotebook / JournalTemplate は SwiftData の @Model(参照型)のため、複数のコンテナや
/// プレビューで同じインスタンスを共有しないよう、アクセスごとに新しいインスタンスを作る。
enum SampleData {
    // プレビュー・サンプルデータの再現性のため、参照日(2026-07-18 JST)と同じ暦・タイムゾーンに固定する。
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return c
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 21, _ minute: Int = 0) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .now
    }

    static let referenceToday: Date = date(2026, 7, 18, 21, 4)

    static var entries: [JournalEntry] {
        [
            JournalEntry(
                date: date(2026, 7, 18, 21, 4),
                title: String(localized: "Summer begins"),
                bodyMarkdown: String(localized: """
                Cicadas were singing from early morning. Watering the pots on the balcony, I realized summer is here again.

                Brewed a strong iced coffee and drank it on the balcony

                ## Things I bought

                - [x] Barley tea bags
                - [ ] Mosquito coil

                <img alt="Photo of the sunset">

                <details><summary>Hospital notes (folded away)</summary></details>

                ## From the evening

                The wind turned cool, so I opened every window and drank barley tea.
                """),
                createdAt: date(2026, 7, 18, 21, 4),
                updatedAt: date(2026, 7, 18, 21, 4)
            ),
            JournalEntry(
                date: date(2026, 7, 16, 22, 10),
                title: String(localized: "A quiet day"),
                bodyMarkdown: String(localized: "Nothing special happened, and that was the good part. The evening breeze felt cool, so I opened every window."),
                createdAt: date(2026, 7, 16, 22, 10),
                updatedAt: date(2026, 7, 16, 22, 10)
            ),
            JournalEntry(
                date: date(2026, 7, 12, 20, 30),
                title: String(localized: "At the bookstore"),
                bodyMarkdown: String(localized: "They didn't have the book I wanted, yet I left with three. These little detours pay off later."),
                createdAt: date(2026, 7, 12, 20, 30),
                updatedAt: date(2026, 7, 12, 20, 30)
            ),
            JournalEntry(
                date: date(2026, 6, 29, 19, 45),
                title: String(localized: "Sound of rain"),
                bodyMarkdown: String(localized: "Rain all day. I forgot my umbrella and stood at the station, but fifteen minutes of shelter wasn't bad at all."),
                createdAt: date(2026, 6, 29, 19, 45),
                updatedAt: date(2026, 6, 29, 19, 45)
            ),
            JournalEntry(
                date: date(2026, 6, 24, 21, 15),
                title: String(localized: "Wardrobe change"),
                bodyMarkdown: String(localized: "Switched the closet to summer. Last year's shirts still smelled like last summer."),
                createdAt: date(2026, 6, 24, 21, 15),
                updatedAt: date(2026, 6, 24, 21, 15)
            ),
        ]
    }

    /// エディタ系画面が使うリッチな本文を持つ日記(梅雨明け)。
    static var sampleEntry: JournalEntry { entries[0] }

    /// アーカイブ一覧のプレビュー・カタログ用のアーカイブ済み日記。
    /// entries には混ぜず、ホーム系プレビュー(絞り込み前の配列を直接受け取る)に出ないようにする。
    static var archivedEntries: [JournalEntry] {
        [
            JournalEntry(
                date: date(2026, 5, 3, 18, 20),
                title: String(localized: "Middle of the long weekend"),
                bodyMarkdown: String(localized: "Went nowhere and sorted the photos that had piled up. A day I'll never reread, but want to keep."),
                createdAt: date(2026, 5, 3, 18, 20),
                updatedAt: date(2026, 5, 3, 18, 20),
                isArchived: true
            ),
        ]
    }

    /// プレビュー・カタログ用ノートの中身。書く時間が決まっているノートにだけリマインドを入れる。
    /// 並び順は配列の順そのもの、テンプレートの名前はノートの名前を使うため、ここには持たない。
    private static var notebookSeeds: [(name: String, reminderFrequency: JournalReminderFrequency, markdown: String)] {
        [
            (
                name: String(localized: "Blank page"),
                reminderFrequency: .none,
                markdown: "# {{date}}"
            ),
            (
                name: String(localized: "3 lines in the morning"),
                reminderFrequency: .daily,
                markdown: String(localized: """
                # Morning of {{date}}
                - Looking forward to
                - Skipping today
                - One line
                """)
            ),
            (
                name: String(localized: "Daily reflection"),
                reminderFrequency: .daily,
                markdown: String(localized: """
                # {{date}}
                Weather: {{weather}}
                ## What went well
                ## Note to tomorrow's me
                """)
            ),
            (
                name: String(localized: "Travel log"),
                reminderFrequency: .none,
                markdown: String(localized: """
                # {{place}} day 1
                ## Where I walked
                ## What I ate
                """)
            ),
        ]
    }

    /// プレビュー・カタログ用の複数ノート。ノートごとに書き出し用のテンプレートを1件持ち、
    /// ノート一覧のカードやリマインドのバッジなど、ノートが複数あるときの表示確認に使う。
    static var notebooks: [JournalNotebook] {
        notebookSeeds.enumerated().map { index, seed in
            let notebook = JournalNotebook(name: seed.name, reminderFrequency: seed.reminderFrequency, sortOrder: index)
            notebook.add(template: JournalTemplate(name: seed.name, markdown: seed.markdown, sortOrder: 0))
            return notebook
        }
    }

    /// 初回起動時にシードする既定ノート。ノートを意識させない方針のため、
    /// {{date}} だけのテンプレートを持つ白紙の1冊だけを用意し、新規日記は自動でこのノートに入る。
    static var seedNotebooks: [JournalNotebook] {
        let seed = notebookSeeds[0]
        let notebook = JournalNotebook(name: seed.name, reminderFrequency: seed.reminderFrequency, sortOrder: 0)
        notebook.add(template: JournalTemplate(name: seed.name, markdown: seed.markdown, sortOrder: 0))
        return [notebook]
    }

    /// 変数入力シート(1m)が既定で開くテンプレート(「一日の振り返り」ノートのもの)。
    /// 見本(1m)は {{date}} と {{weather}} の2変数が並ぶ構成のため、変数を2つ持つこのテンプレートを使う。
    static var reflectionTemplate: JournalTemplate {
        JournalTemplate(name: notebookSeeds[2].name, markdown: notebookSeeds[2].markdown, sortOrder: 0)
    }

    /// プレビューとカタログモードが使う、サンプルデータ投入済みの in-memory コンテナを作る。
    static func inMemoryContainer() -> ModelContainer {
        do {
            // cloudKitDatabase の既定 (.automatic) は entitlements のコンテナへ同期を試みるため、
            // プレビュー・カタログ・テストから CloudKit に触れないよう .none を明示する。
            let container = try ModelContainer(
                for: JournalEntry.self, JournalNotebook.self, JournalTemplate.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
            for entry in entries {
                container.mainContext.insert(entry)
            }
            for entry in archivedEntries {
                container.mainContext.insert(entry)
            }
            container.mainContext.insert(notebooks: notebooks)
            return container
        } catch {
            fatalError("in-memory ModelContainer の生成に失敗: \(error)")
        }
    }
}
