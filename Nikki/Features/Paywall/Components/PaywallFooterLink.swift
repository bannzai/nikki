import SwiftUI

/// フッタのテキストリンク(購入の復元 / 利用規約 / プライバシー)。
struct PaywallFooterLink: View {
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
