import SwiftUI

/// 一覧末尾の「＋ 新しいテンプレート」フッタ。
struct TemplateNewFooter: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: InkIcons.add)
                .font(.system(size: 14, weight: .regular))
            Text("新しいテンプレート")
                .font(.ink(13.5, .regular))
        }
        .foregroundStyle(Color.inkTextSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
