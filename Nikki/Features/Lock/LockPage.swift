import SwiftUI

/// 自動ロック時に表示するロック画面(1f)。背景の日記本文をぼかして中身を守り、
/// 中央のオーバーレイで再開を促す。解除に成功すると locked を false に戻し、直前の画面がそのまま現れる。
struct LockPage: View {
    /// 自動ロック状態。Face ID 解除の成功で false に戻す。
    @Binding var locked: Bool

    #if os(macOS)
    /// ウィンドウがアクティブになった時に解除認証を自動提示してよいか。
    /// 認証ダイアログ自身が起こすアプリのアクティブ切り替えで提示ループにならないよう、提示のたびに消費し、
    /// 評価中ではない非アクティブ化(ユーザーが他アプリへ移った時)でのみ引き直す。
    /// ウィンドウがアクティブなままロックされたケースでもロック画面の表示直後に自動提示したいため、初期値は提示可にする。
    @State var autoPromptArmed = true
    /// 自動提示した認証を評価中かどうか。評価中の認証ダイアログによる非アクティブ化を引き直しから除外するために使う。
    @State var autoPromptEvaluating = false
    #endif

    var body: some View {
        ZStack {
            Color.inkPaper
            LockSkeletonBackground()
            LockOverlay(locked: $locked)
        }
        .ignoresSafeArea()
        #if os(macOS)
        // macOS ではウィンドウがアクティブなら「Touch ID で開く」を押さなくても Touch ID をそのまま受け付けられるよう、
        // ロック画面の表示とアプリのアクティブ化で解除認証を自動提示する。
        .task {
            if NSApp.isActive {
                await autoPromptUnlock()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await autoPromptUnlock()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            if !autoPromptEvaluating {
                autoPromptArmed = true
            }
        }
        #endif
    }

    #if os(macOS)
    /// ロック解除の認証を自動提示する。キャンセル・失敗時はロックを維持し、以降の解除はボタンか再アクティブ化に委ねる。
    private func autoPromptUnlock() async {
        if !autoPromptArmed || autoPromptEvaluating {
            return
        }
        // 評価できる認証手段がない端末(パスコード未設定のシミュレータ等)では、自動提示すると表示直後の即時解除になり
        // ロック画面が無意味になるため、自動提示はせずボタンからの解除に委ねる。
        if !canEvaluateUnlockAuthentication() {
            return
        }
        autoPromptArmed = false
        autoPromptEvaluating = true
        if await evaluateUnlockAuthentication() {
            locked = false
        }
        autoPromptEvaluating = false
    }
    #endif
}

struct LockPage_Previews: PreviewProvider {
    static var previews: some View {
        LockPage(locked: .constant(true))
    }
}
