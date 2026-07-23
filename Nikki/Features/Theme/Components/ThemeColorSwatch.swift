import SwiftUI

/// 紙色プリセット1つを表す丸スウォッチ + ラベル。選択中は墨枠とチェックを表示する。
struct ThemeColorSwatch: View {
    let paperColor: Color
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(paperColor)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: InkIcons.checkmark)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.ink)
                        }
                    }
                Text(label)
                    .font(.ink(11, isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.ink : Color.inkTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    /// 非選択時の枠色。白(プリセット先頭)は紙地に対して輪郭が沈むため、他色より濃い枠にする。
    private var borderColor: Color {
        if isSelected {
            return Color.ink
        }
        return paperColor == Color.paperColorPreset.first ? Color.black.opacity(0.12) : Color.inkBorder
    }
}
