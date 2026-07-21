import SwiftUI

/// 時系列リストの1行。左に日付ブロック(日 + 曜日)、右にタイトルと2行抜粋。
struct HomeEntryRow: View {
    let entry: JournalEntry
    let showsSeparator: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 0) {
                    Text("\(SampleData.calendar.component(.day, from: entry.date))")
                        .font(InkTypography.font(21, .bold))
                        .foregroundStyle(InkColors.ink)
                    Text(weekdayLabel)
                        .font(InkTypography.font(11, .regular))
                        .foregroundStyle(InkColors.textTertiary)
                }
                .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(InkTypography.listItemTitle)
                        .foregroundStyle(InkColors.ink)
                    Text(entry.excerpt)
                        .inkTextStyle(InkTypography.excerpt)
                        .foregroundStyle(InkColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)

            if showsSeparator {
                Rectangle()
                    .fill(InkColors.separator)
                    .frame(height: 0.5)
            }
        }
    }

    private var weekdayLabel: String {
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        return symbols[SampleData.calendar.component(.weekday, from: entry.date) - 1] + "曜"
    }
}
