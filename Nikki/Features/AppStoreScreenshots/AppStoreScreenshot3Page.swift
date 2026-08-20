import SwiftUI

#if DEBUG
/// スクショ3枚目: エディタ。余計なもののない執筆体験とマークダウン互換(見出し・チェックリスト)を訴求する。
struct AppStoreScreenshot3Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (title, subtitle) = switch language {
        case .ja: (
            "書くことに集中できる\n静かなエディタ",
            "マークダウン互換で見出しもチェックリストも"
        )
        case .en: (
            "A quiet editor\nbuilt for writing",
            "Markdown-friendly with headings and checklists"
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotEditorScreen(language: language, canvas: canvas)
        }
    }
}

/// エディタのモック画面。本番の EditorScreenScaffold と各ブロック部品(段落・見出し・チェックリスト)を
/// 再利用し、本文だけ言語別のサンプルにする。
struct AppStoreScreenshotEditorScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (caption, entryTitle, paragraph, heading, checklist, closingHeading, closingParagraph) = switch language {
        case .ja: (
            "7月18日 土曜日",
            "梅雨明け",
            "朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。",
            "買ったもの",
            [ChecklistItem(text: "麦茶のパック", done: true), ChecklistItem(text: "蚊取り線香", done: false)],
            "夕方から",
            "風が涼しくなってきたので、窓を全部開けて麦茶を飲んだ。"
        )
        case .en: (
            "Saturday, July 18",
            "Summer begins",
            "Cicadas were singing from early morning. Watering the pots on the balcony, I realized summer is here again.",
            "Picked up",
            [ChecklistItem(text: "Barley tea packs", done: true), ChecklistItem(text: "Mosquito coils", done: false)],
            "In the evening",
            "The breeze turned cool, so I opened every window and poured myself some barley tea."
        )
        }
        EditorScreenScaffold(caption: caption, onDismiss: {}) {
            VStack(alignment: .leading, spacing: 0) {
                let paragraphHalfLeading = inkLineSpacing(fontSize: 15, multiplier: 2.05) / 2

                Text(entryTitle)
                    .font(.inkEntryTitle)
                    .lineSpacing(inkLineSpacing(fontSize: 22, multiplier: 1.6))
                    .foregroundStyle(Color.ink)
                    .padding(.bottom, 14)

                EditorParagraphBlock(text: paragraph)
                    .padding(.vertical, paragraphHalfLeading)

                EditorHeadingBlock(level: 2, text: heading)
                    .padding(.top, 18)
                    .padding(.bottom, 10)

                EditorChecklistBlock(items: checklist)

                EditorHeadingBlock(level: 2, text: closingHeading)
                    .padding(.top, 22)
                    .padding(.bottom, 10)

                EditorParagraphBlock(text: closingParagraph)
                    .padding(.vertical, paragraphHalfLeading)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
        .padding(.top, appStoreScreenshotScreenTopPadding(canvas: canvas))
    }
}

struct AppStoreScreenshot3Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot3Page(language: .ja, canvas: .iphone)
    }
}
#endif
