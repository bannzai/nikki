import SwiftUI

/// 時系列リスト選択状態のホーム(1g)。共通シャーシ HomeView をリストモードで起動する薄いラッパ。
struct EntryListView: View {
    let entries: [JournalEntry]
    let today: Date

    init(entries: [JournalEntry] = SampleData.entries, today: Date = SampleData.referenceToday) {
        self.entries = entries
        self.today = today
    }

    var body: some View {
        HomeView(entries: entries, today: today, initialMode: .list)
    }
}

/// 時系列リスト本体。日記を月ごとにまとめ、日付ブロック + タイトル + 2行抜粋の行を並べる。
struct HomeListBody: View {
    let entries: [JournalEntry]

    private var monthGroups: [HomeMonthGroup] {
        HomeMonthGroup.grouped(from: entries)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(monthGroups.enumerated()), id: \.element.id) { groupIndex, group in
                    Text(group.title)
                        .font(InkTypography.font(12, .bold).weight(.semibold))
                        .foregroundStyle(InkColors.textTertiary)
                        .padding(.top, groupIndex == 0 ? 14 : 16)
                        .padding(.bottom, 4)

                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { rowIndex, entry in
                        HomeEntryRow(
                            entry: entry,
                            showsSeparator: !(groupIndex == monthGroups.count - 1
                                && rowIndex == group.entries.count - 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
    }
}

/// 時系列リストで同じ年月の日記をまとめた表示単位。
struct HomeMonthGroup: Identifiable {
    let year: Int
    let month: Int
    var entries: [JournalEntry]

    /// 年月の一意キー。ForEach の identity に使う。
    var id: Int { year * 100 + month }

    /// 「2026年7月」形式の月見出し。
    var title: String { "\(year)年\(month)月" }

    /// 日記を新しい月・日が先頭に来るよう降順に並べ、年月ごとにまとめる。
    static func grouped(from entries: [JournalEntry]) -> [HomeMonthGroup] {
        var groups: [HomeMonthGroup] = []
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let comps = SampleData.calendar.dateComponents([.year, .month], from: entry.date)
            let year = comps.year ?? 0
            let month = comps.month ?? 0
            if var last = groups.last, last.year == year, last.month == month {
                last.entries.append(entry)
                groups[groups.count - 1] = last
            } else {
                groups.append(HomeMonthGroup(year: year, month: month, entries: [entry]))
            }
        }
        return groups
    }
}

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
