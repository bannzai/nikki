import SwiftUI

/// カレンダーの曜日ヘッダ(日〜土)。
struct HomeCalendarWeekdayHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { symbol in
                Text(symbol)
                    .font(.ink(11, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
    }
}
