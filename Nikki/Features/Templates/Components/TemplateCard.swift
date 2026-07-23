import SwiftUI

/// テンプレート一覧(1l)の 1 枚分のカード。
struct TemplateCard: View {
    let template: JournalTemplate
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.inkListItemTitle)
                    .foregroundStyle(Color.ink)
                Spacer(minLength: 8)
                Image(systemName: InkIcons.chevronRight)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            Text(template.markdown)
                .font(.inkMono(11.5))
                .foregroundStyle(Color.inkTextTertiary)
                .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
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
