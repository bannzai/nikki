import SwiftUI

#if DEBUG
/// スクショ4枚目: テンプレートの変数入力シート。今日の紙を選んですぐ書き始められることを訴求する。
struct AppStoreScreenshot4Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        // 機能(テンプレート)をタイトルで先に伝える。情緒的な「今日の紙を選ぶ」はサブに置く。
        let (title, subtitle) = switch language {
        case .ja: (
            "テンプレートで、\nすぐ書きはじめる",
            "「朝の3行」「一日の振り返り」から今日の紙を選ぶ"
        )
        case .en: (
            "Start right away\nwith templates",
            "Pick today's page, like \"3 lines in the morning\""
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotTemplateScreen(language: language, canvas: canvas)
        }
    }
}

/// テンプレートの変数入力シートのモック画面。本番の TemplateVariableBackdrop と
/// TemplateMarkdownPreview を再利用し、シートカードと変数フィールドは言語別の静的表現にする
/// (TemplateVariableSheet は見出し・ボタンの文言が日本語固定のため)。
struct AppStoreScreenshotTemplateScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (sheetTitle, sheetCaption, autoBadge, dateName, dateValue, weatherName, weatherValue, preview, buttonTitle) = switch language {
        case .ja: (
            "「一日の振り返り」から作成",
            "埋めた言葉が、そのまま本文に入ります。",
            "自動",
            "date",
            "2026年7月18日",
            "weather",
            "晴れのち夕立",
            "# 2026年7月18日\n天気: 晴れのち夕立\n## よかったこと\n## 明日のじぶんへ",
            "この内容ではじめる"
        )
        case .en: (
            "Create from \"Daily reflection\"",
            "Your words go straight into the entry.",
            "Auto",
            "date",
            "July 18, 2026",
            "weather",
            "Sunny, then showers",
            "# July 18, 2026\nWeather: Sunny, then showers\n## What went well\n## Note to tomorrow's me",
            "Start with this"
        )
        }
        ZStack(alignment: .top) {
            TemplateVariableBackdrop()

            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(hex: 0xD5D4CF))
                    .frame(width: 38, height: 4.5)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 18)

                Text(sheetTitle)
                    .font(.ink(17, .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.bottom, 4)

                Text(sheetCaption)
                    .font(.ink(12.5, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    AppStoreScreenshotTemplateFieldCard(name: dateName, value: dateValue, autoBadge: autoBadge)
                    AppStoreScreenshotTemplateFieldCard(name: weatherName, value: weatherValue, autoBadge: nil)
                }

                TemplateMarkdownPreview(markdown: preview)
                    .padding(.top, 18)

                Text(buttonTitle)
                    .font(.ink(16, .medium).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(Color.inkPrimaryButtonText)
                    .background(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                    .padding(.top, 18)
            }
            .padding(.top, 14)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            // シートの紙地が画面下端(キャンバス外の見切れ)まで続くよう、残りの高さいっぱいに広げる。
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24,
                    style: .continuous
                )
                .fill(Color.inkPaper)
                .shadow(color: Color.ink.opacity(0.18), radius: 20, x: 0, y: -12)
            )
            // キャンバス下端で見切れる前の可視領域に、シートの見出しからボタンまでが収まる高さ。
            .padding(.top, 80)
        }
    }
}

/// 変数入力カードのモック。TemplateVariableFieldCard と同じ見た目で、
/// {{name}} ラベル・値・「自動」バッジを言語別に渡せる静的表現にする。
struct AppStoreScreenshotTemplateFieldCard: View {
    let name: String
    let value: String
    /// 自動入力バッジの文言。nil のときはバッジを表示しない(手入力の変数)。
    let autoBadge: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("{{\(name)}}")
                    .font(.inkMono(11, weight: .semibold))
                    .foregroundStyle(Color.inkLabelGray)
                if let autoBadge {
                    Spacer(minLength: 8)
                    Text(autoBadge)
                        .font(.inkMono(10.5))
                        .foregroundStyle(Color.inkTextTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.inkSurfaceInset)
                        )
                }
            }
            Text(value)
                .font(.ink(14.5, .regular))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.inkBorder, lineWidth: 1)
        )
    }
}

struct AppStoreScreenshot4Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot4Page(language: .ja, canvas: .iphone)
    }
}
#endif
