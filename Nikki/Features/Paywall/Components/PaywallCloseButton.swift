import SwiftUI

/// 右上の × クローズボタン行。ペイウォールのシートを閉じる。
struct PaywallCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
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
