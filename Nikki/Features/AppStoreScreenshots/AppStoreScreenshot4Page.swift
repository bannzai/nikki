import SwiftUI

#if DEBUG
/// スクショ4枚目: テンプレート一覧。テンプレートを選んですぐ書き始められることを訴求する。
struct AppStoreScreenshot4Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        // 機能(テンプレート)をタイトルで先に伝える。使い方の具体例はサブに置く。
        let (title, subtitle) = switch language {
        case .ja: (
            "テンプレートで\nすぐ書きはじめる",
            "「朝の3行」「一日の振り返り」から今日のテンプレートを選ぶ"
        )
        case .en: (
            "Start right away\nwith templates",
            "Pick a template like \"3 lines in the morning\""
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotNotebookScreen(language: language, canvas: canvas)
        }
    }
}

/// テンプレート一覧のモック画面。実際の NotebookListPage と同じ構成
/// (ナビ + 見出し + テンプレートカードの並び)を、文言を言語別に渡せる静的表現で再現する
/// (NotebookListPage はナビタイトル・リマインド表示が日本語固定のため)。
struct AppStoreScreenshotNotebookScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (navTitle, heading, reminderDaily) = switch language {
        case .ja: ("テンプレート", "この日記に使うテンプレートを選べます。", "毎日")
        case .en: ("Templates", "Choose the template for this entry.", "Daily")
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
                    ForEach(Array(AppStoreScreenshotDiary.notebookCards(language: language).enumerated()), id: \.offset) { index, card in
                        AppStoreScreenshotNotebookCard(
                            name: card.name,
                            reminder: card.remindsDaily ? reminderDaily : "",
                            markdown: card.markdown,
                            // 実画面と同じく、既定 (先頭の白紙) が選ばれている状態を見せる。
                            isSelected: index == 0
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, appStoreScreenshotScreenTopPadding(canvas: canvas))
    }
}

/// テンプレートカードのモック。NotebookCard と同じ見た目(名前 + リマインド + チェック/シェブロン + markdown プレビュー)で、
/// 文言を言語別に渡せる静的表現にする。
struct AppStoreScreenshotNotebookCard: View {
    let name: String
    /// リマインド頻度の表示文言。空のときは表示しない(リマインドなしのテンプレート)。
    let reminder: String
    let markdown: String
    /// このカードのテンプレートが選択中かどうか。NotebookCard と同じくチェックで表す。
    let isSelected: Bool

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
                Image(systemName: isSelected ? InkIcons.checkmark : InkIcons.chevronRight)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.ink : Color.inkTextTertiary)
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
