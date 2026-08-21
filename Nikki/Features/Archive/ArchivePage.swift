import SwiftUI
import SwiftData

/// アーカイブした日記の一覧(設定 > アーカイブした日記)。ホームの時系列リストと同じ月まとめ + 行のレイアウト
/// (HomeMonthGroup / HomeEntryRow)で表示し、行のタップでエディタへ、コンテキストメニューでアーカイブから戻す。
struct ArchivePage: View {
    // #Predicate の filter を付けた @Query を push 遷移先の View に持たせると、iOS 26.5 で
    // navigationDestination の遷移自体が黙って失敗する(クラッシュ・ログなし)ことを実機検証で確認したため、
    // filter は使わず全件を取得して body 側で絞り込む(件数は日記アプリの規模なので読みやすさ優先の方針にも合う)。
    @Query(sort: \JournalEntry.date, order: .reverse) var entries: [JournalEntry]

    /// 行タップで開くエディタへの遷移状態。nil のときは一覧のまま。
    /// HomePage がルートに登録する navigationDestination(for: JournalEntry.self) は、
    /// isPresented 経由で2段 push したこの画面の NavigationLink(value:) からは解決されないことを
    /// 実機検証で確認したため、NotebookListPage と同じ item ベースの遷移をこの画面に閉じて持つ。
    @State var editorEntry: JournalEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let archivedEntries = entries.filter { $0.isArchived }
        ZStack(alignment: .top) {
            Color.inkPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title(String(localized: "Archived entries")), onLeading: { dismiss() })

                if archivedEntries.isEmpty {
                    ArchiveEmptyState()
                } else {
                    let monthGroups = HomeMonthGroup.grouped(from: archivedEntries)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(monthGroups.enumerated()), id: \.element.id) { groupIndex, group in
                                Text(group.title)
                                    .font(.ink(12, .bold).weight(.semibold))
                                    .foregroundStyle(Color.inkTextTertiary)
                                    .padding(.top, groupIndex == 0 ? 14 : 16)
                                    .padding(.bottom, 4)

                                ForEach(Array(group.entries.enumerated()), id: \.element.id) { rowIndex, entry in
                                    Button {
                                        editorEntry = entry
                                    } label: {
                                        HomeEntryRow(
                                            entry: entry,
                                            showsSeparator: !(groupIndex == monthGroups.count - 1
                                                && rowIndex == group.entries.count - 1)
                                        )
                                        // タイトルが短い行は大半が透明な余白で、そのままでは余白部分がヒットテストに
                                        // 乗らずコンテキストメニューが開けないため、行の矩形全体を判定領域にする。
                                        .contentShape(Rectangle())
                                        // Button の外側に付けると macOS で右クリックに反応しないため、
                                        // ラベル内側に付けて iOS の長押しと macOS の右クリックの両方を効かせる。
                                        .contextMenu {
                                            Button {
                                                entry.setArchived(false)
                                                // 直後にアプリが kill されても結果が残るよう明示保存する(平常時は autosave が保存する)。
                                                try? modelContext.save()
                                            } label: {
                                                Label("Unarchive", systemImage: InkIcons.unarchive)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .inkNavigationBarHidden()
        .navigationDestination(item: $editorEntry) { entry in
            EditorPage(entry: entry)
        }
    }
}

struct ArchivePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ArchivePage()
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
