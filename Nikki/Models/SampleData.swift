import Foundation
import SwiftData

/// デザインリファレンス(Nikki iOS.dc.html)と一致するサンプルデータ。
/// 日付依存の画面には referenceToday(2026-07-18)を「今日」として渡す。
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
                title: "梅雨明け",
                bodyMarkdown: """
                朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。

                アイスコーヒーを濃いめに淹れて、ベランダで飲んだ

                ## 買ったもの

                - [x] 麦茶のパック
                - [ ] 蚊取り線香

                <img alt="夕焼けの写真">

                <details><summary>病院メモ(たたんでおく)</summary></details>

                ## 夕方から

                風が涼しくなってきたので、窓を全部開けて麦茶を飲んだ。
                """,
                createdAt: date(2026, 7, 18, 21, 4),
                updatedAt: date(2026, 7, 18, 21, 4)
            ),
            JournalEntry(
                date: date(2026, 7, 16, 22, 10),
                title: "何もない日",
                bodyMarkdown: "特別なことは何もなかったけれど、それがよかった。夕方の風がすこし涼しくて、窓を全部開けた。",
                createdAt: date(2026, 7, 16, 22, 10),
                updatedAt: date(2026, 7, 16, 22, 10)
            ),
            JournalEntry(
                date: date(2026, 7, 12, 20, 30),
                title: "本屋にて",
                bodyMarkdown: "目当ての本はなかったのに、気づいたら3冊買っていた。こういう寄り道のほうが、あとで効いてくる気がする。",
                createdAt: date(2026, 7, 12, 20, 30),
                updatedAt: date(2026, 7, 12, 20, 30)
            ),
            JournalEntry(
                date: date(2026, 6, 29, 19, 45),
                title: "雨の音",
                bodyMarkdown: "一日じゅう雨。傘を忘れて駅で立ち尽くしたけれど、雨宿りの15分は悪くなかった。",
                createdAt: date(2026, 6, 29, 19, 45),
                updatedAt: date(2026, 6, 29, 19, 45)
            ),
            JournalEntry(
                date: date(2026, 6, 24, 21, 15),
                title: "衣替え",
                bodyMarkdown: "クローゼットを夏仕様に。去年の夏のシャツから、去年の夏のにおいがした。",
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
                title: "連休の中日",
                bodyMarkdown: "どこへも行かず、たまっていた写真を整理した。読み返すことはないけれど、残しておきたい日。",
                createdAt: date(2026, 5, 3, 18, 20),
                updatedAt: date(2026, 5, 3, 18, 20),
                isArchived: true
            ),
        ]
    }

    /// プレビュー・カタログ用ノートの中身。書く時間が決まっているノートにだけリマインドを入れる。
    /// 並び順は配列の順そのもの、テンプレートの名前はノートの名前を使うため、ここには持たない。
    /// 件数は macOS の confirmationDialog(NSAlert)がボタン4個までしか出せず、
    /// 5件目以降が設定「既定のノート」から選べなくなるため、4件に留める。
    private static var notebookSeeds: [(name: String, reminderFrequency: JournalReminderFrequency, markdown: String)] {
        [
            (
                name: "白紙",
                reminderFrequency: .none,
                markdown: "# {{date}}"
            ),
            (
                name: "朝の3行",
                reminderFrequency: .daily,
                markdown: """
                # {{date}} の朝
                - 今日たのしみなこと
                - 今日やめておくこと
                - ひとこと
                """
            ),
            (
                name: "一日の振り返り",
                reminderFrequency: .daily,
                markdown: """
                # {{date}}
                天気: {{weather}}
                ## よかったこと
                ## 明日のじぶんへ
                """
            ),
            (
                name: "旅の記録",
                reminderFrequency: .none,
                markdown: """
                # {{place}} 1日目
                ## 歩いたところ
                ## たべたもの
                """
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
