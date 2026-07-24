import SwiftUI

/// オンボーディングの進行ステップ。完了したかどうかは onboardingCompleted が持つ。
enum OnboardingStep: String {
    case welcome
    case encryption
    case biometric
}

struct RootPage: View {
    @AppStorage(.onboardingCompleted) var onboardingCompleted: Bool = false
    /// 進行途中でアプリを終了しても続きのステップから再開できるよう永続化する。
    @AppStorage(.onboardingStep) var onboardingStep: OnboardingStep = .welcome
    @AppStorage(.faceIDUnlockEnabled) var faceIDUnlockEnabled: Bool = true
    // README の「5秒タイプがなかったらロック」に合わせた既定値。
    @AppStorage(.autoLockSeconds) var autoLockSeconds: Int = 5

    /// 配下へ environment で配る「今日」。フォアグラウンド復帰と日付変更のタイミングでのみ更新する。
    @State var today: Date = .now
    /// 自動ロックの無操作起点。タッチとテキスト編集で更新する。
    @State var lastActivityAt: Date = .now
    /// 自動ロック中かどうか。README の「開きっぱなしの端末を他人が触るのを防ぐ」UI ゲート。
    @State var locked: Bool = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if onboardingCompleted {
            ZStack {
                NavigationStack {
                    HomePage()
                }
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
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    today = .now
                }
            }
            // フォアグラウンドのまま日付をまたいだケースを日付変更通知で拾う。
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
                today = .now
            }
            .onChange(of: locked) {
                // 解除直後から無操作の計測をやり直す。
                if !locked {
                    lastActivityAt = .now
                }
            }
            // 設定の変更でも無操作タイマーを引き直し、次の計測へ新しい値を反映する。
            .onChange(of: faceIDUnlockEnabled) {
                lastActivityAt = .now
            }
            .onChange(of: autoLockSeconds) {
                lastActivityAt = .now
            }
            // 無操作起点から設定秒数が経ったらロックする。バックグラウンドで中断された場合も、
            // 復帰時に期限超過ならそのまま発火してロックされる。
            .task(id: lastActivityAt) {
                if locked || !faceIDUnlockEnabled {
                    return
                }
                try? await Task.sleep(for: .seconds(autoLockSeconds))
                if Task.isCancelled {
                    return
                }
                locked = true
            }
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

    /// 無操作起点を更新する。スクロール等の連続タッチで再描画とタイマー引き直しが過剰にならないよう1秒単位に間引く。
    private func registerActivity() {
        if locked {
            return
        }
        if Date.now.timeIntervalSince(lastActivityAt) >= 1 {
            lastActivityAt = .now
        }
    }
}
