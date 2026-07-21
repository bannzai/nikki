import SwiftUI

/// セクション見出し(紙の色 / 背景画像)のスタイル。
struct ThemeSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(InkTypography.font(12, .bold))
            .foregroundStyle(InkColors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
