import SwiftUI

/// テキスト選択時のフローティングツールバー(本文 | H1 H2 H3 | ☑ リスト …)。
struct EditorSelectionToolbar: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("本文")
                .font(InkTypography.font(13.5, .regular))
                .foregroundStyle(EditorPalette.inkGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            EditorToolbarDivider()
            EditorToolbarHeadingLabel(title: "H1", active: false)
            EditorToolbarHeadingLabel(title: "H2", active: true)
            EditorToolbarHeadingLabel(title: "H3", active: false)
            EditorToolbarDivider()
            EditorToolbarIcon(systemName: "checkmark.square")
            EditorToolbarIcon(systemName: InkIcons.list)
            Text("…")
                .font(InkTypography.font(14, .regular))
                .tracking(1.4)
                .foregroundStyle(EditorPalette.inkGray)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InkColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(InkColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 13, x: 0, y: 8)
    }
}

/// ツールバー内の縦区切り線。
struct EditorToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(InkColors.ink.opacity(0.1))
            .frame(width: 1, height: 18)
    }
}

/// ツールバーの見出しレベルラベル。アクティブは墨地反転。
struct EditorToolbarHeadingLabel: View {
    let title: String
    let active: Bool

    var body: some View {
        Text(title)
            .font(InkTypography.mono(12.5, weight: .semibold))
            .foregroundStyle(active ? InkColors.primaryButtonText : EditorPalette.inkGray)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(InkColors.ink)
                }
            }
    }
}

/// ツールバーのアイコンボタン見た目。
struct EditorToolbarIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(EditorPalette.inkGray)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
    }
}
