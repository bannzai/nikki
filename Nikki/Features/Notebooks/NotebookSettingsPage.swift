import SwiftUI
import SwiftData

/// 設定 > テンプレート のテンプレート管理一覧。行のタップで編集へ、末尾の「＋ 新しいテンプレート」で作成へ進む。
/// 一覧の下の操作で、初回シードと同じ既定の4テンプレート(日記・朝の3行・1日の振り返り・旅の記録)の復元と、
/// すべてのテンプレートの削除ができる。
struct NotebookSettingsPage: View {
    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    /// 行タップで開く編集画面への遷移状態。nil のときは一覧のまま。
    @State var notebook: JournalNotebook?
    /// 作成フォームへの遷移状態。
    @State var notebookCreateIsPresented = false
    @State var deleteAllConfirmationDialogIsPresented = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !notebooks.isEmpty {
                        InkListSection {
                            ForEach(Array(notebooks.enumerated()), id: \.element.id) { index, notebook in
                                InkListRow(
                                    title: notebook.name,
                                    showsSeparator: index < notebooks.count - 1,
                                    action: { self.notebook = notebook }
                                )
                            }
                        }
                    }

                    NotebookNewFooter(onTap: { notebookCreateIsPresented = true })

                    InkListSection {
                        // 遷移ではなくその場で復元するアクション行のため、シェブロンは出さない。
                        InkListRow(
                            title: String(localized: "Restore the default templates"),
                            showsChevron: false,
                            showsSeparator: !notebooks.isEmpty,
                            action: { restoreSeedNotebooks() }
                        )
                        if !notebooks.isEmpty {
                            // 遷移ではなく確認ダイアログを開くアクション行のため、シェブロンは出さない。
                            InkListRow(
                                title: String(localized: "Delete all templates"),
                                showsChevron: false,
                                showsSeparator: false,
                                action: { deleteAllConfirmationDialogIsPresented = true }
                            )
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .background(paperColor.ignoresSafeArea())
        .inkNavigationBar(title: String(localized: "Templates"))
        .navigationDestination(item: $notebook) { notebook in
            NotebookEditPage(notebook: notebook)
        }
        .navigationDestination(isPresented: $notebookCreateIsPresented) {
            NotebookCreatePage()
        }
        .confirmationDialog("Delete all templates", isPresented: $deleteAllConfirmationDialogIsPresented, titleVisibility: .visible) {
            Button("Delete all templates", role: .destructive) {
                // 直後にアプリが kill されても削除の結果が残るよう save まで行う。失敗しても @Query の再評価でストアの実態に追従するため、ここではエラーを扱わない。
                try? modelContext.deleteAllJournalNotebooks()
            }
        } message: {
            Text("This deletes every template. Entries written with them are kept.")
        }
    }

    /// 初回シードと同じ既定の4テンプレートを一覧の末尾へ入れ直す。
    /// テンプレートごとに、同じ書き出しのものが既にあるときは重複させない(冪等)。
    /// 名前も書き出しもロケールで変わる(String(localized:) の値が永続化される)ため、既存の判定は
    /// 単一言語の完全一致ではなく、全対応言語の書き出し集合(SampleData.seedMarkdownVariants)との一致で行う
    /// (シード時と復元時で表示言語が違っても重複させない)。
    private func restoreSeedNotebooks() {
        let restored = zip(
            SampleData.seedNotebooks(sortOrder: (notebooks.last?.sortOrder ?? -1) + 1),
            SampleData.seedMarkdownVariants
        )
        .filter { _, markdownVariants in
            !notebooks.contains { markdownVariants.contains($0.template?.markdown ?? "") }
        }
        .map { seed, _ in seed }
        if restored.isEmpty {
            return
        }
        modelContext.insert(notebooks: restored)
        // 直後にアプリが kill されても復元の結果が残るよう明示保存する(平常時は autosave が保存する)。
        try? modelContext.save()
    }
}

struct NotebookSettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotebookSettingsPage()
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
