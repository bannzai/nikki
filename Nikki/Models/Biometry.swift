import LocalAuthentication

/// 現在の端末で使える生体認証の種類を返す。ロック画面・オンボーディングの文言とアイコンの出し分けに使う。
/// biometryType は canEvaluatePolicy の評価後にのみ確定するため、評価してから返す。
func currentBiometryType() -> LABiometryType {
    let context = LAContext()
    // 生体認証が未登録でもパスコード / パスワードで解除できる実態に合わせ、解除と同じ .deviceOwnerAuthentication で評価する。
    _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    return context.biometryType
}
