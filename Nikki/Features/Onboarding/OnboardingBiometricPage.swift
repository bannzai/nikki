import SwiftUI

/// オンボーディング 1e: Face ID / パスキー登録を促す最終ステップ。
struct OnboardingBiometricPage: View {
    /// オンボーディングの完了状態。Face ID / パスキーの実登録は未実装のため、どちらのボタンも完了として扱う。
    @Binding var onboardingCompleted: Bool

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 2, total: 2)

                VStack(spacing: 26) {
                    Image(systemName: InkIcons.faceID)
                        .font(.system(size: 86, weight: .regular))
                        .foregroundStyle(Color.ink)

                    Text("つぎからは、\n顔だけで。")
                        .font(.ink(24, .bold))
                        .lineSpacing(inkLineSpacing(fontSize: 24, multiplier: 1.65))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)

                    Text("開きっぱなしの画面は自動でロック。Face ID がそっと鍵を開けます。")
                        .font(.ink(13.5, .regular))
                        .lineSpacing(inkLineSpacing(fontSize: 13.5, multiplier: 2.05))
                        .foregroundStyle(Color.inkTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 290)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    Button("Face ID を有効にする") {
                        onboardingCompleted = true
                    }
                    .buttonStyle(InkPrimaryButtonStyle())
                    Button("パスキーを登録する") {
                        onboardingCompleted = true
                    }
                    .buttonStyle(InkSecondaryButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
    }
}

struct OnboardingBiometricPage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingBiometricPage(onboardingCompleted: .constant(false))
    }
}
