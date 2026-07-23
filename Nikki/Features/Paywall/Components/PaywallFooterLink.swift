import SwiftUI

/// フッタのテキストリンク(購入の復元 / 利用規約 / プライバシー)。
struct PaywallFooterLink: View {
    let title: String

    var body: some View {
        // 課金導線は未実装のため、ボタンはまだ何もしない(https://github.com/bannzai/nikki/issues/14)。
        Button(title) {}
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
        PaywallFooterLink(title: "利用規約")
            .padding()
            .background(Color.inkPaper)
    }
}
