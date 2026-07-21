import SwiftUI

/// 選択中の紙色を地にしたライブプレビュー。見出し + 本文のサンプルを表示する。
struct ThemePreviewCard: View {
    /// プレビューの地に使う紙色。
    let paperColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("プレビュー")
                .font(InkTypography.font(11, .regular))
                .foregroundStyle(InkColors.textTertiary)
                .padding(.bottom, 10)
            Text("梅雨明け")
                .font(InkTypography.font(18, .bold))
                .foregroundStyle(InkColors.ink)
                .padding(.bottom, 8)
            Text("朝から蝉が鳴いていた。今年も夏が来たんだなと思う。")
                .font(InkTypography.font(13, .regular))
                .lineSpacing(InkTypography.lineSpacing(fontSize: 13, multiplier: 2.0))
                .foregroundStyle(InkColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(paperColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(InkColors.border, lineWidth: 1)
        )
    }
}
