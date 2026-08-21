import SwiftUI

/// オンボーディング 1e: 生体認証(Face ID / Touch ID) / パスキー登録を促す最終ステップ。
/// 端末で使える生体認証に合わせて図像と文言を出し分ける。
struct OnboardingBiometricPage: View {
    /// オンボーディングの完了状態。生体認証 / パスキーの実登録は未実装のため、どちらのボタンも完了として扱う。
    @Binding var onboardingCompleted: Bool

    var body: some View {
        // 生体認証が使えない端末(パスコード未設定・生体認証なしの Mac 等)は OS の用語(macOS: パスワード、iOS / iPadOS: パスコード)に合わせる。
        #if os(macOS)
        let fallback = (InkIcons.lock, String(localized: "From now on,\nit's easy."), String(localized: "Left open, the screen locks itself. Your password quietly opens it again."), String(localized: "Enable auto-lock"))
        #else
        let fallback = (InkIcons.lock, String(localized: "From now on,\nit's easy."), String(localized: "Left open, the screen locks itself. Your passcode quietly opens it again."), String(localized: "Enable auto-lock"))
        #endif
        let (systemName, headline, description, primaryButtonTitle) = switch currentBiometryType() {
        case .faceID: (InkIcons.faceID, String(localized: "From now on,\njust your face."), String(localized: "Left open, the screen locks itself. Face ID quietly opens it again."), String(localized: "Enable Face ID"))
        case .touchID: (InkIcons.touchID, String(localized: "From now on,\njust a fingertip."), String(localized: "Left open, the screen locks itself. Touch ID quietly opens it again."), String(localized: "Enable Touch ID"))
        default: fallback
        }
        ZStack {
            Color.inkPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 2, total: 2)

                VStack(spacing: 26) {
                    Image(systemName: systemName)
                        .font(.system(size: 86, weight: .regular))
                        .foregroundStyle(Color.ink)

                    Text(headline)
                        .font(.ink(24, .bold))
                        .lineSpacing(inkLineSpacing(fontSize: 24, multiplier: 1.65))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.ink(13.5, .regular))
                        .lineSpacing(inkLineSpacing(fontSize: 13.5, multiplier: 2.05))
                        .foregroundStyle(Color.inkTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 290)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    Button(primaryButtonTitle) {
                        onboardingCompleted = true
                    }
                    .buttonStyle(InkPrimaryButtonStyle())
                    Button("Register a passkey") {
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
