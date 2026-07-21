import SwiftUI

/// 「Face ID で開く」墨 pill ボタン。高さ50・横パディング26・角丸25。
struct LockFaceIDButton: View {
    /// タップ時のアクション。
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: InkIcons.faceID)
                    .font(.system(size: 18, weight: .regular))
                Text("Face ID で開く")
                    .font(InkTypography.font(15, .medium).weight(.semibold))
            }
            .foregroundStyle(InkColors.primaryButtonText)
            .frame(height: 50)
            .padding(.horizontal, 26)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(InkColors.ink)
            )
        }
        .buttonStyle(.plain)
    }
}
