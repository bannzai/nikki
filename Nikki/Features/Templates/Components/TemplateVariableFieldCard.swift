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
                    .font(.inkMono(11, weight: .semibold))
                    .foregroundStyle(Color.inkLabelGray)
                if field.isAuto {
                    Spacer(minLength: 8)
                    Text("Auto")
                        .font(.inkMono(10.5))
                        .foregroundStyle(Color.inkTextTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.inkSurfaceInset)
                        )
                }
            }
            if field.isAuto {
                Text(field.value)
                    .font(.ink(14.5, .regular))
                    .foregroundStyle(Color.ink)
            } else {
                TextField(
                    "",
                    text: $field.value,
                    prompt: Text(field.placeholder).foregroundStyle(Color.inkTextQuaternary)
                )
                .font(.ink(14.5, .regular))
                .foregroundStyle(Color.ink)
                .tint(Color.ink)
                .focused(focusedFieldName, equals: field.name)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isFocused ? Color.ink : Color.inkBorder, lineWidth: isFocused ? 1.5 : 1)
        )
    }
}

struct TemplateVariableFieldCard_Previews: PreviewProvider {
    /// @FocusState を preview に用意するためのラッパー。
    private struct Container: View {
        @State var field = TemplateVariableField(
            name: "weather",
            isAuto: false,
            value: "晴れのち夕立",
            bodyValue: nil,
            placeholder: "きょうの天気"
        )
        @FocusState var focusedFieldName: String?

        var body: some View {
            TemplateVariableFieldCard(field: $field, focusedFieldName: $focusedFieldName)
        }
    }

    static var previews: some View {
        Container()
            .padding()
            .background(Color.inkPaper)
    }
}
