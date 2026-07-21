import SwiftUI

/// 紙色プリセット1つを表す丸スウォッチ + ラベル。選択中は墨枠とチェックを表示する。
struct ThemeColorSwatch: View {
    let preset: PaperColorPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(preset.color)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: InkIcons.checkmark)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(InkColors.ink)
                        }
                    }
                Text(label)
                    .font(InkTypography.font(11, isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? InkColors.ink : InkColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    /// スウォッチ下に表示する紙色プリセットの表示名。
    private var label: String {
        switch preset {
        case .white: return "白"
        case .ecru: return "生成"
        case .ash: return "薄鼠"
        case .celadon: return "青磁"
        case .sakura: return "桜鼠"
        }
    }

    /// 非選択時の枠色。白は紙地(#FAFAF9)に対して輪郭が沈むため、他色(0.08)より濃い 0.12 の枠にする。
    private var borderColor: Color {
        if isSelected { return InkColors.ink }
        return preset == .white ? Color.black.opacity(0.12) : InkColors.border
    }
}
