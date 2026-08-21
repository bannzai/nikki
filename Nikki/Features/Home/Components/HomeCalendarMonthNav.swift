import SwiftUI

/// カレンダーの月送りナビ。‹ 2026年7月 › の形式で表示し、シェブロンで前後の月へ移動する。
struct HomeCalendarMonthNav: View {
    @Binding var displayedMonth: Date

    var body: some View {
        HStack(spacing: 0) {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: InkIcons.chevronLeft)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextSecondary)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text(displayedMonth.formatted(localizedPattern: "MMMM y"))
                .font(.ink(15, .bold))
                .foregroundStyle(Color.ink)

            Spacer(minLength: 0)

            Button { shiftMonth(by: 1) } label: {
                Image(systemName: InkIcons.chevronRight)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 14)
    }

    private func shiftMonth(by delta: Int) {
        if let shifted = Calendar.display.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = HomeCalendarMonth.startOfMonth(date: shifted)
        }
    }
}

struct HomeCalendarMonthNav_Previews: PreviewProvider {
    static var previews: some View {
        HomeCalendarMonthNav(displayedMonth: .constant(HomeCalendarMonth.startOfMonth(date: SampleData.referenceToday)))
            .padding()
            .background(Color.inkPaper)
    }
}
