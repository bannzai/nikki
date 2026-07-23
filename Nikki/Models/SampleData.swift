import Foundation
import SwiftData

/// デザインリファレンス(Nikki iOS.dc.html)と一致するサンプルデータ。
/// 日付依存の画面には referenceToday(2026-07-18)を「今日」として渡す。
/// JournalEntry / JournalTemplate は SwiftData の @Model(参照型)のため、複数のコンテナや
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

    /// 初回起動時のシードにも使う既定テンプレート4種。
    static var templates: [JournalTemplate] {
        [
            JournalTemplate(
                name: "白紙",
                markdown: "# {{date}}",
                sortOrder: 0
            ),
            JournalTemplate(
                name: "朝の3行",
                markdown: """
                # {{date}} の朝
                - 今日たのしみなこと
                - 今日やめておくこと
                - ひとこと
                """,
                sortOrder: 1
            ),
            JournalTemplate(
                name: "一日の振り返り",
                markdown: """
                # {{date}}
                天気: {{weather}}
                ## よかったこと
                ## 明日のじぶんへ
                """,
                sortOrder: 2
            ),
            JournalTemplate(
                name: "旅の記録",
                markdown: """
                # {{place}} 1日目
                ## 歩いたところ
                ## たべたもの
                """,
                sortOrder: 3
            ),
        ]
    }

    /// 変数入力シート(1m)が既定で開くテンプレート。
    static var reflectionTemplate: JournalTemplate { templates[2] }

    /// プレビューとカタログモードが使う、サンプルデータ投入済みの in-memory コンテナを作る。
    static func inMemoryContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: JournalEntry.self, JournalTemplate.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            for entry in entries {
                container.mainContext.insert(entry)
            }
            for template in templates {
                container.mainContext.insert(template)
            }
            return container
        } catch {
            fatalError("in-memory ModelContainer の生成に失敗: \(error)")
        }
    }
}
