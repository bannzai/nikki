import SwiftUI

/// オンボーディング 1e: Face ID / パスキー登録を促す最終ステップ。
struct OnboardingBiometricPage: View {
    /// オンボーディングの完了状態。Face ID / パスキーの実登録は未実装のため、どちらのボタンも完了として扱う。
    @Binding var onboardingCompleted: Bool

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 2, total: 2)

                VStack(spacing: 26) {
                    Image(systemName: InkIcons.faceID)
                        .font(.system(size: 86, weight: .regular))
                        .foregroundStyle(InkColors.ink)

                    Text("つぎからは、\n顔だけで。")
                        .inkTextStyle(InkTypography.onboardingHeadline)
                        .foregroundStyle(InkColors.ink)
                        .multilineTextAlignment(.center)

                    Text("開きっぱなしの画面は自動でロック。Face ID がそっと鍵を開けます。")
                        .font(InkTypography.font(13.5, .regular))
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 13.5, multiplier: 2.05))
                        .foregroundStyle(InkColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 290)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    InkPrimaryButton("Face ID を有効にする") {
                        onboardingCompleted = true
                    }
                    InkSecondaryButton("パスキーを登録する") {
                        onboardingCompleted = true
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    OnboardingBiometricPage(onboardingCompleted: .constant(false))
}
