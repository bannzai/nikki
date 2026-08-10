import LocalAuthentication

/// ロック解除の認証を評価できる(パスコード / パスワード等の認証手段が設定されている)かを返す。
/// 解除と同じ .deviceOwnerAuthentication で評価する。
func canEvaluateUnlockAuthentication() -> Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
}

/// ロック解除の認証を評価し、解除に成功したかを返す。キャンセル・失敗時は false を返す。
/// 生体認証が未登録・失敗した場合でもパスコード / パスワードで解除できるよう .deviceOwnerAuthentication を使う。
func evaluateUnlockAuthentication() async -> Bool {
    (try? await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "日記のロックを解除します")) == true
}
