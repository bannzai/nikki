import SwiftUI

/// アーカイブした日記が1件もないときの空状態。HomeEmptyState と同じトーンで控えめに知らせる。
struct ArchiveEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("No archived entries.")
                .font(.ink(15, .medium))
                .foregroundStyle(Color.inkTextSecondary)
            // アーカイブ操作の入口 (コンテキストメニュー) の開き方が OS で違うため、案内文言を分ける。
            #if os(macOS)
            Text("Right-click an entry on Home to tuck it away here.")
                .font(.ink(12.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
            #else
            Text("Press and hold an entry on Home to tuck it away here.")
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
