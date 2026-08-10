import SwiftUI

/// 自動ロック時に表示するロック画面(1f)。背景の日記本文をぼかして中身を守り、
/// 中央のオーバーレイで再開を促す。解除に成功すると locked を false に戻し、直前の画面がそのまま現れる。
struct LockPage: View {
    /// 自動ロック状態。Face ID 解除の成功で false に戻す。
    @Binding var locked: Bool

    #if os(macOS)
    /// ウィンドウの見た目のアクティブ状態。アプリがアクティブでもウィンドウが最小化されている間は false になるため、
    /// アプリ単位のアクティブ状態ではなくこの値で判定し、非表示のウィンドウから認証ダイアログを出さない。
    @Environment(\.appearsActive) var appearsActive
    /// ウィンドウがアクティブになった時に解除認証を自動提示してよいか。
    /// 認証ダイアログ自身が起こすアクティブ切り替えで提示ループにならないよう、提示のたびに消費し、
    /// 評価中ではない非アクティブ化(ユーザーが他アプリへ移った時)と、評価終了時にアプリが非アクティブのまま
    /// だった場合(ダイアログを残して他アプリへ移り、そこでキャンセルした時)にのみ引き直す。
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
            } else if !autoPromptEvaluating {
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
        } else {
            // 認証ダイアログを残したまま他アプリへ移ると Nikki は既に非アクティブで、以降ウィンドウの
            // アクティブ切り替えが起きないため、ここで引き直さないと復帰時に自動提示できない。
            // その場でキャンセルしただけの場合はフォーカスが Nikki に戻るまでにわずかな間があり、
            // すぐ判定すると非アクティブ扱いの引き直し→再アクティブ化で再提示ループになり得るため、
            // フォーカスの戻りが落ち着くのを待ってから判定する。
            try? await Task.sleep(for: .milliseconds(500))
            if !NSApp.isActive {
                autoPromptArmed = true
            }
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
