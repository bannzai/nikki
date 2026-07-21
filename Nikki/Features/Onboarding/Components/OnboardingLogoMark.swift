import SwiftUI

/// ようこそ画面のロゴマーク。角丸枠の「日」とワードマーク「Nikki」を縦に並べる。
struct OnboardingLogoMark: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(InkColors.ink, lineWidth: 2)
                .frame(width: 52, height: 52)
                .overlay {
                    Text("日")
                        .font(InkTypography.font(24, .bold))
                        .foregroundStyle(InkColors.ink)
                }
            Text("Nikki")
                .font(InkTypography.font(30, .bold))
                .tracking(30 * 0.04)
                .foregroundStyle(InkColors.ink)
        }
    }
}
