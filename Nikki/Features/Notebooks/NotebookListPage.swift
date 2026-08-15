import SwiftUI
import SwiftData

/// ノート一覧(1l)。「今日はどの紙に書きますか。」の見出しの下に、
/// 各ノートをカード(名前 + リマインドの頻度 + シェブロン + テンプレートの markdown プレビュー)で並べる。
/// カードを選ぶと日記をそのノートに入れ、ノートのテンプレートの内容({{date}} は日記の日付で補完)で
/// entry を置き換えて保存し、次回の新規作成で自動的に使う既定のノートとして記憶してエディタへ戻る。
/// entry に入力があるときは、置き換えで入力内容が消えることをアラートで確認してから置き換える。
/// 末尾の「＋ 新しいノート」からは作成フォーム(NotebookCreatePage)へ進む。
struct NotebookListPage: View {
    /// ノートを決める対象の日記。遷移元のエディタが表示中の日記を渡す。
    let entry: JournalEntry

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    /// 置き換え確認アラートの対象ノート。nil のときはアラートを閉じている。
    @State var notebook: JournalNotebook?
    @State var replaceAlertIsPresented = false

    /// 「＋ 新しいノート」の作成フォームへの遷移状態。
    @State var notebookCreateIsPresented = false

    /// 既定のノートの id(UUID 文字列)。空のときは未設定。選んだノートを次回の自動挿入用に記憶する。
    @AppStorage(.defaultNotebookID) var defaultNotebookID: String = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title("ノート"), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("今日はどの紙に書きますか。")
                        .font(.ink(12.5, .regular))
                        .foregroundStyle(Color.inkTextSecondary)
                        .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
                        .padding(.bottom, 16)

                    VStack(spacing: 12) {
                        ForEach(notebooks) { notebook in
                            NotebookCard(notebook: notebook) { select(notebook: notebook) }
                        }
                    }

                    NotebookNewFooter(onTap: { notebookCreateIsPresented = true })
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.inkPaper.ignoresSafeArea())
        .inkNavigationBarHidden()
        .navigationDestination(isPresented: $notebookCreateIsPresented) {
            NotebookCreatePage()
        }
        .alert("入力内容の置き換え", isPresented: $replaceAlertIsPresented, presenting: notebook) { notebook in
            Button("置き換える", role: .destructive) { apply(notebook: notebook) }
            Button("キャンセル", role: .cancel) {}
        } message: { notebook in
            Text("「\(notebook.name)」を選ぶと、いま入力されている内容は消えます。")
        }
    }

    /// カードで選んだノートを適用する。entry に入力があるときは、消えることを確認してから適用する。
    private func select(notebook: JournalNotebook) {
        if entry.title.isEmpty && entry.bodyMarkdown.isEmpty {
            apply(notebook: notebook)
        } else {
            self.notebook = notebook
            replaceAlertIsPresented = true
        }
    }

    /// 日記をノートに入れ、ノートのテンプレートの内容で置き換えて保存し、既定のノートとして記憶してエディタへ戻る。
    private func apply(notebook: JournalNotebook) {
        entry.setNotebook(notebook: notebook)
        // テンプレートを持たないノートは置き換えるものがないため、所属だけ変えて本文はそのまま残す。
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
