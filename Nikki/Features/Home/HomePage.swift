import SwiftUI
import SwiftData

/// ホームの表示モード(リスト / カレンダー)。セグメントの index と rawValue が対応する。
enum HomePageMode: Int, CaseIterable {
    case list
    case calendar
}

/// ホーム画面の共通シャーシ。ロゴヘッダ・検索バー・「リスト / カレンダー」セグメント・新規作成 FAB をまとめ、
/// 選択中セグメントに応じて時系列リスト(1g)とカレンダー(1h)を切り替える。
/// 日記は @Query で読み、検索バーの入力でタイトル・本文に一致する日記へ絞り込む。
/// 行のタップでエディタ、FAB でテンプレート一覧(1l)へ進む。
struct HomePage: View {
    /// 表示モードの選択状態。リスト派/カレンダー派の常用に合わせて起動をまたいで保持する。
    @AppStorage(.homePageMode) var homePageMode: HomePageMode = .list

    /// 検索バーの入力。空のときは全件を表示する。
    @State var searchText: String = ""

    /// FAB からのテンプレート一覧(1l)への遷移状態。
    @State var templateListIsPresented: Bool = false

    /// 検索バーのフォーカス。⌘F ショートカットからも当てられるようにここで持つ。
    @FocusState var searchFieldIsFocused: Bool

    @Query(sort: \JournalEntry.date, order: .reverse) var entries: [JournalEntry]

    @Environment(\.today) private var today
    @Environment(\.resetAutoLockTimer) private var resetAutoLockTimer

    var body: some View {
        let filteredEntries = searchText.isEmpty ? entries : entries.filter { $0.matches(searchText: searchText) }
        ZStack(alignment: .bottomTrailing) {
            Color.inkPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HomeHeader()
                    InkSearchBar(text: $searchText, isFocused: $searchFieldIsFocused)
                    InkSegmentedControl(
                        options: HomePageMode.allCases.map { segmentLabel(for: $0) },
                        selectedIndex: Binding(
                            get: { homePageMode.rawValue },
                            // セグメントの index が enum の範囲外になることはないが、rawValue init が failable のため list に倒す。
                            set: { homePageMode = HomePageMode(rawValue: $0) ?? .list }
                        )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Group {
                    switch homePageMode {
                    case .list:
                        if filteredEntries.isEmpty && !searchText.isEmpty {
                            HomeSearchEmptyState()
                        } else {
                            HomeListBody(entries: filteredEntries)
                        }
                    case .calendar:
                        HomeCalendarBody(entries: filteredEntries, displayedMonth: HomeCalendarMonth.startOfMonth(date: today))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            Button {
                templateListIsPresented = true
            } label: {
                // アイコンのみ表示しつつ、⌘ 長押しのショートカット一覧と VoiceOver に名前を出すため Label にする。
                Label("新しい日記", systemImage: InkIcons.pen)
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(InkFABButtonStyle())
            .keyboardShortcut("n", modifiers: .command)
            .padding(.trailing, 22)
            .padding(.bottom, 16)
        }
        // ハードウェアキーボード(iPad / Mac)から検索フィールドへフォーカスするためのショートカット。画面には出さない。
        .background {
            Button("日記をさがす") {
                searchFieldIsFocused = true
            }
            .keyboardShortcut("f", modifiers: .command)
            .hidden()
        }
        .inkNavigationBarHidden()
        // キーボード入力はタッチとして拾えないため、検索の入力を無操作タイマーのリセットにする。
        .onChange(of: searchText) {
            resetAutoLockTimer()
        }
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
