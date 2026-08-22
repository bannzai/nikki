import SwiftUI

/// 一覧末尾の「＋ 新しいテンプレート」フッタ。タップで作成フォームへ進む。
struct NotebookNewFooter: View {
    let onTap: () -> Void

    var body: some View {
        // VoiceOver や AX 自動操作からも押せるよう、onTapGesture ではなく Button にする。
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: InkIcons.add)
                    .font(.system(size: 14, weight: .regular))
                Text("New template")
                    .font(.ink(13.5, .regular))
            }
            .foregroundStyle(Color.inkTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct NotebookNewFooter_Previews: PreviewProvider {
    static var previews: some View {
        NotebookNewFooter(onTap: {})
            .padding()
            .background(Color.inkPaper)
    }
}
