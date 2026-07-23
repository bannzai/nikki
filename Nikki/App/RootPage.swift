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

    var body: some View {
        if onboardingCompleted {
            NavigationStack {
                // アプリを開いたまま日付をまたいでも「今日」の表示が追従するよう、分刻みの時計から today を渡す。
                TimelineView(.everyMinute) { context in
                    HomePage(today: context.date)
                }
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
}
