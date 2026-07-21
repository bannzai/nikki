import SwiftUI

/// カレンダーの日グリッド。先頭に月初めまでの空白セルを置き、7列で日セルを並べる。
struct HomeCalendarDaysGrid: View {
    let entries: [JournalEntry]
    let today: Date
    let displayedMonth: Date

    var body: some View {
        let cells = gridDays()
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 6
        ) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                HomeCalendarDayCell(cell: cell)
            }
        }
    }

    /// 表示中の月のグリッドに並べるセル。先頭に月初めまでの空白セルを含む。
    private func gridDays() -> [HomeCalendarDay] {
        let calendar = SampleData.calendar
        let firstOfMonth = HomeCalendarMonth.startOfMonth(for: displayedMonth)
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
