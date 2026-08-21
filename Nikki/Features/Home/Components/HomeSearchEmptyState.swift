import SwiftUI

/// 検索に一致する日記が1件もないときの空状態。HomeEmptyState と同じトーンで控えめに知らせる。
struct HomeSearchEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Nothing found.")
                .font(.ink(15, .medium))
                .foregroundStyle(Color.inkTextSecondary)
            Text("Try searching with different words.")
                .font(.ink(12.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HomeSearchEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        HomeSearchEmptyState()
            .background(Color.inkPaper)
    }
}
