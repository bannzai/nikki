import SwiftUI
import SwiftData

/// 設定 > テンプレート のテンプレート管理一覧。行のタップで編集へ、末尾の「＋ 新しいテンプレート」で作成へ進む。
/// 一覧の下の操作で、初回シードと同じ既定のテンプレート(白紙)の復元と、すべてのテンプレートの削除ができる。
struct NotebookSettingsPage: View {
    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    /// 行タップで開く編集画面への遷移状態。nil のときは一覧のまま。
    @State var notebook: JournalNotebook?
    /// 作成フォームへの遷移状態。
    @State var notebookCreateIsPresented = false
    @State var deleteAllConfirmationDialogIsPresented = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(String(localized: "Templates")), onLeading: { dismiss() })
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
                            title: String(localized: "Restore the default template"),
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
        .inkNavigationBarHidden()
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

    /// 初回シードと同じ既定のテンプレート(白紙)を一覧の末尾へ入れ直す。
    /// 同じ名前・同じ書き出しのテンプレートが既にあるときは重複させない(冪等)。
    private func restoreSeedNotebooks() {
        let seeds = SampleData.seedNotebooks(sortOrder: (notebooks.last?.sortOrder ?? -1) + 1)
        let restored = seeds.filter { seed in
            !notebooks.contains { $0.name == seed.name && $0.template?.markdown == seed.template?.markdown }
        }
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
