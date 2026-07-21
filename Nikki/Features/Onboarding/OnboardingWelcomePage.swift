import SwiftUI

/// オンボーディング 1a: ようこそ画面。ロゴ + キャッチコピー + はじめる導線。
struct OnboardingWelcomePage: View {
    var onStart: () -> Void = {}

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                OnboardingLogoMark()
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    Text("ここに書くことは、\nあなたしか読めません。")
                        .font(InkTypography.font(25, .bold))
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 25, multiplier: 1.7))
                        .foregroundStyle(InkColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("日記はこの端末の中で暗号化されます。わたしたち開発者にも、中身を見ることはできません。")
                        .font(InkTypography.font(14.5, .regular))
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 14.5, multiplier: 2.1))
                        .foregroundStyle(InkColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                InkPrimaryButton("はじめる", action: onStart)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    OnboardingWelcomePage()
}
