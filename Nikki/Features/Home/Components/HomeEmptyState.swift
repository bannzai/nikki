import SwiftUI

/// 日記がまだ1件もないときの空状態。紙の静けさを保つため、控えめな文言だけを中央に置く。
struct HomeEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("まだ日記はありません。")
                .font(.ink(15, .medium))
                .foregroundStyle(Color.inkTextSecondary)
            Text("最初の一枚は、右下のペンから。")
                .font(.ink(12.5, .regular))
                .foregroundStyle(Color.inkTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeEmptyState()
        .background(Color.inkPaper)
}
