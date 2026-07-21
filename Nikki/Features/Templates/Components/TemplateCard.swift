import SwiftUI

/// テンプレート一覧(1l)の 1 枚分のカード。
struct TemplateCard: View {
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
