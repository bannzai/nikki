import SwiftUI

/// オンボーディング 1b: E2E 暗号化を「書く / 鍵をかける / 読めるのはあなただけ」の図解で説明する。
struct OnboardingEncryptionPage: View {
    /// オンボーディングの進行状態。「次へ」で次のステップへ進める。
    @Binding var onboardingStep: OnboardingStep

    /// 図解の 1 項目(円アイコン + タイトル + 説明)。
    private struct Point: Identifiable {
        let icon: String
        let title: String
        let description: String
        var id: String { title }
    }

    private let points: [Point] = [
        Point(icon: InkIcons.pen, title: String(localized: "Write"), description: String(localized: "Your entries live on this device first.")),
        Point(icon: InkIcons.lock, title: String(localized: "Lock it"), description: String(localized: "Encrypted on the device. The key never leaves it.")),
        Point(icon: InkIcons.search, title: String(localized: "Only you can read it"), description: String(localized: "All that reaches our servers is ciphertext no one can read.")),
    ]

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 1, total: 2)

                Text("A locked box\nthat's yours alone.")
                    .font(.ink(24, .bold))
                    .lineSpacing(inkLineSpacing(fontSize: 24, multiplier: 1.65))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                VStack(alignment: .leading, spacing: 26) {
                    ForEach(points) { point in
                        HStack(alignment: .top, spacing: 16) {
                            InkCircledIcon(systemName: point.icon)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(point.title)
                                    .font(.ink(15.5, .bold))
                                    .foregroundStyle(Color.ink)
                                Text(point.description)
                                    .font(.ink(13, .regular))
                                    .lineSpacing(inkLineSpacing(fontSize: 13, multiplier: 1.9))
                                    .foregroundStyle(Color.inkTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("No AI, no analytics, no sharing. Just a journal.")
                    .font(.ink(12, .regular))
                    .lineSpacing(inkLineSpacing(fontSize: 12, multiplier: 1.9))
                    .foregroundStyle(Color.inkTextTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                Button("Next") {
                    onboardingStep = .biometric
                }
                .buttonStyle(InkPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
    }
}

struct OnboardingEncryptionPage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingEncryptionPage(onboardingStep: .constant(.encryption))
    }
}
