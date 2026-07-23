import SwiftUI

/// カレンダー本体。月送り・曜日ヘッダ・日グリッド(日記の墨ドット / today の墨円)と today の日記プレビューを表示する。
struct HomeCalendarBody: View {
    let entries: [JournalEntry]
    let today: Date

    /// 表示中の月(1日 00:00)。‹ › で前後の月に移動する。初期値は呼び出し側が決める。
    @State var displayedMonth: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HomeCalendarMonthNav(displayedMonth: $displayedMonth)
            HomeCalendarWeekdayHeader()
            HomeCalendarDaysGrid(entries: entries, today: today, displayedMonth: displayedMonth)
            // 前後の月を表示している間は today のカードが紛らわしいため、today を含む月だけプレビューを出す。
            if let entry = entries.first(where: { Calendar.display.isDate($0.date, inSameDayAs: today) }),
               Calendar.display.isDate(today, equalTo: displayedMonth, toGranularity: .month) {
                NavigationLink(value: entry) {
                    HomeCalendarPreviewCard(entry: entry)
                }
                .buttonStyle(.plain)
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
    static func startOfMonth(date: Date) -> Date {
        let calendar = Calendar.display
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

struct HomeCalendarBody_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeCalendarBody(
                entries: SampleData.entries,
                today: SampleData.referenceToday,
                displayedMonth: HomeCalendarMonth.startOfMonth(date: SampleData.referenceToday)
            )
        }
        .background(Color.inkPaper)
    }
}
