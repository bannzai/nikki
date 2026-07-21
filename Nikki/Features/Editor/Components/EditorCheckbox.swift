import SwiftUI

/// チェックボックス。完了は墨地+白チェック、未完了は角丸枠。
struct EditorCheckbox: View {
    var done: Bool
    var size: CGFloat = 19

    var body: some View {
        if done {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(InkColors.ink)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: InkIcons.checkmark)
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(InkColors.primaryButtonText)
                }
        } else {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(InkColors.ink.opacity(0.35), lineWidth: 1.5)
                .frame(width: size, height: size)
        }
    }
}
