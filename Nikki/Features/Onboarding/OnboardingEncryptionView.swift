import SwiftUI

/// オンボーディング 1b: E2E 暗号化を「書く / 鍵をかける / 読めるのはあなただけ」の図解で説明する。
struct OnboardingEncryptionView: View {
    var onNext: () -> Void = {}

    /// 図解の 1 項目(円アイコン + タイトル + 説明)。
    private struct Point: Identifiable {
        let icon: String
        let title: String
        let description: String
        var id: String { title }
    }

    private let points: [Point] = [
        Point(icon: InkIcons.pen, title: "書く", description: "日記は、まずこの端末の中に置かれます。"),
        Point(icon: InkIcons.lock, title: "鍵をかける", description: "端末の中で暗号化。鍵は端末の外に出ません。"),
        Point(icon: InkIcons.search, title: "読めるのは、あなただけ", description: "わたしたちのサーバーに届くのは、誰にも読めない暗号だけです。"),
    ]

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 1, total: 3)

                Text("鍵のかかった、\nあなただけの箱。")
                    .inkTextStyle(InkTypography.onboardingHeadline)
                    .foregroundStyle(InkColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                VStack(alignment: .leading, spacing: 26) {
                    ForEach(points) { point in
                        HStack(alignment: .top, spacing: 16) {
                            InkCircledIcon(systemName: point.icon)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(point.title)
                                    .font(InkTypography.font(15.5, .bold))
                                    .foregroundStyle(InkColors.ink)
                                Text(point.description)
                                    .font(InkTypography.font(13, .regular))
                                    .lineSpacing(InkTypography.lineSpacing(fontSize: 13, multiplier: 1.9))
                                    .foregroundStyle(InkColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("AI も、解析も、共有もありません。ただの日記帳です。")
                    .font(InkTypography.font(12, .regular))
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 12, multiplier: 1.9))
                    .foregroundStyle(InkColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                InkPrimaryButton("次へ", action: onNext)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    OnboardingEncryptionView()
}
