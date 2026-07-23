import SwiftUI

/// 選択中の紙色を地にしたライブプレビュー。見出し + 本文のサンプルを表示する。
struct ThemePreviewCard: View {
    /// プレビューの地に使う紙色。
    let paperColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("プレビュー")
                .font(.ink(11, .regular))
                .foregroundStyle(Color.inkTextTertiary)
                .padding(.bottom, 10)
            Text("梅雨明け")
                .font(.ink(18, .bold))
                .foregroundStyle(Color.ink)
                .padding(.bottom, 8)
            Text("朝から蝉が鳴いていた。今年も夏が来たんだなと思う。")
                .font(.ink(13, .regular))
                .lineSpacing(inkLineSpacing(fontSize: 13, multiplier: 2.0))
                .foregroundStyle(Color.inkTextSecondary)
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
                .strokeBorder(Color.inkBorder, lineWidth: 1)
        )
    }
}
