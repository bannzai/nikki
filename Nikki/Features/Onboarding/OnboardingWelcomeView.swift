import SwiftUI

/// オンボーディング 1a: ようこそ画面。ロゴ + キャッチコピー + はじめる導線。
struct OnboardingWelcomeView: View {
    var onStart: () -> Void = {}
    var onRestore: () -> Void = {}

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                logoMark
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

                VStack(spacing: 14) {
                    InkPrimaryButton("はじめる", action: onStart)
                    InkTextLink("以前の日記を復元する", action: onRestore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
    }

    private var logoMark: some View {
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

#Preview {
    OnboardingWelcomeView()
}
