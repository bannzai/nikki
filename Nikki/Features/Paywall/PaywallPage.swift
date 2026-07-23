import SwiftUI

/// サブスク訴求 / ペイウォール画面(1q「Nikki Plus」)。
/// 訴求軸はデバイス数・同期。料金プランはタップで選択を切り替える。
struct PaywallPage: View {
    /// 見本(1q)では年プランを選択済みとして墨枠強調しているため、初期選択は年プラン。
    // PaywallPlan がファイル内 private 型のため、@State も private のままにする(@State を非 private にする規約から逸脱)。
    @State private var selectedPlan: PaywallPlan = .yearly

    /// 見本の見出し文字色(#52514E)。ink と textSecondary の中間で専用トークンがないため直接指定する。
    private static let headlineColor = Color(hex: 0x52514E)

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                PaywallCloseButton()
                    .padding(.top, 6)
                    .padding(.bottom, 4)

                PaywallHeader()
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                Text("どの端末でも、続きから書けるように。")
                    .font(.ink(15, .regular))
                    .foregroundStyle(PaywallPage.headlineColor)
                    .lineSpacing(inkLineSpacing(fontSize: 15, multiplier: 2.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 26)

                VStack(spacing: 20) {
                    PaywallBenefitRow(title: "複数端末で同期", description: "iPhone・Mac・Web。暗号化されたまま届きます。")
                    PaywallBenefitRow(title: "テーマを増やす", description: "紙の色と背景画像を、もっと自由に。")
                    PaywallBenefitRow(title: "テンプレート無制限", description: "自分の書き方を、いくつでも。")
                }
                .padding(.bottom, 28)

                HStack(spacing: 12) {
                    PaywallPlanCard(
                        title: "月ごと",
                        price: "¥300",
                        caption: "/月",
                        badge: nil,
                        isSelected: selectedPlan == .monthly,
                        onTap: { selectedPlan = .monthly }
                    )
                    PaywallPlanCard(
                        title: "年ごと",
                        price: "¥3,000",
                        caption: "¥250/月",
                        badge: "2ヶ月ぶんお得",
                        isSelected: selectedPlan == .yearly,
                        onTap: { selectedPlan = .yearly }
                    )
                }
                .padding(.bottom, 20)

                Spacer(minLength: 24)

                Text("同期中も、内容は暗号化されたままです。\nわたしたちが読めないことは、変わりません。")
                    .font(.ink(11.5, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 14)

                Button("Nikki Plus をはじめる") {}
                    .buttonStyle(InkPrimaryButtonStyle())

                HStack(spacing: 22) {
                    PaywallFooterLink(title: "購入の復元")
                    PaywallFooterLink(title: "利用規約")
                    PaywallFooterLink(title: "プライバシー")
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }
}

/// ペイウォールの料金プラン種別。
private enum PaywallPlan {
    case monthly
    case yearly
}

struct PaywallPage_Previews: PreviewProvider {
    static var previews: some View {
        PaywallPage()
    }
}
