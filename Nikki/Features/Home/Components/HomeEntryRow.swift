import SwiftUI

/// 時系列リストの1行。左に日付ブロック(日 + 曜日)、右にタイトルと2行抜粋。
struct HomeEntryRow: View {
    let entry: JournalEntry
    let showsSeparator: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 0) {
                    Text("\(Calendar.display.component(.day, from: entry.date))")
                        .font(.ink(21, .bold))
                        .foregroundStyle(Color.ink)
                    Text(weekdayLabel)
                        .font(.ink(11, .regular))
                        .foregroundStyle(Color.inkTextTertiary)
                }
                .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.inkListItemTitle)
                        .foregroundStyle(Color.ink)
                    Text(entry.excerpt)
                        .font(.ink(13))
                        .lineSpacing(inkLineSpacing(fontSize: 13, multiplier: 1.8))
                        .foregroundStyle(Color.inkTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)

            if showsSeparator {
                Rectangle()
                    .fill(Color.inkSeparator)
                    .frame(height: 0.5)
            }
        }
    }

    private var weekdayLabel: String {
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        return symbols[Calendar.display.component(.weekday, from: entry.date) - 1] + "曜"
    }
}
