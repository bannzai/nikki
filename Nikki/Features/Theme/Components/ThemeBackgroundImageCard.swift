import SwiftUI

/// 背景画像の選択リスト。「写真から選ぶ」(no-op)と現在選択中の「なし」。
struct ThemeBackgroundImageCard: View {
    var body: some View {
        InkListSection {
            InkListRow("写真から選ぶ", action: {})
            HStack(spacing: 8) {
                Text("なし")
                    .font(InkTypography.font(14.5, .regular))
                    .foregroundStyle(InkColors.textSecondary)
                Spacer(minLength: 8)
                Image(systemName: InkIcons.checkmark)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(InkColors.ink)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
    }
}
