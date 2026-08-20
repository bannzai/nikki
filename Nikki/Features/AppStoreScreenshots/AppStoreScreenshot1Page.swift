import SwiftUI

#if DEBUG
/// スクショ1枚目: ホーム(時系列リスト)。プライバシー(あなたしか読めない)を主訴求にする。
struct AppStoreScreenshot1Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (title, subtitle) = switch language {
        case .ja: (
            "ここに書くことは\nあなたしか読めません",
            "日記は端末とあなたの iCloud にだけ"
        )
        case .en: (
            "What you write here\nonly you can read",
            "Entries live only on your device and your iCloud"
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotHomeListScreen(language: language, canvas: canvas)
        }
    }
}

/// ホーム(リスト)のモック画面。ヘッダ・検索バー・セグメント・月見出し + 日記行で構成する。
struct AppStoreScreenshotHomeListScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (searchPlaceholder, segments, julyLabel, juneLabel, mayLabel) = switch language {
        case .ja: ("日記をさがす", ["リスト", "カレンダー"], "2026年7月", "2026年6月", "2026年5月")
        case .en: ("Search your journal", ["List", "Calendar"], "July 2026", "June 2026", "May 2026")
        }
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                AppStoreScreenshotHomeHeader()
                AppStoreScreenshotSearchBar(placeholder: searchPlaceholder)
                InkSegmentedControl(options: segments, selectedIndex: .constant(0))
            }
            .padding(.horizontal, 24)
            .padding(.top, appStoreScreenshotScreenTopPadding(canvas: canvas))

            VStack(alignment: .leading, spacing: 0) {
                AppStoreScreenshotMonthLabel(text: julyLabel)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                ForEach(Array(AppStoreScreenshotDiary.julyRows(language: language).enumerated()), id: \.offset) { _, row in
                    AppStoreScreenshotEntryRow(day: row.day, weekday: row.weekday, title: row.title, excerpt: row.excerpt, showsSeparator: true)
                }
                AppStoreScreenshotMonthLabel(text: juneLabel)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                ForEach(Array(AppStoreScreenshotDiary.juneRows(language: language).enumerated()), id: \.offset) { _, row in
                    AppStoreScreenshotEntryRow(day: row.day, weekday: row.weekday, title: row.title, excerpt: row.excerpt, showsSeparator: true)
                }
                // iPhone のキャンバスではここから下は見切れる。画面が縦に長い iPad / Mac の埋め草として置く。
                AppStoreScreenshotMonthLabel(text: mayLabel)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                ForEach(Array(AppStoreScreenshotDiary.mayRows(language: language).enumerated()), id: \.offset) { _, row in
                    AppStoreScreenshotEntryRow(day: row.day, weekday: row.weekday, title: row.title, excerpt: row.excerpt, showsSeparator: true)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
        }
    }
}

/// スクショのモック画面が表示する日記のサンプル文言。SampleData の日記(日本語)と、その英訳版を言語別に返す。
enum AppStoreScreenshotDiary {
    /// 時系列リスト1行ぶんの表示文言。
    struct Row {
        let day: Int
        let weekday: String
        let title: String
        let excerpt: String
    }

    /// 2026年7月の行(参照日 7/18 が土曜)。
    static func julyRows(language: AppStoreScreenshotLanguage) -> [Row] {
        switch language {
        case .ja:
            return [
                Row(day: 18, weekday: "土曜", title: "梅雨明け", excerpt: "朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。 アイスコーヒーを濃いめに淹れて、ベランダで飲んだ"),
                Row(day: 16, weekday: "木曜", title: "何もない日", excerpt: "特別なことは何もなかったけれど、それがよかった。夕方の風がすこし涼しくて、窓を全部開けた。"),
                Row(day: 12, weekday: "日曜", title: "本屋にて", excerpt: "目当ての本はなかったのに、気づいたら3冊買っていた。こういう寄り道のほうが、あとで効いてくる気がする。"),
            ]
        case .en:
            return [
                Row(day: 18, weekday: "Sat", title: "Summer begins", excerpt: "Cicadas were singing from early morning. Watering the pots on the balcony, I realized summer is here again."),
                Row(day: 16, weekday: "Thu", title: "A quiet day", excerpt: "Nothing special happened, and that was the good part. The evening breeze felt cool, so I opened every window."),
                Row(day: 12, weekday: "Sun", title: "At the bookstore", excerpt: "They didn't have the book I wanted, yet I left with three. These little detours pay off later."),
            ]
        }
    }

    /// 2026年6月の行。
    static func juneRows(language: AppStoreScreenshotLanguage) -> [Row] {
        switch language {
        case .ja:
            return [
                Row(day: 29, weekday: "月曜", title: "雨の音", excerpt: "一日じゅう雨。傘を忘れて駅で立ち尽くしたけれど、雨宿りの15分は悪くなかった。"),
                Row(day: 24, weekday: "水曜", title: "衣替え", excerpt: "クローゼットを夏仕様に。去年の夏のシャツから、去年の夏のにおいがした。"),
                Row(day: 21, weekday: "日曜", title: "早起きの得", excerpt: "めずらしく6時に起きた。朝のうちに洗濯を干して、そのぶん夕方が長く感じた。"),
            ]
        case .en:
            return [
                Row(day: 29, weekday: "Mon", title: "Sound of rain", excerpt: "Rain all day. I forgot my umbrella and stood at the station, but fifteen minutes of shelter wasn't bad at all."),
                Row(day: 24, weekday: "Wed", title: "Wardrobe change", excerpt: "Switched the closet to summer. Last year's shirts still smelled like last summer."),
                Row(day: 21, weekday: "Sun", title: "Up early", excerpt: "Woke up at six for once. Hung the laundry in the morning, and the evening felt longer for it."),
            ]
        }
    }

    /// 2026年5月の行。iPhone のキャンバスでは見切れて表示されず、縦に長い iPad / Mac の埋め草になる。
    static func mayRows(language: AppStoreScreenshotLanguage) -> [Row] {
        switch language {
        case .ja:
            return [
                Row(day: 31, weekday: "日曜", title: "五月の終わり", excerpt: "気づけば今年も5ヶ月が終わった。ページをめくるように、6月へ。"),
                Row(day: 23, weekday: "土曜", title: "あたらしい靴", excerpt: "おろしたての靴で遠回りして帰る。靴擦れも、まあ記念のうち。"),
            ]
        case .en:
            return [
                Row(day: 31, weekday: "Sun", title: "End of May", excerpt: "Five months of the year gone already. Turning the page to June."),
                Row(day: 23, weekday: "Sat", title: "New shoes", excerpt: "Took the long way home in brand-new shoes. The blisters count as a souvenir."),
            ]
        }
    }
}

struct AppStoreScreenshot1Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot1Page(language: .ja, canvas: .iphone)
    }
}
#endif
