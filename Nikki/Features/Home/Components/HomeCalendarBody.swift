import SwiftUI

/// カレンダー本体。月送り・曜日ヘッダ・日グリッド(日記の墨ドット / today の墨円)と today の日記プレビューを表示する。
struct HomeCalendarBody: View {
    let entries: [JournalEntry]
    let today: Date

    /// 表示中の月(1日 00:00)。‹ › で前後の月に移動する。@State の初期値を today から決めるため custom init を用いる。
    @State var displayedMonth: Date

    init(entries: [JournalEntry], today: Date) {
        self.entries = entries
        self.today = today
        self._displayedMonth = State(initialValue: HomeCalendarMonth.startOfMonth(for: today))
    }

    var body: some View {
        let todayEntry = entries.first { SampleData.calendar.isDate($0.date, inSameDayAs: today) }
        VStack(alignment: .leading, spacing: 0) {
            HomeCalendarMonthNav(displayedMonth: $displayedMonth)
            HomeCalendarWeekdayHeader()
            HomeCalendarDaysGrid(entries: entries, today: today, displayedMonth: displayedMonth)
            if let entry = todayEntry {
                HomeCalendarPreviewCard(entry: entry)
                    .padding(.top, 14)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }
}

/// 月の起点日付を扱う共通ヘルパー。
enum HomeCalendarMonth {
    /// 指定日を含む月の1日 00:00 を返す。
    static func startOfMonth(for date: Date) -> Date {
        let calendar = SampleData.calendar
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
