import SwiftUI

/// ペイウォール上部のロゴ「日」+「Nikki Plus」ヘッダ。
struct PaywallHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("日")
                .font(InkTypography.font(18, .bold))
                .foregroundStyle(InkColors.ink)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(InkColors.ink, lineWidth: 2)
                )
            Text("Nikki Plus")
                .font(InkTypography.font(22, .bold))
                .tracking(0.44)
                .foregroundStyle(InkColors.ink)
            Spacer(minLength: 0)
        }
    }
}
