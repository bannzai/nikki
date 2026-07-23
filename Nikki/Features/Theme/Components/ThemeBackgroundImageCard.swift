import SwiftUI

/// 背景画像の選択リスト。「写真から選ぶ」(no-op)と現在選択中の「なし」。
struct ThemeBackgroundImageCard: View {
    var body: some View {
        InkListSection {
            InkListRow(title: "写真から選ぶ", action: {})
            HStack(spacing: 8) {
                Text("なし")
                    .font(.ink(14.5, .regular))
                    .foregroundStyle(Color.inkTextSecondary)
                Spacer(minLength: 8)
                Image(systemName: InkIcons.checkmark)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
    }
}

struct ThemeBackgroundImageCard_Previews: PreviewProvider {
    static var previews: some View {
        ThemeBackgroundImageCard()
            .padding()
            .background(Color.inkPaper)
    }
}
