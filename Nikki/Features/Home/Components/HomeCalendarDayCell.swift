import SwiftUI

/// カレンダーの日セル。today は 36px の墨円で反転、日記のある日は 4px の墨ドット、未来日は微色。
/// 日記のある日はタップでその日記のエディタへ進む(entry が nil の日は NavigationLink が無効化される)。
struct HomeCalendarDayCell: View {
    let cell: HomeCalendarDay

    var body: some View {
        NavigationLink(value: cell.entry) {
            VStack(spacing: 0) {
                if let day = cell.day {
                    if cell.isToday {
                        Text("\(day)")
                            .font(.ink(14, .bold))
                            .foregroundStyle(Color.inkPrimaryButtonText)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.ink))
                            .padding(.top, 2)
                        Spacer(minLength: 0)
                    } else {
                        Text("\(day)")
                            .font(.ink(14, .regular))
                            .foregroundStyle(cell.isFuture ? Color.inkTextQuaternary : Color.ink)
                            .padding(.top, 8)
                        Spacer(minLength: 0)
                        Circle()
                            .fill(cell.entry != nil ? Color.ink : Color.clear)
                            .frame(width: 4, height: 4)
                            .padding(.bottom, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38, alignment: .top)
        }
        .buttonStyle(.plain)
    }
}

struct HomeCalendarDayCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HStack(spacing: 12) {
                HomeCalendarDayCell(cell: HomeCalendarDay(day: 18, isToday: true, isFuture: false, entry: nil))
                HomeCalendarDayCell(cell: HomeCalendarDay(day: 12, isToday: false, isFuture: false, entry: SampleData.entries[0]))
                HomeCalendarDayCell(cell: HomeCalendarDay(day: 25, isToday: false, isFuture: true, entry: nil))
            }
            .padding()
            .background(Color.inkPaper)
        }
    }
}
