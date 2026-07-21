import SwiftUI

/// カレンダー選択状態のホーム(1h)。共通シャーシ HomeView をカレンダーモードで起動する薄いラッパ。
struct CalendarMonthView: View {
    let entries: [JournalEntry]
    let today: Date

    init(entries: [JournalEntry] = SampleData.entries, today: Date = SampleData.referenceToday) {
        self.entries = entries
        self.today = today
    }

    var body: some View {
        HomeView(entries: entries, today: today, initialMode: .calendar)
    }
}

/// カレンダー本体。月送り・曜日ヘッダ・日グリッド(日記の墨ドット / today の墨円)と today の日記プレビューを表示する。
struct HomeCalendarBody: View {
    let entries: [JournalEntry]
    let today: Date

    /// 表示中の月(1日 00:00)。‹ › で前後の月に移動する。@State の初期値を today から決めるため custom init を用いる。
    @State var displayedMonth: Date

    init(entries: [JournalEntry], today: Date) {
        self.entries = entries
        self.today = today
        self._displayedMonth = State(initialValue: HomeCalendarBody.startOfMonth(for: today))
    }

    private var calendar: Calendar { SampleData.calendar }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            monthNav
            weekdayHeader
            daysGrid
            if let entry = todayEntry {
                previewCard(entry)
                    .padding(.top, 14)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    // MARK: - Sections

    private var monthNav: some View {
        HStack(spacing: 0) {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: InkIcons.chevronLeft)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(InkColors.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text(monthTitle)
                .font(InkTypography.font(15, .bold))
                .foregroundStyle(InkColors.ink)

            Spacer(minLength: 0)

            Button { shiftMonth(by: 1) } label: {
                Image(systemName: InkIcons.chevronRight)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(InkColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 14)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { symbol in
                Text(symbol)
                    .font(InkTypography.font(11, .regular))
                    .foregroundStyle(InkColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
    }

    private var daysGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 6
        ) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, cell in
                cellView(cell)
            }
        }
    }

    private func cellView(_ cell: HomeCalendarDay) -> some View {
        VStack(spacing: 0) {
            if let day = cell.day {
                if cell.isToday {
                    Text("\(day)")
                        .font(InkTypography.font(14, .bold))
                        .foregroundStyle(InkColors.primaryButtonText)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(InkColors.ink))
                        .padding(.top, 2)
                    Spacer(minLength: 0)
                } else {
                    Text("\(day)")
                        .font(InkTypography.font(14, .regular))
                        .foregroundStyle(cell.isFuture ? InkColors.textQuaternary : InkColors.ink)
                        .padding(.top, 8)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(cell.hasEntry ? InkColors.ink : Color.clear)
                        .frame(width: 4, height: 4)
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38, alignment: .top)
    }

    private func previewCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(previewDateLabel(entry.date))
                    .font(InkTypography.font(13, .bold))
                    .foregroundStyle(InkColors.ink)
                Text(timeLabel(entry.createdAt))
                    .font(InkTypography.font(11, .regular))
                    .foregroundStyle(InkColors.textTertiary)
            }
            .padding(.bottom, 6)

            Text(entry.title)
                .font(InkTypography.font(14.5, .bold))
                .foregroundStyle(InkColors.ink)
                .padding(.bottom, 3)

            Text(entry.excerpt)
                .inkTextStyle(InkTextStyle(
                    font: InkTypography.font(12.5, .regular),
                    lineSpacing: InkTypography.lineSpacing(fontSize: 12.5, multiplier: 1.8)
                ))
                .foregroundStyle(InkColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .inkCard(cornerRadius: 14)
    }

    // MARK: - Derived data

    /// today と同じ日の日記。プレビューカードに表示する。
    private var todayEntry: JournalEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: today) }
    }

    private var monthTitle: String {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        return "\(comps.year ?? 0)年\(comps.month ?? 0)月"
    }

    /// 表示中の月のグリッドに並べるセル。先頭に月初めまでの空白セルを含む。
    private var gridDays: [HomeCalendarDay] {
        let firstOfMonth = HomeCalendarBody.startOfMonth(for: displayedMonth)
        let leadingBlanks = calendar.component(.weekday, from: firstOfMonth) - 1
        let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<1
        let todayStart = calendar.startOfDay(for: today)

        var cells = Array(
            repeating: HomeCalendarDay(day: nil, isToday: false, isFuture: false, hasEntry: false),
            count: leadingBlanks
        )
        for day in dayRange {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? firstOfMonth
            cells.append(HomeCalendarDay(
                day: day,
                isToday: calendar.isDate(date, inSameDayAs: today),
                isFuture: calendar.startOfDay(for: date) > todayStart,
                hasEntry: entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
            ))
        }
        return cells
    }

    // MARK: - Helpers

    private func shiftMonth(by delta: Int) {
        if let shifted = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = HomeCalendarBody.startOfMonth(for: shifted)
        }
    }

    private func previewDateLabel(_ date: Date) -> String {
        let comps = calendar.dateComponents([.month, .day, .weekday], from: date)
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        return "\(comps.month ?? 0)月\(comps.day ?? 0)日 \(symbols[(comps.weekday ?? 1) - 1])曜日"
    }

    private func timeLabel(_ date: Date) -> String {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }

    /// 指定日を含む月の1日 00:00 を返す。
    private static func startOfMonth(for date: Date) -> Date {
        let calendar = SampleData.calendar
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

/// カレンダーグリッドの1セル。day が nil のセルは月初めまでの空白。
struct HomeCalendarDay {
    /// 日付の数値。nil のとき空白セル。
    let day: Int?
    /// today と同じ日か(墨円で反転表示する)。
    let isToday: Bool
    /// today より未来の日か(微色で表示する)。
    let isFuture: Bool
    /// その日に日記があるか(墨ドットを表示する)。
    let hasEntry: Bool
}
