import SwiftUI

/// 一覧末尾の「＋ 新しいノート」フッタ。
struct NotebookNewFooter: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: InkIcons.add)
                .font(.system(size: 14, weight: .regular))
            Text("新しいノート")
                .font(.ink(13.5, .regular))
        }
        .foregroundStyle(Color.inkTextSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct NotebookNewFooter_Previews: PreviewProvider {
    static var previews: some View {
        NotebookNewFooter()
            .padding()
            .background(Color.inkPaper)
    }
}
