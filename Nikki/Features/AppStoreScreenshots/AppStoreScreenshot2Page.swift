import SwiftUI

#if DEBUG
/// スクショ2枚目: 自動ロック画面。手が止まると自動でロックされる安心感を訴求する。
struct AppStoreScreenshot2Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (title, subtitle) = switch language {
        case .ja: (
            "手が止まると\nそっとロック",
            "Face ID / Touch ID でひらきます"
        )
        case .en: (
            "Step away\nand it locks itself",
            "Open again with Face ID / Touch ID"
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotLockScreen(language: language, canvas: canvas)
        }
    }
}

/// ロック画面のモック。本番の LockSkeletonBackground と LockPadlockCircle を再利用し、
/// 文言と解除ボタンだけ言語別の静的表現にする(LockOverlay は文言が日本語固定のため)。
struct AppStoreScreenshotLockScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        // Mac のウィンドウモックでは実機と同じ Touch ID 表記にする(Mac に Face ID は無いため)。
        let (heading, caption, buttonIcon, buttonTitle, footnote) = switch (language, canvas) {
        case (.ja, .mac): (
            "鍵をかけておきました",
            "しばらく手が止まっていたので、\nそっとロックしました。",
            InkIcons.touchID,
            "Touch ID で開く",
            "解除すると、さっきの続きに戻ります"
        )
        case (.ja, _): (
            "鍵をかけておきました",
            "しばらく手が止まっていたので、\nそっとロックしました。",
            InkIcons.faceID,
            "Face ID で開く",
            "解除すると、さっきの続きに戻ります"
        )
        case (.en, .mac): (
            "Locked, just in case",
            "Your hands rested for a while,\nso we quietly locked the page.",
            InkIcons.touchID,
            "Open with Touch ID",
            "Unlock to pick up right where you left off"
        )
        case (.en, _): (
            "Locked, just in case",
            "Your hands rested for a while,\nso we quietly locked the page.",
            InkIcons.faceID,
            "Open with Face ID",
            "Unlock to pick up right where you left off"
        )
        }
        ZStack(alignment: .top) {
            LockSkeletonBackground()

            VStack(spacing: 20) {
                LockPadlockCircle()

                VStack(spacing: 8) {
                    Text(heading)
                        .font(.ink(16, .bold))
                        .foregroundStyle(Color.ink)
                    Text(caption)
                        .font(.ink(12.5, .regular))
                        .foregroundStyle(Color.inkTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
                }

                AppStoreScreenshotPillButton(systemName: buttonIcon, title: buttonTitle)
                    .padding(.top, 8)

                Text(footnote)
                    .font(.ink(12, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .padding(.horizontal, 28)
            // キャンバス下端で見切れる前の可視領域の中で、オーバーレイが中央近くに見える高さ。
            .padding(.top, 130)
            .frame(maxWidth: .infinity)
        }
    }
}

struct AppStoreScreenshot2Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot2Page(language: .ja, canvas: .iphone)
    }
}
#endif
