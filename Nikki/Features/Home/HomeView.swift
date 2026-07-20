import SwiftUI

/// ホーム画面の共通シャーシ。ロゴヘッダ・検索バー・「リスト / カレンダー」セグメント・新規作成 FAB をまとめ、
/// 選択中セグメントに応じて時系列リスト(1g)とカレンダー(1h)を切り替える。
struct HomeView: View {
    let entries: [JournalEntry]
    let today: Date
    var onNewEntry: () -> Void
    var onAccount: () -> Void

    /// セグメントの選択状態。切替時に相互のモードへ即時に切り替わる。
    @State private var selectedIndex: Int

    /// @State の初期値を initialMode から決めるため custom init を用いる。
    init(
        entries: [JournalEntry] = SampleData.entries,
        today: Date = SampleData.referenceToday,
        initialMode: HomeViewMode = .list,
        onNewEntry: @escaping () -> Void = {},
        onAccount: @escaping () -> Void = {}
    ) {
        self.entries = entries
        self.today = today
        self.onNewEntry = onNewEntry
        self.onAccount = onAccount
        self._selectedIndex = State(initialValue: initialMode.rawValue)
    }

    private var selectedMode: HomeViewMode {
        HomeViewMode(rawValue: selectedIndex) ?? .list
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    InkSearchBar()
                    InkSegmentedControl(
                        options: HomeViewMode.allCases.map(\.label),
                        selectedIndex: $selectedIndex
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                content(for: selectedMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            InkFAB(action: onNewEntry)
                .padding(.trailing, 22)
                .padding(.bottom, 16)
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("Nikki")
                .font(InkTypography.screenTitle)
                .tracking(20 * 0.03)
                .foregroundStyle(InkColors.ink)
            Spacer(minLength: 0)
            Button(action: onAccount) {
                Image(systemName: "person")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color(hex: 0x52514E))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func content(for mode: HomeViewMode) -> some View {
        switch mode {
        case .list:
            HomeListBody(entries: entries)
        case .calendar:
            HomeCalendarBody(entries: entries, today: today)
        }
    }
}
