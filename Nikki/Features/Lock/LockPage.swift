import SwiftUI
#if os(macOS)
import AppKit
#endif

/// 自動ロック時に表示するロック画面(1f)。背景の日記本文をぼかして中身を守り、
/// 中央のオーバーレイで再開を促す。解除に成功すると locked を false に戻し、直前の画面がそのまま現れる。
/// macOS ではウィンドウのアクティブ化を起点に解除認証を自動提示し、別の通常アプリが前面になるか
/// ウィンドウが最小化されたら認証ダイアログを閉じる( https://github.com/bannzai/nikki/issues/52 )。
/// かつて自動提示は他アプリと行き来するたびにダイアログが残って邪魔なためやめた
/// ( https://github.com/bannzai/nikki/issues/47 )が、非表示時にダイアログを閉じることで解消したため提示し直す。
struct LockPage: View {
    /// 自動ロック状態。Face ID 解除の成功で false に戻す。
    @Binding var locked: Bool

    #if os(macOS)
    /// ウィンドウの見た目のアクティブ状態。アプリがアクティブでもウィンドウが最小化されている間は false になるため、
    /// アプリ単位のアクティブ状態ではなくこの値で判定し、非表示のウィンドウから認証ダイアログを出さない。
    @Environment(\.appearsActive) var appearsActive
    /// ウィンドウがアクティブになった時に解除認証を自動提示してよいか。
    /// その場でキャンセルした直後に起きる再アクティブ化で提示ループにならないよう提示のたびに消費し、
    /// 別の通常アプリが前面になった時にだけ引き直す。
    /// ウィンドウがアクティブなままロックされたケースでもロック画面の表示直後に自動提示したいため、初期値は提示可にする。
    @State var autoPromptArmed = true
    #endif

    var body: some View {
        ZStack {
            Color.inkPaper
            LockSkeletonBackground()
            LockOverlay(locked: $locked)
        }
        .ignoresSafeArea()
        #if os(macOS)
        // ウィンドウがアクティブなら「Touch ID で開く」を押さなくても Touch ID をそのまま受け付けられるよう、
        // ロック画面の表示とウィンドウのアクティブ化で解除認証を自動提示する。
        .task {
            if appearsActive {
                await autoPromptUnlock()
            }
        }
        .onChange(of: appearsActive) {
            if appearsActive {
                Task {
                    await autoPromptUnlock()
                }
            }
        }
        // 別の通常アプリが前面になったら、認証ダイアログを他アプリの上に残さないよう閉じ、
        // 次のアクティブ化で提示し直せるよう引き直す。認証ダイアログ自身が起こす前面切り替え
        // (coreautha。Dock に出ない非 regular なプロセス)を対象にすると提示した直後に閉じる
        // ループになるため、通常アプリだけを対象にする。
        .onReceive(
            NSWorkspace.shared.notificationCenter
                .publisher(for: NSWorkspace.didActivateApplicationNotification)
                .receive(on: DispatchQueue.main)
        ) { notification in
            if let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               application.processIdentifier != ProcessInfo.processInfo.processIdentifier,
               application.activationPolicy == .regular {
                cancelUnlockAuthentication()
                autoPromptArmed = true
            }
        }
        // ウィンドウの最小化も認証ダイアログだけが残る非表示だが、アプリの前面切り替えが起きず
        // didActivateApplicationNotification では検知できないため、最小化通知で閉じて引き直す。
        .onReceive(
            NotificationCenter.default
                .publisher(for: NSWindow.didMiniaturizeNotification)
                .receive(on: DispatchQueue.main)
        ) { _ in
            cancelUnlockAuthentication()
            autoPromptArmed = true
        }
        // ウィンドウが閉じられた時も認証ダイアログだけを残さないよう閉じる。
        .onDisappear {
            cancelUnlockAuthentication()
        }
        #endif
    }

    #if os(macOS)
    /// ロック解除の認証を自動提示する。キャンセル・失敗時はロックを維持し、以降の解除はボタンか再アクティブ化に委ねる。
    private func autoPromptUnlock() async {
        if !autoPromptArmed {
            return
        }
        // appearsActive の変化から Task の実行までの間にウィンドウが非アクティブ化・最小化され得る。
        // environment の appearsActive は Task 生成時点のスナップショットで実行時点の状態を参照できないため、
        // 提示直前に実行時点の前面状態を確認し、非アクティブなウィンドウから認証ダイアログを出さない。
        if !NSApp.isActive || NSApp.keyWindow == nil {
            return
        }
        // 生体認証を使えない環境では自動提示せず、ボタンからの解除に委ねる。
        // パスワードしか使えない Mac では入力必須のパネルがアクティブ化のたびに割り込んで邪魔なため、
        // パスコード未設定の端末(シミュレータ等)では自動提示が表示直後の即時解除になりロック画面が無意味になるため。
        if !canEvaluateBiometricsUnlockAuthentication() {
            return
        }
        autoPromptArmed = false
        if await evaluateUnlockAuthentication() {
            locked = false
        }
    }
    #endif
}

struct LockPage_Previews: PreviewProvider {
    static var previews: some View {
        LockPage(locked: .constant(true))
    }
}
