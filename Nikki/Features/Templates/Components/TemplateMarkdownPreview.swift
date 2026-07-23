import SwiftUI

/// 生成後の markdown 本文プレビュー。くぼみ地に mono で表示する。
struct TemplateMarkdownPreview: View {
    let markdown: String

    var body: some View {
        Text(markdown)
            .font(.inkMono(11.5))
            .foregroundStyle(Color.inkLabelGray)
            .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.95))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.inkSurfaceInset)
            )
    }
}

struct TemplateMarkdownPreview_Previews: PreviewProvider {
    static var previews: some View {
        TemplateMarkdownPreview(markdown: "# 2026年7月18日\n天気: 晴れのち夕立\n## よかったこと\n## 明日のじぶんへ")
            .padding()
            .background(Color.inkPaper)
    }
}
