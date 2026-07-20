import SwiftUI

/// サブスク訴求 / ペイウォール画面(1q「Nikki Plus」)。
/// 訴求軸はデバイス数・同期。料金プランはタップで選択を切り替える。
struct PaywallView: View {
    var onClose: () -> Void = {}
    var onPurchase: () -> Void = {}
    var onRestore: () -> Void = {}
    var onTerms: () -> Void = {}
    var onPrivacy: () -> Void = {}

    /// 見本(1q)では年プランを選択済みとして墨枠強調しているため、初期選択は年プラン。
    @State private var selectedPlan: PaywallPlan = .yearly

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton
                    .padding(.top, 6)
                    .padding(.bottom, 4)

                header
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                Text("どの端末でも、続きから書けるように。")
                    .font(InkTypography.font(15, .regular))
                    .foregroundStyle(PaywallView.headlineColor)
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 15, multiplier: 2.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 26)

                benefits
                    .padding(.bottom, 28)

                plans
                    .padding(.bottom, 20)

                Spacer(minLength: 24)

                footnote
                    .padding(.bottom, 14)

                InkPrimaryButton("Nikki Plus をはじめる", action: onPurchase)

                footerLinks
                    .padding(.top, 14)
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    /// 見本の見出し文字色(#52514E)。ink と textSecondary の中間で専用トークンがないため直接指定する。
    private static let headlineColor = Color(hex: 0x52514E)

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: InkIcons.close)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(InkColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("日")
                .font(InkTypography.font(18, .bold))
                .foregroundStyle(InkColors.ink)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(InkColors.ink, lineWidth: 2)
                )
            Text("Nikki Plus")
                .font(InkTypography.font(22, .bold))
                .tracking(0.44)
                .foregroundStyle(InkColors.ink)
            Spacer(minLength: 0)
        }
    }

    private var benefits: some View {
        VStack(spacing: 20) {
            PaywallBenefitRow(title: "複数端末で同期", description: "iPhone・Mac・Web。暗号化されたまま届きます。")
            PaywallBenefitRow(title: "テーマを増やす", description: "紙の色と背景画像を、もっと自由に。")
            PaywallBenefitRow(title: "テンプレート無制限", description: "自分の書き方を、いくつでも。")
        }
    }

    private var plans: some View {
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
    }

    private var footnote: some View {
        Text("同期中も、内容は暗号化されたままです。\nわたしたちが読めないことは、変わりません。")
            .font(InkTypography.font(11.5, .regular))
            .foregroundStyle(InkColors.textTertiary)
            .multilineTextAlignment(.center)
            .lineSpacing(InkTypography.lineSpacing(fontSize: 11.5, multiplier: 1.9))
            .frame(maxWidth: .infinity)
    }

    private var footerLinks: some View {
        HStack(spacing: 22) {
            PaywallFooterLink(title: "購入の復元", action: onRestore)
            PaywallFooterLink(title: "利用規約", action: onTerms)
            PaywallFooterLink(title: "プライバシー", action: onPrivacy)
        }
    }
}

/// ペイウォールの料金プラン種別。
private enum PaywallPlan {
    case monthly
    case yearly
}

/// 特典1件(チェック + タイトル + 説明)。
private struct PaywallBenefitRow: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: InkIcons.checkmark)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(InkColors.ink)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(InkTypography.font(14.5, .bold))
                    .foregroundStyle(InkColors.ink)
                Text(description)
                    .font(InkTypography.font(12.5, .regular))
                    .foregroundStyle(InkColors.textSecondary)
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 12.5, multiplier: 1.9))
            }
            Spacer(minLength: 0)
        }
    }
}

/// 料金プランカード。選択時は墨枠 + 白背景で強調する。
private struct PaywallPlanCard: View {
    let title: String
    let price: String
    let caption: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(InkTypography.font(12, .regular))
                .foregroundStyle(InkColors.textSecondary)
                .padding(.bottom, 6)
            Text(price)
                .font(InkTypography.font(20, .bold))
                .foregroundStyle(InkColors.ink)
            Text(caption)
                .font(InkTypography.font(11, .regular))
                .foregroundStyle(InkColors.textTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? InkColors.surface : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                // 未選択の淡い枠は見本の rgba(28,27,26,.2) を再現するため直接指定する。
                .strokeBorder(isSelected ? InkColors.ink : InkColors.ink.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .top) {
            if let badge {
                Text(badge)
                    .font(InkTypography.font(10, .medium))
                    .foregroundStyle(InkColors.primaryButtonText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(InkColors.ink)
                    )
                    .offset(y: -9)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}

/// フッタのテキストリンク(購入の復元 / 利用規約 / プライバシー)。
private struct PaywallFooterLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InkTypography.font(11.5, .regular))
                .foregroundStyle(InkColors.textTertiary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
