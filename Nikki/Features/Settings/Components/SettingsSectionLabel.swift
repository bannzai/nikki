import SwiftUI

/// グループ化リストのセクション見出し(小さな灰色ラベル)。
struct SettingsSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(InkTypography.font(12, .medium))
            .foregroundStyle(InkColors.textTertiary)
            .padding(.horizontal, 2)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
