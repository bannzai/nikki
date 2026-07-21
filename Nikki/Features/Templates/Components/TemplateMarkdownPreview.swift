import SwiftUI

/// 生成後の markdown 本文プレビュー。くぼみ地に mono で表示する。
struct TemplateMarkdownPreview: View {
    let markdown: String

    var body: some View {
        Text(markdown)
            .font(InkTypography.mono(11.5))
            .foregroundStyle(InkColors.labelGray)
            .lineSpacing(InkTypography.lineSpacing(fontSize: 11.5, multiplier: 1.95))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(InkColors.surfaceInset)
            )
    }
}
