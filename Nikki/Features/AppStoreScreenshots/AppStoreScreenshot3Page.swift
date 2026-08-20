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

/// エディタのモック画面。実際の EditorPage と同じく、タイトル + 生の markdown 本文をそのまま表示する
/// (実エディタは TextEditor で markdown を装飾せずに編集するため、装飾済みのブロック表示は使わない)。
/// 外枠は本番の EditorScreenScaffold を再利用し、本文だけ言語別のサンプルにする。
struct AppStoreScreenshotEditorScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (caption, entryTitle, markdownBody) = switch language {
        case .ja: (
            "7月18日 土曜日",
            "梅雨明け",
            """
            朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。

            ## 買ったもの

            - [x] 麦茶のパック
            - [ ] 蚊取り線香

            ## 夕方から

            風が涼しくなってきたので、窓を全部開けて麦茶を飲んだ。
            """
        )
        case .en: (
            "Saturday, July 18",
            "Summer begins",
            """
            Cicadas were singing from early morning. Watering the pots on the balcony, I realized summer is here again.

            ## Picked up

            - [x] Barley tea packs
            - [ ] Mosquito coils

            ## In the evening

            The breeze turned cool, so I opened every window and poured myself some barley tea.
            """
        )
        }
        EditorScreenScaffold(caption: caption, onDismiss: {}) {
            VStack(alignment: .leading, spacing: 0) {
                Text(entryTitle)
                    .font(.inkEntryTitle)
                    .foregroundStyle(Color.ink)
                    .padding(.bottom, 8)

                // EditorPage の TextEditor と同じ書体・行間(標準の文字の大きさ 15pt)。
                Text(markdownBody)
                    .font(.ink(15))
                    .lineSpacing(inkLineSpacing(fontSize: 15, multiplier: 2.05))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
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
