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
/// 行のタップでエディタへ進む。FAB は日記を先に作成してからエディタへ進み、
/// 既定のノート(未設定なら先頭のノート)のテンプレートの内容を自動挿入する。
/// ノートを意識させないため、作成時にノート選択は挟まない。
struct HomePage: View {
    /// 表示モードの選択状態。リスト派/カレンダー派の常用に合わせて起動をまたいで保持する。
    @AppStorage(.homePageMode) var homePageMode: HomePageMode = .list

    /// 既定のノートの id(UUID 文字列)。空のときは未設定で、先頭のノートを既定として扱う。
    @AppStorage(.defaultNotebookID) var defaultNotebookID: String = ""

    /// 検索バーの入力。空のときは全件を表示する。
    @State var searchText: String = ""

    /// FAB が作成した日記。エディタへの遷移に使う。
    @State var entry: JournalEntry?

    /// 検索バーのフォーカス。⌘F ショートカットからも当てられるようにここで持つ。
    @FocusState var searchFieldIsFocused: Bool

    // アーカイブ済みの日記はホーム(リスト・カレンダー・検索)に出さず、設定 > アーカイブした日記でだけ見せる。
    @Query(
        filter: #Predicate<JournalEntry> { $0.isArchived == false },
        sort: \JournalEntry.date,
        order: .reverse
    ) var entries: [JournalEntry]

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    @Environment(\.today) private var today
    @Environment(\.resetAutoLockTimer) private var resetAutoLockTimer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        let filteredEntries = searchText.isEmpty ? entries : entries.filter { $0.matches(searchText: searchText) }
        ZStack(alignment: .bottomTrailing) {
            paperColor.ignoresSafeArea()

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
                createEntry()
            } label: {
                // アイコンのみ表示しつつ、⌘ 長押しのショートカット一覧と VoiceOver に名前を出すため Label にする。
                Label("New entry", systemImage: InkIcons.pen)
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(InkFABButtonStyle())
            .keyboardShortcut("n", modifiers: .command)
            .padding(.trailing, 22)
            .padding(.bottom, 16)
        }
        // ハードウェアキーボード(iPad / Mac)から検索フィールドへフォーカスするためのショートカット。画面には出さない。
        .background {
            Button("Search your journal") {
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
        .navigationDestination(item: $entry) { entry in
            EditorPage(entry: entry)
        }
        .navigationDestination(for: JournalEntry.self) { entry in
            EditorPage(entry: entry)
        }
    }

    /// FAB の新規作成。既定のノート(未設定なら先頭のノート)のテンプレートの内容({{date}} は今日で補完)を
    /// 挿入した日記を作成・保存し、エディタへの遷移を起こす。
    private func createEntry() {
        // 日付が変わる瞬間に {{date}} の補完値と日記の date がずれないよう、同じ時刻を共有する。
        let now = Date.now
        let notebook = notebooks.first { $0.id.uuidString == defaultNotebookID } ?? notebooks.first
        let entry: JournalEntry
        if let template = notebook?.template {
            entry = JournalEntry(
                templateMarkdown: TemplateVariableField.substitutedMarkdown(
                    template: template,
                    fields: TemplateVariableField.fields(template: template, today: now, includesDemoValues: false)
                ),
                date: now
            )
        } else {
            entry = JournalEntry(date: now, title: "", bodyMarkdown: "", createdAt: now, updatedAt: now)
        }
        modelContext.insert(entry)
        // 所属の設定は、日記が同じコンテキストに入ってから行う。
        if let notebook {
            entry.setNotebook(notebook: notebook)
        }
        // 直後にアプリが kill されても作成した日記が残るよう明示保存する(平常時は autosave が保存する)。
        try? modelContext.save()
        self.entry = entry
    }

    private func segmentLabel(for mode: HomePageMode) -> String {
        switch mode {
        case .list: return String(localized: "List")
        case .calendar: return String(localized: "Calendar")
        }
    }
}
