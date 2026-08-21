import SwiftUI
import RevenueCat

/// サブスク訴求 / ペイウォール画面(1q「Nikki Plus」)。
/// 料金プランは offering `default` の packages から表示し、購入・復元は RevenueCat 経由で行う。
/// 特典の記載は現時点で実際に解放される機能(プレミアムテーマ)のみに絞る(同期・テンプレート等は各ゲートの実装時に追加する)。
struct PaywallPage: View {
    /// 見本(1q)では年プランを選択済みとして墨枠強調しているため、初期選択は年プラン。
    /// offering に年プランが無い場合は loadOffering() で購入可能なプランへ倒す。
    @State var selectedPlan: PaywallPlan = .yearly
    /// RevenueCat の current offering(`default`)。読み込み中・失敗・未 configure の間は nil。
    @State var offering: Offering?
    /// 買い切り済み・サブスク加入中の判定に使う顧客情報。読み込み中・未 configure の間は nil。
    @State var customerInfo: CustomerInfo?
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

                // 高さが足りない端末(iPhone SE・横画面等)でも購入ボタンと復元・規約リンクが
                // 画面外へ押し出されないよう、訴求と料金カードだけをスクロール領域にし、購入導線は下部に固定する。
                ScrollView {
                    VStack(spacing: 0) {
                        PaywallHeader()
                            .padding(.top, 10)
                            .padding(.bottom, 16)

                        Text("Make your journal look more like you.")
                            .font(.ink(15, .regular))
                            .foregroundStyle(PaywallPage.headlineColor)
                            .lineSpacing(inkLineSpacing(fontSize: 15, multiplier: 2.0))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 26)

                        PaywallBenefitRow(title: String(localized: "More themes"), description: String(localized: "Ash, Celadon, and Sakura. Unlock every paper color."))
                            .padding(.bottom, 28)

                        if lifetimePurchased {
                            Text("You own the lifetime purchase, so Nikki Plus stays active forever.")
                                .font(.ink(12.5, .regular))
                                .foregroundStyle(Color.inkTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            // offering に存在する package のカードだけを表示する。
                            // 未 configure(カタログ・プレビュー)は見本価格で全カードを表示する。
                            HStack(spacing: 12) {
                                if offering?.monthly != nil || !Purchases.isConfigured {
                                    PaywallPlanCard(
                                        title: String(localized: "Monthly"),
                                        price: planPrice(package: offering?.monthly, samplePrice: "¥300"),
                                        caption: String(localized: "/month"),
                                        badge: nil,
                                        isSelected: selectedPlan == .monthly,
                                        onTap: { selectedPlan = .monthly }
                                    )
                                }
                                if offering?.annual != nil || !Purchases.isConfigured {
                                    PaywallPlanCard(
                                        title: String(localized: "Yearly"),
                                        price: planPrice(package: offering?.annual, samplePrice: "¥3,000"),
                                        caption: annualPerMonthCaption(),
                                        badge: annualSavingsBadge(),
                                        isSelected: selectedPlan == .yearly,
                                        onTap: { selectedPlan = .yearly }
                                    )
                                }
                            }
                            .padding(.bottom, 12)

                            if offering?.lifetime != nil || !Purchases.isConfigured {
                                PaywallPlanCard(
                                    title: String(localized: "Lifetime"),
                                    price: planPrice(package: offering?.lifetime, samplePrice: "¥12,000"),
                                    caption: String(localized: "Pay once, keep forever"),
                                    badge: nil,
                                    isSelected: selectedPlan == .lifetime,
                                    onTap: { selectedPlan = .lifetime }
                                )

                                // 買い切りを購入しても既存の自動更新サブスクは解約されないため、加入中は明示して管理画面へ誘導する。
                                if subscriptionActive {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Buying the lifetime plan doesn't cancel your current subscription automatically. After purchasing, cancel it from your App Store subscription settings.")
                                            .foregroundStyle(Color.inkTextTertiary)
                                            .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                                        Button("Manage subscription") {
                                            openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                                        }
                                        .foregroundStyle(Color.ink)
                                    }
                                    .font(.ink(11.5, .regular))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 12)
                                }
                            }
                        }

                        if Purchases.isConfigured && offering == nil && !offeringLoadFailed {
                            ProgressView()
                                .padding(.top, 24)
                        }

                        if offeringLoadFailed {
                            HStack(spacing: 8) {
                                Text("Couldn't load prices.")
                                    .foregroundStyle(Color.inkTextTertiary)
                                Button("Retry") {
                                    Task {
                                        await loadOffering()
                                    }
                                }
                                .foregroundStyle(Color.ink)
                            }
                            .font(.ink(11.5, .regular))
                            .padding(.top, 12)
                        }
                    }
                }

                Button(purchasing ? "Processing…" : "Start Nikki Plus") {
                    Task {
                        await purchase()
                    }
                }
                .buttonStyle(InkPrimaryButtonStyle())
                .disabled(purchasing || selectedPackage == nil || lifetimePurchased)
                .padding(.top, 14)

                HStack(spacing: 22) {
                    PaywallFooterLink(title: String(localized: "Restore purchases")) {
                        Task {
                            await restore()
                        }
                    }
                    // 規約・プライバシーポリシーは言語ごとのページがあるため、URL も String Catalog で言語別に持つ。
                    PaywallFooterLink(title: String(localized: "Terms of Use")) {
                        openURL(URL(string: String(localized: "https://bannzai.github.io/nikki/legal/terms-en.html"))!)
                    }
                    PaywallFooterLink(title: String(localized: "Privacy")) {
                        openURL(URL(string: String(localized: "https://bannzai.github.io/nikki/legal/privacy-en.html"))!)
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

    /// 買い切り(非消耗型)を購入済みかどうか。本アプリの非消耗型商品は買い切り(nikki_plus_lifetime2)のみ。
    private var lifetimePurchased: Bool {
        customerInfo?.nonSubscriptions.isEmpty == false
    }

    /// 自動更新サブスクリプション(月額・年額)が有効かどうか。
    private var subscriptionActive: Bool {
        customerInfo?.activeSubscriptions.isEmpty == false
    }

    /// 選択中プランに対応する package。offering 未取得の間は nil。
    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly: return offering?.monthly
        case .yearly: return offering?.annual
        case .lifetime: return offering?.lifetime
        }
    }

    /// プラン価格の表示文字列。カードは package があるか未 configure の場合しか表示しないため、
    /// package が無いのは未 configure(カタログ・プレビュー)の見本表示だけになる。
    private func planPrice(package: Package?, samplePrice: String) -> String {
        package?.storeProduct.localizedPriceString ?? samplePrice
    }

    /// 年プランのキャプション。月あたり換算を実価格から出し、換算できない場合は期間表記に倒す。
    private func annualPerMonthCaption() -> String {
        if let storeProduct = offering?.annual?.storeProduct {
            if let pricePerMonth = storeProduct.pricePerMonth,
               let formatted = storeProduct.priceFormatter?.string(from: pricePerMonth) {
                return String(localized: "\(formatted)/month")
            }
            return String(localized: "/year")
        }
        // 未 configure(カタログ・プレビュー)の見本表示。
        return String(localized: "¥250/month")
    }

    /// 年プランの「◯ヶ月ぶんお得」バッジ。実価格から算出し、算出できない・得にならない場合は表示しない。
    private func annualSavingsBadge() -> String? {
        if let monthly = offering?.monthly, let annual = offering?.annual {
            if let months = annualSavingsMonths(monthlyPrice: monthly.storeProduct.price, annualPrice: annual.storeProduct.price) {
                return String(localized: "\(months) months free")
            }
            return nil
        }
        // 未 configure(カタログ・プレビュー)は見本価格(¥300/¥3,000)相当の2ヶ月で表示する。
        return Purchases.isConfigured ? nil : String(localized: "\(2) months free")
    }

    /// current offering(`default`)を取得する。未 configure(カタログ・プレビュー)では何もしない。
    private func loadOffering() async {
        if !Purchases.isConfigured {
            return
        }
        offeringLoadFailed = false
        // 買い切り済み・サブスク加入中の表示分岐に使う。取得失敗しても価格表示は続行できるため try? に留める。
        customerInfo = try? await Purchases.shared.customerInfo()
        do {
            offering = try await Purchases.shared.offerings().current
            if offering == nil {
                offeringLoadFailed = true
            }
            // 選択中プランの package が offering に無い場合、購入可能なプランへ選択を倒す。
            if selectedPackage == nil {
                if offering?.annual != nil {
                    selectedPlan = .yearly
                } else if offering?.monthly != nil {
                    selectedPlan = .monthly
                } else if offering?.lifetime != nil {
                    selectedPlan = .lifetime
                }
            }
        } catch {
            offeringLoadFailed = true
        }
    }

    /// 選択中の package を購入し、entitlement `plus` が有効になったら閉じる。
    /// 月額⇔年額の切り替えも同じ購入 API で行う(同一サブスクグループのため App Store 側でプラン変更として処理される)。
    private func purchase() async {
        // 多重タップや復元との並行実行を防ぐ。
        guard !purchasing, let selectedPackage else {
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
            } else {
                // 商品と entitlement の紐付け不備・反映遅延で、購入が成功しても plus が有効にならないケースを黙殺しない。
                paywallAlertMessage = String(localized: "The purchase went through, but the plan couldn't be confirmed yet. Please try “Restore purchases” in a little while.")
                paywallAlertIsPresented = true
            }
        } catch {
            paywallAlertMessage = String(localized: "The purchase couldn't be completed. \(error.localizedDescription)")
            paywallAlertIsPresented = true
        }
    }

    /// 過去の購入を復元し、entitlement `plus` が有効になったら閉じる。
    private func restore() async {
        // 未 configure(カタログ・プレビュー)で Purchases.shared に触れるとクラッシュするのを防ぎ、多重実行も防ぐ。
        guard Purchases.isConfigured, !purchasing else {
            return
        }
        purchasing = true
        defer {
            purchasing = false
        }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            if customerInfo.entitlements[Const.revenueCatPlusEntitlementID]?.isActive == true {
                dismiss()
            } else {
                paywallAlertMessage = String(localized: "No purchases to restore.")
                paywallAlertIsPresented = true
            }
        } catch {
            paywallAlertMessage = String(localized: "Purchases couldn't be restored. \(error.localizedDescription)")
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

/// 年額が月額の12ヶ月ぶんに対して何ヶ月ぶん安いかを返す(切り捨て)。
/// 1ヶ月未満の差しかない・割引がない・月額が不正な場合は nil(バッジを出さない)。
func annualSavingsMonths(monthlyPrice: Decimal, annualPrice: Decimal) -> Int? {
    if monthlyPrice <= 0 {
        return nil
    }
    let savedMonths = Int(NSDecimalNumber(decimal: (monthlyPrice * 12 - annualPrice) / monthlyPrice).doubleValue.rounded(.down))
    if savedMonths < 1 {
        return nil
    }
    return savedMonths
}

struct PaywallPage_Previews: PreviewProvider {
    static var previews: some View {
        PaywallPage()
    }
}
