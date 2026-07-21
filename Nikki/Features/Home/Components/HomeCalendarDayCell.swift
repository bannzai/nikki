import SwiftUI

/// カレンダーの日セル。today は 36px の墨円で反転、日記のある日は 4px の墨ドット、未来日は微色。
struct HomeCalendarDayCell: View {
    let cell: HomeCalendarDay

    var body: some View {
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
}
