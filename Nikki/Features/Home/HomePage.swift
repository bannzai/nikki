import SwiftUI
import SwiftData

/// ホームの表示モード(リスト / カレンダー)。セグメントの index と rawValue が対応する。
enum HomePageMode: Int, CaseIterable {
    case list
    case calendar
}

/// ホーム画面の共通シャーシ。ロゴヘッダ・検索バー・「リスト / カレンダー」セグメント・新規作成 FAB をまとめ、
/// 選択中セグメントに応じて時系列リスト(1g)とカレンダー(1h)を切り替える。
/// 日記は @Query で読み、行のタップでエディタ、FAB でテンプレート一覧(1l)へ進む。
struct HomePage: View {
    let today: Date

    /// セグメントの選択状態。切替時に相互のモードへ即時に切り替わる。初期値は呼び出し側が HomePageMode の rawValue で決める。
    @State var selectedIndex: Int

    /// FAB からのテンプレート一覧(1l)への遷移状態。
    @State var templateListIsPresented: Bool = false

    @Query(sort: \JournalEntry.date, order: .reverse) var entries: [JournalEntry]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.inkPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HomeHeader()
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

            InkFAB { templateListIsPresented = true }
                .padding(.trailing, 22)
                .padding(.bottom, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $templateListIsPresented) {
            TemplateListPage()
        }
        .navigationDestination(for: JournalEntry.self) { entry in
            EditorPage(entry: entry)
        }
    }

    private func segmentLabel(for mode: HomePageMode) -> String {
        switch mode {
        case .list: return "リスト"
        case .calendar: return "カレンダー"
        }
    }
}
