import SwiftUI

/// 日記がまだ1件もないときの空状態。紙の静けさを保つため、控えめな文言だけを中央に置く。
struct HomeEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("No entries yet.")
                .font(.ink(15, .medium))
                .foregroundStyle(Color.inkTextSecondary)
            Text("Start your first one with the pen at the bottom right.")
                .font(.ink(12.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HomeEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        HomeEmptyState()
            .background(Color.inkPaper)
    }
}
