import SwiftUI

#if DEBUG
/// スクショ4枚目: ノート一覧(テンプレート選択)。今日の紙を選んですぐ書き始められることを訴求する。
struct AppStoreScreenshot4Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        // 機能(テンプレート)をタイトルで先に伝える。情緒的な「今日の紙を選ぶ」はサブに置く。
        let (title, subtitle) = switch language {
        case .ja: (
            "テンプレートで\nすぐ書きはじめる",
            "「朝の3行」「一日の振り返り」から今日の紙を選ぶ"
        )
        case .en: (
            "Start right away\nwith templates",
            "Pick today's page like \"3 lines in the morning\""
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotNotebookScreen(language: language, canvas: canvas)
        }
    }
}

/// ノート一覧(テンプレート選択)のモック画面。実際の NotebookListPage と同じ構成
/// (ナビ + 見出し + ノートカードの並び)を、文言を言語別に渡せる静的表現で再現する
/// (NotebookListPage はナビタイトル・リマインド表示が日本語固定のため)。
struct AppStoreScreenshotNotebookScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (navTitle, heading, reminderDaily) = switch language {
        case .ja: ("ノート", "今日はどの紙に書きますか。", "毎日")
        case .en: ("Notebooks", "Which page will you write on today?", "Daily")
        }
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(navTitle))
            VStack(alignment: .leading, spacing: 0) {
                Text(heading)
                    .font(.ink(12.5, .regular))
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
                    .padding(.bottom, 16)

                VStack(spacing: 12) {
                    ForEach(Array(AppStoreScreenshotDiary.notebookCards(language: language).enumerated()), id: \.offset) { _, card in
                        AppStoreScreenshotNotebookCard(
                            name: card.name,
                            reminder: card.remindsDaily ? reminderDaily : "",
                            markdown: card.markdown
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, appStoreScreenshotScreenTopPadding(canvas: canvas))
    }
}

/// ノートカードのモック。NotebookCard と同じ見た目(名前 + リマインド + シェブロン + markdown プレビュー)で、
/// 文言を言語別に渡せる静的表現にする。
struct AppStoreScreenshotNotebookCard: View {
    let name: String
    /// リマインド頻度の表示文言。空のときは表示しない(リマインドなしのノート)。
    let reminder: String
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.inkListItemTitle)
                    .foregroundStyle(Color.ink)
                Spacer(minLength: 8)
                Text(reminder)
                    .font(.ink(11, .regular))
                    .foregroundStyle(Color.inkTextQuaternary)
                Image(systemName: InkIcons.chevronRight)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            Text(markdown)
                .font(.inkMono(11.5))
                .foregroundStyle(Color.inkTextTertiary)
                .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .inkCard(cornerRadius: 14)
    }
}

extension AppStoreScreenshotDiary {
    /// ノート一覧のモックが表示するノートカードの文言。SampleData.notebooks (日本語) と、その英訳版を言語別に返す。
    struct NotebookCardContent {
        let name: String
        let remindsDaily: Bool
        let markdown: String
    }

    static func notebookCards(language: AppStoreScreenshotLanguage) -> [NotebookCardContent] {
        switch language {
        case .ja:
            return [
                NotebookCardContent(name: "白紙", remindsDaily: false, markdown: "# {{date}}"),
                NotebookCardContent(name: "朝の3行", remindsDaily: true, markdown: "# {{date}} の朝\n- 今日たのしみなこと\n- 今日やめておくこと\n- ひとこと"),
                NotebookCardContent(name: "一日の振り返り", remindsDaily: true, markdown: "# {{date}}\n天気: {{weather}}\n## よかったこと\n## 明日のじぶんへ"),
                NotebookCardContent(name: "旅の記録", remindsDaily: false, markdown: "# {{place}} 1日目\n## 歩いたところ\n## たべたもの"),
            ]
        case .en:
            return [
                NotebookCardContent(name: "Blank page", remindsDaily: false, markdown: "# {{date}}"),
                NotebookCardContent(name: "3 lines in the morning", remindsDaily: true, markdown: "# Morning of {{date}}\n- Looking forward to\n- Skipping today\n- One line"),
                NotebookCardContent(name: "Daily reflection", remindsDaily: true, markdown: "# {{date}}\nWeather: {{weather}}\n## What went well\n## Note to tomorrow's me"),
                NotebookCardContent(name: "Travel log", remindsDaily: false, markdown: "# {{place}} day 1\n## Where I walked\n## What I ate"),
            ]
        }
    }
}

struct AppStoreScreenshot4Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot4Page(language: .ja, canvas: .iphone)
    }
}
#endif
