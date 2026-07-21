import SwiftUI

/// details ブロック。枠線カード + ▶ + summary。
struct EditorDetailsBlock: View {
    let summary: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: InkIcons.chevronRight)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(InkColors.textSecondary)
            Text("details — \(summary)")
                .font(InkTypography.font(14, .regular))
                .foregroundStyle(InkColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(InkColors.ink.opacity(0.12), lineWidth: 1)
        )
    }
}
