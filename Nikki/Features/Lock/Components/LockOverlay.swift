import SwiftUI

/// 画面中央のロック解除オーバーレイ(南京錠円・文言・Face ID ボタン・脚注)。
struct LockOverlay: View {
    /// 自動ロック状態。Face ID ボタンが解除に成功すると false に戻す。
    @Binding var locked: Bool

    var body: some View {
        VStack(spacing: 20) {
            LockPadlockCircle()

            VStack(spacing: 8) {
                Text("鍵をかけておきました")
                    .font(.ink(16, .bold))
                    .foregroundStyle(Color.ink)
                Text("しばらく手が止まっていたので、\nそっとロックしました。")
                    .font(.ink(12.5, .regular))
                    .foregroundStyle(Color.inkTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
            }

            LockFaceIDButton(locked: $locked)
                .padding(.top, 8)

            Text("解除すると、さっきの続きに戻ります")
                .font(.ink(12, .regular))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .padding(.horizontal, 28)
    }
}

/// 64px 円(半透明地 + 細枠)に南京錠アイコンを収めたシンボル。
struct LockPadlockCircle: View {
    var body: some View {
        Circle()
            .fill(Color.inkPaper.opacity(0.85))
            .overlay(Circle().strokeBorder(Color.ink.opacity(0.3), lineWidth: 1.5))
            .frame(width: 64, height: 64)
            .overlay { LockPadlockIcon() }
    }
}

struct LockOverlay_Previews: PreviewProvider {
    static var previews: some View {
        LockOverlay(locked: .constant(true))
            .background(Color.inkPaper)
    }
}
