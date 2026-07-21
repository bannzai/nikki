import SwiftUI

/// 変数1つ分の入力カード。{{name}} ラベルと入力フィールド(auto は固定表示 + 「自動」バッジ)。
struct TemplateVariableFieldCard: View {
    @Binding var field: TemplateVariableField
    /// シート全体で共有するフォーカス対象の変数名。
    var focusedFieldName: FocusState<String?>.Binding

    var body: some View {
        let isFocused = focusedFieldName.wrappedValue == field.name
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("{{\(field.name)}}")
                    .font(InkTypography.mono(11, weight: .semibold))
                    .foregroundStyle(InkColors.labelGray)
                if field.isAuto {
                    Spacer(minLength: 8)
                    Text("自動")
                        .font(InkTypography.mono(10.5))
                        .foregroundStyle(InkColors.textTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(InkColors.surfaceInset)
                        )
                }
            }
            if field.isAuto {
                Text(field.value)
                    .font(InkTypography.font(14.5, .regular))
                    .foregroundStyle(InkColors.ink)
            } else {
                TextField(
                    "",
                    text: $field.value,
                    prompt: Text(field.placeholder).foregroundStyle(InkColors.textQuaternary)
                )
                .font(InkTypography.font(14.5, .regular))
                .foregroundStyle(InkColors.ink)
                .tint(InkColors.ink)
                .focused(focusedFieldName, equals: field.name)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InkColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isFocused ? InkColors.ink : InkColors.border, lineWidth: isFocused ? 1.5 : 1)
        )
    }
}
