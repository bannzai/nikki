import SwiftUI
import SwiftData

/// 設定 > テンプレート のテンプレート管理一覧。行のタップで編集へ、末尾の「＋ 新しいテンプレート」で作成へ進む。
struct NotebookSettingsPage: View {
    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    /// 行タップで開く編集画面への遷移状態。nil のときは一覧のまま。
    @State var notebook: JournalNotebook?
    /// 作成フォームへの遷移状態。
    @State var notebookCreateIsPresented = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(String(localized: "Templates")), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    InkListSection {
                        ForEach(Array(notebooks.enumerated()), id: \.element.id) { index, notebook in
                            InkListRow(
                                title: notebook.name,
                                showsSeparator: index < notebooks.count - 1,
                                action: { self.notebook = notebook }
                            )
                        }
                    }

                    NotebookNewFooter(onTap: { notebookCreateIsPresented = true })
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
