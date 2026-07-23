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
                .font(.ink(12, .regular))
                .foregroundStyle(Color.inkTextSecondary)
                .padding(.bottom, 6)
            Text(price)
                .font(.ink(20, .bold))
                .foregroundStyle(Color.ink)
            Text(caption)
                .font(.ink(11, .regular))
                .foregroundStyle(Color.inkTextTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.inkSurface : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                // 未選択の淡い枠は見本の rgba(28,27,26,.2) を再現するため直接指定する。
                .strokeBorder(isSelected ? Color.ink : Color.ink.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .top) {
            if let badge {
                Text(badge)
                    .font(.ink(10, .medium))
                    .foregroundStyle(Color.inkPrimaryButtonText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.ink)
                    )
                    .offset(y: -9)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}

struct PaywallPlanCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 14) {
            PaywallPlanCard(title: "月ごと", price: "¥300", caption: "/月", badge: nil, isSelected: false, onTap: {})
            PaywallPlanCard(title: "年ごと", price: "¥3,000", caption: "¥250/月", badge: "2ヶ月ぶんお得", isSelected: true, onTap: {})
        }
        .padding()
        .background(Color.inkPaper)
    }
}
