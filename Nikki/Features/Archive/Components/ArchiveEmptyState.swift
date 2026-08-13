import SwiftUI

/// アーカイブした日記が1件もないときの空状態。HomeEmptyState と同じトーンで控えめに知らせる。
struct ArchiveEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("アーカイブした日記はありません。")
                .font(.ink(15, .medium))
                .foregroundStyle(Color.inkTextSecondary)
            // アーカイブ操作の入口 (コンテキストメニュー) の開き方が OS で違うため、案内文言を分ける。
            #if os(macOS)
            Text("ホームの日記を右クリックすると、ここへしまえます。")
                .font(.ink(12.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
            #else
            Text("ホームの日記を長押しすると、ここへしまえます。")
                .font(.ink(12.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ArchiveEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        ArchiveEmptyState()
            .background(Color.inkPaper)
    }
}
