import SwiftUI

/// 右上の × クローズボタン行。
struct PaywallCloseButton: View {
    var body: some View {
        HStack {
            Spacer()
            // ペイウォールの表示導線が未配線のため、閉じる処理もまだ何もしない(https://github.com/bannzai/nikki/issues/14)。
            Button {} label: {
                Image(systemName: InkIcons.close)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct PaywallCloseButton_Previews: PreviewProvider {
    static var previews: some View {
        PaywallCloseButton()
            .padding()
            .background(Color.inkPaper)
    }
}
