import SwiftUI

/// オンボーディング 1e: 生体認証(Face ID / Touch ID)を促す最終ステップ。
/// 端末で使える生体認証に合わせて図像と文言を出し分ける。
struct OnboardingBiometricPage: View {
    /// オンボーディングの完了状態。生体認証の実登録は OS 設定に委ねるため、ボタンは完了として扱う。
    @Binding var onboardingCompleted: Bool

    /// パスキー登録に失敗した時のエラー文言。nil でアラートを閉じる。
    @State var passkeyRegistrationErrorMessage: String?

    /// 登録済みパスキー(issue #84)。「パスキーを登録する」の成功で保存し、オンボーディングを完了にする。
    @AppStorage(.passkeyCredentialID) var passkeyCredentialID: Data = Data()
    @AppStorage(.passkeyPublicKey) var passkeyPublicKey: Data = Data()

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

                VStack(spacing: 10) {
                    Button(primaryButtonTitle) {
                        onboardingCompleted = true
                    }
                    .buttonStyle(InkPrimaryButtonStyle())

                    // パスキーはロック解除の代替手段(issue #84)。登録できたらそのまま完了し、キャンセルならこの画面に留まる。
                    Button("Register a passkey") {
                        Task {
                            await registerPasskeyAndComplete()
                        }
                    }
                    .buttonStyle(InkSecondaryButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
        .alert("Couldn't register the passkey", isPresented: Binding(get: { passkeyRegistrationErrorMessage != nil }, set: { if !$0 { passkeyRegistrationErrorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(passkeyRegistrationErrorMessage ?? "")
        }
    }

    /// OS のパスキー登録を起動し、成功したら識別子と公開鍵を保存してオンボーディングを完了にする。
    /// キャンセルは何もせず、それ以外の失敗はアラートで知らせる(設定の登録行と同じ扱い)。
    private func registerPasskeyAndComplete() async {
        do {
            let credential = try await registerPasskey()
            // 登録状態の判定に使う credentialID は最後に保存する。2 つの値は別々に書き込まれるため、
            // 先に credentialID だけが残ると公開鍵なしで登録済み扱いになる。
            passkeyPublicKey = credential.publicKey
            passkeyCredentialID = credential.credentialID
            onboardingCompleted = true
        } catch {
            if !isPasskeyCanceled(error: error) {
                passkeyRegistrationErrorMessage = error.localizedDescription
            }
        }
    }
}

struct OnboardingBiometricPage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingBiometricPage(onboardingCompleted: .constant(false))
    }
}
