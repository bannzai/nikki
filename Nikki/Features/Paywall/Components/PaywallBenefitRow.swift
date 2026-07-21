import SwiftUI

/// 特典1件(チェック + タイトル + 説明)。
struct PaywallBenefitRow: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: InkIcons.checkmark)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(InkColors.ink)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(InkTypography.font(14.5, .bold))
                    .foregroundStyle(InkColors.ink)
                Text(description)
                    .font(InkTypography.font(12.5, .regular))
                    .foregroundStyle(InkColors.textSecondary)
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 12.5, multiplier: 1.9))
            }
            Spacer(minLength: 0)
        }
    }
}
