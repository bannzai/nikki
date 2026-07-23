import SwiftUI

/// オンボーディングの進行ステップ。完了したかどうかは RootPage の onboardingCompleted が持つ。
enum OnboardingStep {
    case welcome
    case encryption
    case biometric
}

struct RootPage: View {
    // AppStorage の key 名は変数名と一致させる。
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false

    /// 表示中のオンボーディングステップ。
    @State var step: OnboardingStep = .welcome

    var body: some View {
        if onboardingCompleted {
            NavigationStack {
                HomePage(today: .now)
            }
        } else {
            switch step {
            case .welcome:
                OnboardingWelcomePage(onStart: { step = .encryption })
            case .encryption:
                OnboardingEncryptionPage(onNext: { step = .biometric })
            case .biometric:
                // Face ID / パスキーの実登録は未実装のため、どちらのボタンもオンボーディング完了として扱う。
                OnboardingBiometricPage(
                    onEnableFaceID: { onboardingCompleted = true },
                    onRegisterPasskey: { onboardingCompleted = true }
                )
            }
        }
    }
}
