import SwiftUI

/// ロック画面の「パスキーで開く」枠線ボタン。パスキーが登録済みの端末でだけ表示し、
/// タップで OS のパスキー認証を行い、保存済みの公開鍵で検証できたら locked を false に戻す。
struct LockPasskeyButton: View {
    /// 自動ロック状態。解除の成功で false に戻す。
    @Binding var locked: Bool

    @AppStorage(.passkeyCredentialID) var passkeyCredentialID: Data = Data()
    @AppStorage(.passkeyPublicKey) var passkeyPublicKey: Data = Data()

    var body: some View {
        if !passkeyCredentialID.isEmpty {
            Button {
                Task {
                    if await evaluatePasskeyUnlockAuthentication(credential: PasskeyCredential(credentialID: passkeyCredentialID, publicKey: passkeyPublicKey)) {
                        locked = false
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: InkIcons.passkey)
                        .font(.system(size: 18, weight: .regular))
                    Text("Open with passkey")
                        .font(.ink(15, .medium).weight(.semibold))
                }
            }
            .buttonStyle(LockPasskeyButtonStyle())
        }
    }
}

/// 「パスキーで開く」ボタンの ButtonStyle。主導線の Face ID ボタンと同じ pill 形で、枠線だけの二次ボタンにする。
private struct LockPasskeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.ink)
            .frame(height: 50)
            .padding(.horizontal, 26)
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .strokeBorder(Color.ink.opacity(0.3), lineWidth: 1.5)
            )
    }
}

struct LockPasskeyButton_Previews: PreviewProvider {
    static var previews: some View {
        LockPasskeyButton(locked: .constant(true))
            .padding()
            .background(Color.inkPaper)
    }
}
