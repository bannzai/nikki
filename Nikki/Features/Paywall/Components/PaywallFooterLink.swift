import SwiftUI

/// フッタのテキストリンク(購入の復元 / 利用規約 / プライバシー)。
struct PaywallFooterLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(PaywallFooterLinkButtonStyle())
    }
}

/// フッタリンクの ButtonStyle。
private struct PaywallFooterLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ink(11.5))
            .foregroundStyle(Color.inkTextTertiary)
    }
}

struct PaywallFooterLink_Previews: PreviewProvider {
    static var previews: some View {
        PaywallFooterLink(title: "利用規約", action: {})
            .padding()
            .background(Color.inkPaper)
    }
}
