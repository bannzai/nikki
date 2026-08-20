import SwiftUI

/// オンボーディング 1a: ようこそ画面。ロゴ + キャッチコピー + はじめる導線。
struct OnboardingWelcomePage: View {
    /// オンボーディングの進行状態。「はじめる」で次のステップへ進める。
    @Binding var onboardingStep: OnboardingStep

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                OnboardingLogoMark()
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    Text("What you write here,\nonly you can read.")
                        .font(.ink(25, .bold))
                        .lineSpacing(inkLineSpacing(fontSize: 25, multiplier: 1.7))
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Your journal is encrypted on this device. Not even we, the developers, can read it.")
                        .font(.ink(14.5, .regular))
                        .lineSpacing(inkLineSpacing(fontSize: 14.5, multiplier: 2.1))
                        .foregroundStyle(Color.inkTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                Button("Get started") {
                    onboardingStep = .encryption
                }
                .buttonStyle(InkPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
    }
}

struct OnboardingWelcomePage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingWelcomePage(onboardingStep: .constant(.welcome))
    }
}
