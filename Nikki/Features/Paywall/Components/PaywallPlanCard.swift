import SwiftUI

/// 料金プランカード。選択時は墨枠 + 白背景で強調する。
struct PaywallPlanCard: View {
    let title: String
    let price: String
    let caption: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(InkTypography.font(12, .regular))
                .foregroundStyle(InkColors.textSecondary)
                .padding(.bottom, 6)
            Text(price)
                .font(InkTypography.font(20, .bold))
                .foregroundStyle(InkColors.ink)
            Text(caption)
                .font(InkTypography.font(11, .regular))
                .foregroundStyle(InkColors.textTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? InkColors.surface : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                // 未選択の淡い枠は見本の rgba(28,27,26,.2) を再現するため直接指定する。
                .strokeBorder(isSelected ? InkColors.ink : InkColors.ink.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .top) {
            if let badge {
                Text(badge)
                    .font(InkTypography.font(10, .medium))
                    .foregroundStyle(InkColors.primaryButtonText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(InkColors.ink)
                    )
                    .offset(y: -9)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}
