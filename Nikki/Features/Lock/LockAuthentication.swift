import LocalAuthentication

/// 評価中のロック解除認証のコンテキスト。ウィンドウの非表示時に認証ダイアログを閉じる(invalidate)ために保持する。
/// 認証ダイアログは同時に1つしか出ないため、モジュールで1つだけ持てば足りる。
@MainActor private var unlockAuthenticationContext: LAContext?

/// ロック解除の認証を評価できる(パスコード / パスワード等の認証手段が設定されている)かを返す。
/// 解除と同じ .deviceOwnerAuthentication で評価する。
func canEvaluateUnlockAuthentication() -> Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
}

/// 生体認証(Touch ID / Face ID)だけでロック解除の認証を評価できる(搭載かつ登録済み)かを返す。
/// パスワードしか使えない環境を自動提示の対象から外すため、フォールバック込みの .deviceOwnerAuthentication ではなく
/// 生体認証限定のポリシーで評価する。
func canEvaluateBiometricsUnlockAuthentication() -> Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
}

/// ロック解除の認証を評価し、解除に成功したかを返す。キャンセル・失敗時は false を返す。
/// 生体認証が未登録・失敗した場合でもパスコード / パスワードで解除できるよう .deviceOwnerAuthentication を使う。
@MainActor
func evaluateUnlockAuthentication() async -> Bool {
    let context = LAContext()
    unlockAuthenticationContext = context
    defer {
        // 評価中にキャンセル→再提示が起きた場合、古い評価の後始末が新しいコンテキストを消さないよう同一性を確認する。
        if unlockAuthenticationContext === context {
            unlockAuthenticationContext = nil
        }
    }
    return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: String(localized: "Unlock your journal"))) == true
}

/// 評価中のロック解除認証を中断し、表示中の認証ダイアログを閉じる。評価中でなければ何もしない(冪等)。
@MainActor
func cancelUnlockAuthentication() {
    unlockAuthenticationContext?.invalidate()
    unlockAuthenticationContext = nil
}
