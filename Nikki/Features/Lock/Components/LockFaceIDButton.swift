import SwiftUI
import LocalAuthentication

/// ロック解除の墨 pill ボタン。高さ50・横パディング26・角丸25。
/// 端末で使える生体認証(Face ID / Touch ID)に合わせて文言とアイコンを出し分ける。
/// タップで生体認証(使えない場合はパスコード / パスワード)を評価し、成功したら locked を false に戻す。
struct LockFaceIDButton: View {
    /// 自動ロック状態。解除の成功で false に戻す。
    @Binding var locked: Bool

    var body: some View {
        // 生体認証が使えない端末(パスコード未設定・生体認証なしの Mac 等)は OS の用語(macOS: パスワード、iOS / iPadOS: パスコード)に合わせる。
        #if os(macOS)
        let fallback = (InkIcons.lock, String(localized: "Open with password"))
        #else
        let fallback = (InkIcons.lock, String(localized: "Open with passcode"))
        #endif
        let (systemName, title) = switch currentBiometryType() {
        case .faceID: (InkIcons.faceID, String(localized: "Open with Face ID"))
        case .touchID: (InkIcons.touchID, String(localized: "Open with Touch ID"))
        default: fallback
        }
        Button {
            Task {
                await unlock()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .regular))
                Text(title)
                    .font(.ink(15, .medium).weight(.semibold))
            }
        }
        .buttonStyle(LockFaceIDButtonStyle())
    }

    /// 生体認証でロックを解除する。キャンセル・失敗時はロックを維持する。
    private func unlock() async {
        // パスコード未設定の端末(シミュレータ等)は評価できる認証手段がなく締め出しになるため、そのまま解除する。
        if !canEvaluateUnlockAuthentication() {
            locked = false
            return
        }
        if await evaluateUnlockAuthentication() {
            locked = false
        }
    }
}

/// 「Face ID で開く」ボタンの ButtonStyle。
private struct LockFaceIDButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.inkPrimaryButtonText)
            .frame(height: 50)
            .padding(.horizontal, 26)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color.ink)
            )
    }
}

struct LockFaceIDButton_Previews: PreviewProvider {
    static var previews: some View {
        LockFaceIDButton(locked: .constant(true))
            .padding()
            .background(Color.inkPaper)
    }
}
