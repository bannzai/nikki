import SwiftUI

/// テンプレート一覧(1l)。「今日はどの紙に書きますか。」の見出しの下に、
/// 各テンプレをカード(タイトル + シェブロン + markdown プレビュー)で並べる。
struct TemplateListView: View {
    let templates: [JournalTemplate]
    /// カードをタップしたときに呼ばれる。既定は no-op。
    var onSelect: (JournalTemplate) -> Void

    init(templates: [JournalTemplate] = SampleData.templates, onSelect: @escaping (JournalTemplate) -> Void = { _ in }) {
        self.templates = templates
        self.onSelect = onSelect
    }

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

                    newTemplateFooter
                }
                .padding(.horizontal, 24)
            }
        }
        .background(InkColors.paper.ignoresSafeArea())
    }

    private var newTemplateFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: InkIcons.add)
                .font(.system(size: 14, weight: .regular))
            Text("新しいテンプレート")
                .font(InkTypography.font(13.5, .regular))
        }
        .foregroundStyle(InkColors.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

/// テンプレート一覧(1l)の 1 枚分のカード。
private struct TemplateCard: View {
    let template: JournalTemplate
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(InkTypography.listItemTitle)
                    .foregroundStyle(InkColors.ink)
                Spacer(minLength: 8)
                Image(systemName: InkIcons.chevronRight)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(InkColors.textTertiary)
            }
            Text(template.markdown)
                .font(InkTypography.mono(11.5))
                .foregroundStyle(InkColors.textTertiary)
                .lineSpacing(InkTypography.lineSpacing(fontSize: 11.5, multiplier: 1.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .inkCard(cornerRadius: 14)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    TemplateListView(templates: SampleData.templates)
}
