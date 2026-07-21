import SwiftUI

/// 変数入力のシートカード本体。ドラッグハンドル・見出し・変数フィールド群・
/// markdown プレビュー・開始ボタンを上端角丸24のカードに載せる。
struct TemplateVariableSheet: View {
    let template: JournalTemplate
    @Binding var fields: [TemplateVariableField]
    /// 「この内容ではじめる」をタップしたときに呼ばれる。
    var onStart: () -> Void = {}

    @FocusState private var focusedFieldName: String?

    var body: some View {
        let generatedMarkdown = TemplateVariableField.substitutedMarkdown(template: template, fields: fields)

        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0xD5D4CF))
                .frame(width: 38, height: 4.5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 18)

            Text("「\(template.name)」から作成")
                .font(InkTypography.font(17, .bold))
                .foregroundStyle(InkColors.ink)
                .padding(.bottom, 4)

            Text("埋めた言葉が、そのまま本文に入ります。")
                .font(InkTypography.font(12.5, .regular))
                .foregroundStyle(InkColors.textTertiary)
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                ForEach($fields) { $field in
                    TemplateVariableFieldCard(field: $field, focusedFieldName: $focusedFieldName)
                }
            }

            TemplateMarkdownPreview(markdown: generatedMarkdown)
                .padding(.top, 18)

            InkPrimaryButton("この内容ではじめる", action: onStart)
                .padding(.top, 18)
        }
        .padding(.top, 14)
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
            .fill(InkColors.paper)
            .shadow(color: InkColors.ink.opacity(0.18), radius: 20, x: 0, y: -12)
        )
    }
}
