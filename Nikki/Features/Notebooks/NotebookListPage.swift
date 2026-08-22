import SwiftUI
import SwiftData

/// テンプレート一覧(1l)。日記に使うテンプレートをカード(名前 + リマインドの頻度 +
/// テンプレートの markdown プレビュー)で並べ、いま日記に使われているものにチェックを付ける
/// (新規日記は既定のテンプレートが選ばれた状態になる。issue #82)。
/// カードを選ぶとそのテンプレートの内容({{date}} は日記の日付で補完)で entry を置き換えて保存し、
/// 次回の新規作成で自動的に使う既定のテンプレートとして記憶してエディタへ戻る。
/// entry に入力があるときは、置き換えで入力内容が消えることをアラートで確認してから置き換える。
/// 末尾の「＋ 新しいテンプレート」からは作成フォーム(NotebookCreatePage)へ進む。
struct NotebookListPage: View {
    /// テンプレートを決める対象の日記。遷移元のエディタが表示中の日記を渡す。
    let entry: JournalEntry

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    /// 置き換え確認アラートの対象テンプレート。nil のときはアラートを閉じている。
    @State var notebook: JournalNotebook?
    @State var replaceAlertIsPresented = false

    /// 「＋ 新しいテンプレート」の作成フォームへの遷移状態。
    @State var notebookCreateIsPresented = false

    /// 既定のテンプレートの id(UUID 文字列)。空のときは未設定。選んだテンプレートを次回の自動挿入用に記憶する。
    @AppStorage(.defaultNotebookID) var defaultNotebookID: String = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(String(localized: "Templates")), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Choose the template for this entry.")
                        .font(.ink(12.5, .regular))
                        .foregroundStyle(Color.inkTextSecondary)
                        .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
                        .padding(.bottom, 16)

                    VStack(spacing: 12) {
                        ForEach(notebooks) { notebook in
                            NotebookCard(
                                notebook: notebook,
                                isSelected: notebook.id == entry.notebook?.id,
                                onTap: { select(notebook: notebook) }
                            )
                        }
                    }

                    NotebookNewFooter(onTap: { notebookCreateIsPresented = true })
                }
                .padding(.horizontal, 24)
            }
        }
        .background(paperColor.ignoresSafeArea())
        .inkNavigationBarHidden()
        .navigationDestination(isPresented: $notebookCreateIsPresented) {
            NotebookCreatePage()
        }
        .alert("Replace current content", isPresented: $replaceAlertIsPresented, presenting: notebook) { notebook in
            Button("Replace", role: .destructive) { apply(notebook: notebook) }
            Button("Cancel", role: .cancel) {}
        } message: { notebook in
            Text("Choosing “\(notebook.name)” will discard what you've written.")
        }
    }

    /// カードで選んだテンプレートを適用する。entry に入力があるときは、消えることを確認してから適用する。
    private func select(notebook: JournalNotebook) {
        if entry.title.isEmpty && entry.bodyMarkdown.isEmpty {
            apply(notebook: notebook)
        } else {
            self.notebook = notebook
            replaceAlertIsPresented = true
        }
    }

    /// 日記をテンプレートに紐付け、その内容で本文を置き換えて保存し、既定のテンプレートとして記憶してエディタへ戻る。
    private func apply(notebook: JournalNotebook) {
        entry.setNotebook(notebook: notebook)
        // 書き出しを持たないテンプレートは置き換えるものがないため、紐付けだけ変えて本文はそのまま残す。
        if let template = notebook.template {
            entry.replace(templateMarkdown: TemplateVariableField.substitutedMarkdown(
                template: template,
                fields: TemplateVariableField.fields(template: template, today: entry.date, includesDemoValues: false)
            ))
        }
        // エディタへ戻った直後にアプリが kill されても置き換えが残るよう明示保存する。
        try? modelContext.save()
        defaultNotebookID = notebook.id.uuidString
        dismiss()
    }
}

struct NotebookListPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotebookListPage(entry: SampleData.sampleEntry)
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
