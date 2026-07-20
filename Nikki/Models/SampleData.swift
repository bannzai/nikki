import Foundation

/// デザインリファレンス(Nikki iOS.dc.html)と一致するサンプルデータ。
/// 日付依存の画面には referenceToday(2026-07-18)を「今日」として渡す。
enum SampleData {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return c
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 21, _ minute: Int = 0) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }

    static let referenceToday: Date = date(2026, 7, 18, 21, 4)

    static let mnemonic: [String] = [
        "river", "lantern", "quiet", "marble",
        "orbit", "velvet", "cedar", "hollow",
        "amber", "drift", "plume", "stone",
    ]

    static let restoreSuggestions: [String] = ["amber", "amount", "amuse"]

    static let entries: [JournalEntry] = [
        JournalEntry(
            date: date(2026, 7, 18, 21, 4),
            title: "梅雨明け",
            blocks: [
                .paragraph(text: "朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。"),
                .paragraph(text: "アイスコーヒーを濃いめに淹れて、ベランダで飲んだ"),
                .heading(level: 2, text: "買ったもの"),
                .checklist(items: [
                    ChecklistItem(text: "麦茶のパック", done: true),
                    ChecklistItem(text: "蚊取り線香", done: false),
                ]),
                .image(label: "夕焼けの写真"),
                .details(summary: "病院メモ(たたんでおく)", isCollapsed: true),
                .heading(level: 2, text: "夕方から"),
                .paragraph(text: "風が涼しくなってきたので、窓を全部開けて麦茶を飲んだ。"),
            ],
            createdAt: date(2026, 7, 18, 21, 4),
            updatedAt: date(2026, 7, 18, 21, 4)
        ),
        JournalEntry(
            date: date(2026, 7, 16, 22, 10),
            title: "何もない日",
            blocks: [
                .paragraph(text: "特別なことは何もなかったけれど、それがよかった。夕方の風がすこし涼しくて、窓を全部開けた。"),
            ],
            createdAt: date(2026, 7, 16, 22, 10),
            updatedAt: date(2026, 7, 16, 22, 10)
        ),
        JournalEntry(
            date: date(2026, 7, 12, 20, 30),
            title: "本屋にて",
            blocks: [
                .paragraph(text: "目当ての本はなかったのに、気づいたら3冊買っていた。こういう寄り道のほうが、あとで効いてくる気がする。"),
            ],
            createdAt: date(2026, 7, 12, 20, 30),
            updatedAt: date(2026, 7, 12, 20, 30)
        ),
        JournalEntry(
            date: date(2026, 6, 29, 19, 45),
            title: "雨の音",
            blocks: [
                .paragraph(text: "一日じゅう雨。傘を忘れて駅で立ち尽くしたけれど、雨宿りの15分は悪くなかった。"),
            ],
            createdAt: date(2026, 6, 29, 19, 45),
            updatedAt: date(2026, 6, 29, 19, 45)
        ),
        JournalEntry(
            date: date(2026, 6, 24, 21, 15),
            title: "衣替え",
            blocks: [
                .paragraph(text: "クローゼットを夏仕様に。去年の夏のシャツから、去年の夏のにおいがした。"),
            ],
            createdAt: date(2026, 6, 24, 21, 15),
            updatedAt: date(2026, 6, 24, 21, 15)
        ),
    ]

    /// エディタ系画面が使うリッチな本文を持つ日記(梅雨明け)。
    static var sampleEntry: JournalEntry { entries[0] }

    static let templates: [JournalTemplate] = [
        JournalTemplate(
            name: "白紙",
            markdown: "# {{date}}"
        ),
        JournalTemplate(
            name: "朝の3行",
            markdown: """
            # {{date}} の朝
            - 今日たのしみなこと
            - 今日やめておくこと
            - ひとこと
            """
        ),
        JournalTemplate(
            name: "一日の振り返り",
            markdown: """
            # {{date}}
            天気: {{weather}}
            ## よかったこと
            ## 明日のじぶんへ
            """
        ),
        JournalTemplate(
            name: "旅の記録",
            markdown: """
            # {{place}} 1日目
            ## 歩いたところ
            ## たべたもの
            """
        ),
    ]

    /// 変数入力シート(1m)が既定で開くテンプレート。
    static var reflectionTemplate: JournalTemplate { templates[2] }
}
