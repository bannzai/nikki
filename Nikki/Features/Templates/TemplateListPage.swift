import SwiftUI

/// テンプレート一覧(1l)。「今日はどの紙に書きますか。」の見出しの下に、
/// 各テンプレをカード(タイトル + シェブロン + markdown プレビュー)で並べる。
struct TemplateListPage: View {
    var templates: [JournalTemplate] = SampleData.templates
    /// カードをタップしたときに呼ばれる。既定は no-op。
    var onSelect: (JournalTemplate) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title("テンプレート"))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("今日はどの紙に書きますか。")
                        .font(InkTypography.font(12.5, .regular))
                        .foregroundStyle(InkColors.textSecondary)
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 12.5, multiplier: 1.9))
                        .padding(.bottom, 16)

                    VStack(spacing: 12) {
                        ForEach(templates) { template in
                            TemplateCard(template: template) { onSelect(template) }
                        }
                    }

                    TemplateNewFooter()
                }
                .padding(.horizontal, 24)
            }
        }
        .background(InkColors.paper.ignoresSafeArea())
    }
}

#Preview {
    TemplateListPage(templates: SampleData.templates)
}
