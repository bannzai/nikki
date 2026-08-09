import SwiftUI
import RevenueCat

/// サブスク訴求 / ペイウォール画面(1q「Nikki Plus」)。
/// 訴求軸はデバイス数・同期。料金プランは offering `default` の packages から表示し、購入・復元は RevenueCat 経由で行う。
struct PaywallPage: View {
    /// 見本(1q)では年プランを選択済みとして墨枠強調しているため、初期選択は年プラン。
    @State var selectedPlan: PaywallPlan = .yearly
    /// RevenueCat の current offering(`default`)。読み込み中・失敗・未 configure の間は nil。
    @State var offering: Offering?
    /// offering の取得に失敗したかどうか。再読み込みの導線を出す。
    @State var offeringLoadFailed = false
    /// 購入・復元の処理中かどうか。二重実行を防ぎ、ボタンを無効化する。
    @State var purchasing = false
    @State var paywallAlertIsPresented = false
    /// 購入・復元の失敗をユーザーへ伝えるメッセージ。paywallAlertIsPresented とセットで更新する。
    @State var paywallAlertMessage = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

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
                        price: planPrice(package: offering?.monthly, samplePrice: "¥300"),
                        caption: "/月",
                        badge: nil,
                        isSelected: selectedPlan == .monthly,
                        onTap: { selectedPlan = .monthly }
                    )
                    PaywallPlanCard(
                        title: "年ごと",
                        price: planPrice(package: offering?.annual, samplePrice: "¥3,000"),
                        caption: annualPerMonthCaption(),
                        badge: "2ヶ月ぶんお得",
                        isSelected: selectedPlan == .yearly,
                        onTap: { selectedPlan = .yearly }
                    )
                }
                .padding(.bottom, 12)

                PaywallPlanCard(
                    title: "買い切り",
                    price: planPrice(package: offering?.lifetime, samplePrice: "¥12,000"),
                    caption: "一度の購入で、ずっと",
                    badge: nil,
                    isSelected: selectedPlan == .lifetime,
                    onTap: { selectedPlan = .lifetime }
                )
                .padding(.bottom, 20)

                if offeringLoadFailed {
                    HStack(spacing: 8) {
                        Text("価格を読み込めませんでした。")
                            .foregroundStyle(Color.inkTextTertiary)
                        Button("再読み込み") {
                            Task {
                                await loadOffering()
                            }
                        }
                        .foregroundStyle(Color.ink)
                    }
                    .font(.ink(11.5, .regular))
                }

                Spacer(minLength: 24)

                Text("同期中も、内容は暗号化されたままです。\nわたしたちが読めないことは、変わりません。")
                    .font(.ink(11.5, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 14)

                Button(purchasing ? "処理中…" : "Nikki Plus をはじめる") {
                    Task {
                        await purchase()
                    }
                }
                .buttonStyle(InkPrimaryButtonStyle())
                .disabled(purchasing || selectedPackage == nil)

                HStack(spacing: 22) {
                    PaywallFooterLink(title: "購入の復元") {
                        Task {
                            await restore()
                        }
                    }
                    PaywallFooterLink(title: "利用規約") {
                        openURL(URL(string: "https://bannzai.github.io/nikki/legal/terms-ja.html")!)
                    }
                    PaywallFooterLink(title: "プライバシー") {
                        openURL(URL(string: "https://bannzai.github.io/nikki/legal/privacy-ja.html")!)
                    }
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .task {
            await loadOffering()
        }
        .alert(paywallAlertMessage, isPresented: $paywallAlertIsPresented) {
            Button("OK") {}
        }
    }

    /// 選択中プランに対応する package。offering 未取得の間は nil。
    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly: return offering?.monthly
        case .yearly: return offering?.annual
        case .lifetime: return offering?.lifetime
        }
    }

    /// プラン価格の表示文字列。取得済みならストア価格、未 configure(カタログ・プレビュー)は見本価格、取得前・失敗時はプレースホルダ。
    private func planPrice(package: Package?, samplePrice: String) -> String {
        if let package {
            return package.storeProduct.localizedPriceString
        }
        return Purchases.isConfigured ? "—" : samplePrice
    }

    /// 年プランの月あたり換算のキャプション。換算できない間は期間表記に倒す。
    private func annualPerMonthCaption() -> String {
        if let storeProduct = offering?.annual?.storeProduct,
           let pricePerMonth = storeProduct.pricePerMonth,
           let formatted = storeProduct.priceFormatter?.string(from: pricePerMonth) {
            return "\(formatted)/月"
        }
        return Purchases.isConfigured ? "/年" : "¥250/月"
    }

    /// current offering(`default`)を取得する。未 configure(カタログ・プレビュー)では何もしない。
    private func loadOffering() async {
        if !Purchases.isConfigured {
            return
        }
        offeringLoadFailed = false
        do {
            offering = try await Purchases.shared.offerings().current
            if offering == nil {
                offeringLoadFailed = true
            }
        } catch {
            offeringLoadFailed = true
        }
    }

    /// 選択中の package を購入し、entitlement `plus` が有効になったら閉じる。
    /// 月額⇔年額の切り替えも同じ購入 API で行う(同一サブスクグループのため App Store 側でプラン変更として処理される)。
    private func purchase() async {
        guard let selectedPackage else {
            return
        }
        purchasing = true
        defer {
            purchasing = false
        }
        do {
            let result = try await Purchases.shared.purchase(package: selectedPackage)
            // キャンセルはユーザー操作の範囲なので何もしない。
            if result.userCancelled {
                return
            }
            if result.customerInfo.entitlements[Const.revenueCatPlusEntitlementID]?.isActive == true {
                dismiss()
            }
        } catch {
            paywallAlertMessage = "購入を完了できませんでした。\(error.localizedDescription)"
            paywallAlertIsPresented = true
        }
    }

    /// 過去の購入を復元し、entitlement `plus` が有効になったら閉じる。
    private func restore() async {
        purchasing = true
        defer {
            purchasing = false
        }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            if customerInfo.entitlements[Const.revenueCatPlusEntitlementID]?.isActive == true {
                dismiss()
            } else {
                paywallAlertMessage = "復元できる購入が見つかりませんでした。"
                paywallAlertIsPresented = true
            }
        } catch {
            paywallAlertMessage = "購入を復元できませんでした。\(error.localizedDescription)"
            paywallAlertIsPresented = true
        }
    }
}

/// ペイウォールの料金プラン種別。
enum PaywallPlan {
    case monthly
    case yearly
    case lifetime
}

struct PaywallPage_Previews: PreviewProvider {
    static var previews: some View {
        PaywallPage()
    }
}
