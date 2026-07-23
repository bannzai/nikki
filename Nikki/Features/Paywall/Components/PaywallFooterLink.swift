import SwiftUI

/// フッタのテキストリンク(購入の復元 / 利用規約 / プライバシー)。
struct PaywallFooterLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ink(11.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .buttonStyle(.plain)
    }
}
