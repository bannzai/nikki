import SwiftUI
import RevenueCat
#if os(macOS)
import AppKit
#endif

/// オンボーディングの進行ステップ。完了したかどうかは onboardingCompleted が持つ。
enum OnboardingStep: String {
    case welcome
    case encryption
    case biometric
}

/// 自動ロックの無操作起点。View の @State(Date) で持つとテキスト編集のたびに RootPage 配下の
/// 全画面が再評価され、日本語入力の変換中テキストが破棄される(issue #86)ため、
/// 書き込みで再描画を起こさない参照型で持ち、ロック判定タスクが読み取る。
/// 参照を共有して書き込む器が必要なため、関数ではなく class にする。
@MainActor
final class AutoLockActivity {
    /// 無操作の起点時刻。タッチ・テキスト編集(macOS では NSEvent も)のたびに更新する。
    var lastActivityAt: Date = .now
}

struct RootPage: View {
    @AppStorage(.onboardingCompleted) var onboardingCompleted: Bool = false
    /// 進行途中でアプリを終了しても続きのステップから再開できるよう永続化する。
    @AppStorage(.onboardingStep) var onboardingStep: OnboardingStep = .welcome
    @AppStorage(.faceIDUnlockEnabled) var faceIDUnlockEnabled: Bool = true
    // README の「5秒タイプがなかったらロック」に合わせた既定値。
    @AppStorage(.autoLockSeconds) var autoLockSeconds: Int = 5
    // ThemePage と同じ既定(「生成」)。
    @AppStorage(.paperColorPresetIndex) var paperColorPresetIndex: Int = 1

    /// 配下へ environment で配る「今日」。フォアグラウンド復帰と日付変更のタイミングでのみ更新する。
    @State var today: Date = .now
    // 自動ロックの無操作起点。@State はインスタンスを View の生存期間で保持するためで、
    // 中身(lastActivityAt)の書き込みは再描画を起こさない(AutoLockActivity のコメント参照)。
    @State var autoLockActivity = AutoLockActivity()
    /// 自動ロック中かどうか。README の「開きっぱなしの端末を他人が触るのを防ぐ」UI ゲート。
    @State var locked: Bool = false
    /// Nikki Plus の加入状態。customerInfoStream の更新に追従し、environment で配下へ配る。
    @State var plusActive: Bool = false
    #if os(macOS)
    /// スクロール等の NSEvent を無操作起点のリセットにつなぐローカルモニター。onDisappear で解除するために保持する。
    @State var activityEventMonitor: Any?
    #endif

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if onboardingCompleted {
            ZStack {
                NavigationStack {
                    HomePage()
                }
                // ロック中は下の画面ごと無効化し、ハードウェアキーボードのショートカット(⌘N / ⌘F)が
                // ロックの裏で画面状態を変えないようにする。
                .disabled(locked)
                // 画面に触れている間はロックしないよう、配下へのあらゆるタッチを無操作起点のリセットとして拾う。
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0).onChanged { _ in registerActivity() }
                )

                if locked {
                    LockPage(locked: $locked)
                }
            }
            .environment(\.today, today)
            .environment(\.resetAutoLockTimer, registerActivity)
            .environment(\.plusActive, plusActive)
            // テーマで選んだ紙色を実画面の紙地に配る。Plus 失効中は無料範囲へ倒した色になる。
            .environment(\.paperColor, effectivePaperColor(storedIndex: paperColorPresetIndex, plusActive: plusActive))
            // 起動時キャッシュ→購入・復元・更新の順で customerInfo が流れてくるため、加入状態はこの1本で追従できる。
            .task {
                if !Purchases.isConfigured {
                    return
                }
                for await customerInfo in Purchases.shared.customerInfoStream {
                    plusActive = customerInfo.entitlements[Const.revenueCatPlusEntitlementID]?.isActive == true
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    today = .now
                }
            }
            // フォアグラウンドのまま日付をまたいだケースを日付変更通知で拾う。
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
                today = .now
            }
            // 無操作起点から設定秒数が経ったらロックする。バックグラウンドで中断された場合も、
            // 復帰時に期限超過ならそのまま発火してロックされる。
            // 計測をやり直す契機(初回表示・ロック解除・Face ID 設定/秒数/加入状態の変化)は
            // id の変化によるタスクの再起動として受け、無操作起点はタスクの起動時に引き直す。
            // 操作(registerActivity)は起点の書き込みだけで再描画もタスク再起動も起こさず、
            // 期限に目覚めたタスクが、起点が進んでいれば新しい期限まで眠り直す(issue #86)。
            .task(id: [locked, faceIDUnlockEnabled, autoLockSeconds, plusActive] as [AnyHashable]) {
                if locked || !faceIDUnlockEnabled {
                    return
                }
                #if DEBUG
                // E2E・AX 自動操作での動作確認が数秒の自動ロックに阻まれないよう、開発ビルドに限り環境変数で自動ロックを無効化できる。
                if ProcessInfo.processInfo.environment["NIKKI_AUTOLOCK_DISABLED"] != nil {
                    return
                }
                #endif
                autoLockActivity.lastActivityAt = .now
                while true {
                    // Plus 失効中はプリセット外のカスタム秒数を既定へ倒した実効値でロックする。
                    let deadline = autoLockActivity.lastActivityAt.addingTimeInterval(
                        Double(effectiveAutoLockSeconds(storedSeconds: autoLockSeconds, plusActive: plusActive))
                    )
                    if Date.now >= deadline {
                        locked = true
                        return
                    }
                    try? await Task.sleep(for: .seconds(deadline.timeIntervalSinceNow))
                    if Task.isCancelled {
                        return
                    }
                }
            }
            #if os(macOS)
            // macOS のスクロールホイール・トラックパッドのスクロールは SwiftUI のジェスチャに乗らず
            // simultaneousGesture の DragGesture では拾えないため、NSEvent のローカルモニターで
            // 操作イベントを無操作起点のリセットとして拾う。マウスをわずかに動かしただけでも発火する
            // mouseMoved は意図した操作といえないため対象に含めない。
            .onAppear {
                if activityEventMonitor != nil {
                    return
                }
                activityEventMonitor = NSEvent.addLocalMonitorForEvents(
                    matching: [.scrollWheel, .leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown, .magnify]
                ) { event in
                    registerActivity()
                    // nil を返すとイベントがアプリに届かなくなるため、そのまま流す。
                    return event
                }
            }
            .onDisappear {
                if let activityEventMonitor {
                    NSEvent.removeMonitor(activityEventMonitor)
                }
                activityEventMonitor = nil
            }
            #endif
        } else {
            switch onboardingStep {
            case .welcome:
                OnboardingWelcomePage(onboardingStep: $onboardingStep)
            case .encryption:
                OnboardingEncryptionPage(onboardingStep: $onboardingStep)
            case .biometric:
                OnboardingBiometricPage(onboardingCompleted: $onboardingCompleted)
            }
        }
    }

    /// 無操作起点を更新する。書き込み先が再描画を起こさない参照型のため、間引かず毎回更新する。
    private func registerActivity() {
        if locked {
            return
        }
        autoLockActivity.lastActivityAt = .now
    }
}
