import SwiftUI

/// 時系列リスト本体。日記を月ごとにまとめ、日付ブロック + タイトル + 2行抜粋の行を並べる。
struct HomeListBody: View {
    let entries: [JournalEntry]

    var body: some View {
        let monthGroups = HomeMonthGroup.grouped(from: entries)
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
