import SwiftUI

/// カレンダーの月送りナビ。‹ 2026年7月 › の形式で表示し、シェブロンで前後の月へ移動する。
struct HomeCalendarMonthNav: View {
    @Binding var displayedMonth: Date

    var body: some View {
        let comps = SampleData.calendar.dateComponents([.year, .month], from: displayedMonth)
        HStack(spacing: 0) {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: InkIcons.chevronLeft)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(InkColors.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            // Text の Int 補間はロケール書式で桁区切り(2,026)が入るため、String にしてから表示する。
            Text("\(String(comps.year ?? 0))年\(comps.month ?? 0)月")
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

    private func shiftMonth(by delta: Int) {
        if let shifted = SampleData.calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = HomeCalendarMonth.startOfMonth(for: shifted)
        }
    }
}
