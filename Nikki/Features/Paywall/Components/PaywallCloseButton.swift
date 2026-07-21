import SwiftUI

/// 右上の × クローズボタン行。
struct PaywallCloseButton: View {
    /// タップ時のアクション。
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: InkIcons.close)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(InkColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }
}
