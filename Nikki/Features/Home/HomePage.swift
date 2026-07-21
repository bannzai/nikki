import SwiftUI

/// ホーム画面の共通シャーシ。ロゴヘッダ・検索バー・「リスト / カレンダー」セグメント・新規作成 FAB をまとめ、
/// 選択中セグメントに応じて時系列リスト(1g)とカレンダー(1h)を切り替える。
struct HomePage: View {
    let entries: [JournalEntry]
    let today: Date
    var onNewEntry: () -> Void
    var onAccount: () -> Void

    /// セグメントの選択状態。切替時に相互のモードへ即時に切り替わる。
    @State var selectedIndex: Int

    /// @State の初期値を initialMode から決めるため custom init を用いる。
    init(
        entries: [JournalEntry] = SampleData.entries,
        today: Date = SampleData.referenceToday,
        initialMode: HomePageMode = .list,
        onNewEntry: @escaping () -> Void = {},
        onAccount: @escaping () -> Void = {}
    ) {
        self.entries = entries
        self.today = today
        self.onNewEntry = onNewEntry
        self.onAccount = onAccount
        self._selectedIndex = State(initialValue: initialMode.rawValue)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HomeHeader(onAccount: onAccount)
                    InkSearchBar()
                    InkSegmentedControl(
                        options: HomePageMode.allCases.map { segmentLabel(for: $0) },
                        selectedIndex: $selectedIndex
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Group {
                    switch HomePageMode(rawValue: selectedIndex) ?? .list {
                    case .list:
                        HomeListBody(entries: entries)
                    case .calendar:
                        HomeCalendarBody(entries: entries, today: today)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            InkFAB(action: onNewEntry)
                .padding(.trailing, 22)
                .padding(.bottom, 16)
        }
    }

    private func segmentLabel(for mode: HomePageMode) -> String {
        switch mode {
        case .list: return "リスト"
        case .calendar: return "カレンダー"
        }
    }
}
