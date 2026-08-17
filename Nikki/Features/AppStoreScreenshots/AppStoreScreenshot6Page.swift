import SwiftUI

#if DEBUG
/// スクショ6枚目: テーマ設定。紙色のカスタマイズと Nikki Plus を訴求する。
struct AppStoreScreenshot6Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (title, subtitle) = switch language {
        case .ja: (
            "紙の色を、\nじぶんの好みに",
            "テーマは Nikki Plus で解放"
        )
        case .en: (
            "Paper in your\nfavorite shade",
            "Themes unlock with Nikki Plus"
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotThemeScreen(language: language, canvas: canvas)
        }
    }
}

/// テーマ設定のモック画面。スウォッチは本番の ThemeColorSwatch・セクション見出しは ThemeSectionLabel を
/// 再利用し、ナビタイトル・プレビューカード・スウォッチのラベルを言語別に渡す
/// (ThemePreviewCard はサンプル文言が日本語固定のため静的表現にする)。
/// 背景画像セクションは実画面に存在するが選択機能が未実装 (issue #54) のため、
/// 「実装済みの機能のみを見せる」方針でストア画像には載せない。
struct AppStoreScreenshotThemeScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (navTitle, previewLabel, previewTitle, previewBody, paperSection, swatchLabels) = switch language {
        case .ja: (
            "テーマ",
            "プレビュー",
            "梅雨明け",
            "朝から蝉が鳴いていた。今年も夏が来たんだなと思う。",
            "紙の色",
            ["白", "生成", "薄鼠", "青磁", "桜鼠"]
        )
        case .en: (
            "Theme",
            "Preview",
            "Summer begins",
            "Cicadas were singing this morning. Summer is here again.",
            "Paper color",
            ["White", "Cream", "Ash", "Celadon", "Sakura"]
        )
        }
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(navTitle))
            VStack(alignment: .leading, spacing: 0) {
                // ThemePreviewCard と同じライブプレビューの見た目。サンプル文言を言語別に渡す。
                VStack(alignment: .leading, spacing: 0) {
                    Text(previewLabel)
                        .font(.ink(11, .regular))
                        .foregroundStyle(Color.inkTextTertiary)
                        .padding(.bottom, 10)
                    Text(previewTitle)
                        .font(.ink(18, .bold))
                        .foregroundStyle(Color.ink)
                        .padding(.bottom, 8)
                    Text(previewBody)
                        .font(.ink(13, .regular))
                        .lineSpacing(inkLineSpacing(fontSize: 13, multiplier: 2.0))
                        .foregroundStyle(Color.inkTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24))
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.paperColorPreset[1])
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.inkBorder, lineWidth: 1)
                )
                .padding(.bottom, 22)

                ThemeSectionLabel(text: paperSection)
                    .padding(.bottom, 10)

                HStack(spacing: 14) {
                    ForEach(Color.paperColorPreset.indices, id: \.self) { index in
                        ThemeColorSwatch(
                            index: index,
                            label: swatchLabels[index],
                            selectedIndex: .constant(1),
                            locked: paperColorPresetRequiresPlus(index: index),
                            paywallSheetIsPresented: .constant(false)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .padding(.top, appStoreScreenshotScreenTopPadding(canvas: canvas))
    }
}

struct AppStoreScreenshot6Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot6Page(language: .ja, canvas: .iphone)
    }
}
#endif
