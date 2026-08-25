import SwiftUI

/// 一覧末尾の「＋ 新しいテンプレート」フッタ。タップで作成フォームへ進む。
/// 無料枠の上限に達している(#94)ときはロック表示にし、タップの扱いは呼び出し元の onTap に委ねる
/// (呼び出し元がロック中は PaywallPage を開き、そうでなければ作成フォームへ遷移する)。
struct NotebookNewFooter: View {
    let locked: Bool
    let onTap: () -> Void

    var body: some View {
        // VoiceOver や AX 自動操作からも押せるよう、onTapGesture ではなく Button にする。
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: locked ? InkIcons.lock : InkIcons.add)
                    .font(.system(size: locked ? 13 : 14, weight: locked ? .semibold : .regular))
                Text(locked ? String(localized: "Nikki Plus required") : String(localized: "New template"))
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
        VStack {
            NotebookNewFooter(locked: false, onTap: {})
            NotebookNewFooter(locked: true, onTap: {})
        }
        .padding()
        .background(Color.inkPaper)
    }
}
