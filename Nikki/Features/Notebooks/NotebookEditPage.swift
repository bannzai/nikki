import SwiftUI
import SwiftData

/// ノートの編集(設定 > ノート > ノートの行から)。名前と書き出しのテンプレート(markdown)を直接編集し、
/// 変更のたびにドメインメソッドで書き戻す(エディタと同じ即時反映)。
/// 削除するとテンプレートも一緒に消え、日記はどのノートにも属さないまま残る(モデルの削除ルール)。
struct NotebookEditPage: View {
    let notebook: JournalNotebook

    @State var deleteConfirmationDialogIsPresented = false

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(String(localized: "Edit notebook")), onLeading: { dismiss() })
            NotebookFormFields(
                name: Binding(get: { notebook.name }, set: { setName(name: $0) }),
                markdown: Binding(get: { notebook.template?.markdown ?? "" }, set: { setTemplateMarkdown(markdown: $0) })
            )
            // 最後の1冊まで消すと、新規日記の書き出し(既定のノートのテンプレート)が次回起動の
            // 入れ直しまで無くなるため、2冊以上あるときだけ削除できる。
            if notebooks.count >= 2 {
                InkListSection {
                    // 遷移ではなく確認ダイアログを開くアクション行のため、シェブロンは出さない。
                    InkListRow(
                        title: String(localized: "Delete notebook"),
                        showsChevron: false,
                        showsSeparator: false,
                        action: { deleteConfirmationDialogIsPresented = true }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.inkPaper.ignoresSafeArea())
        .inkNavigationBarHidden()
        .confirmationDialog("Delete notebook", isPresented: $deleteConfirmationDialogIsPresented, titleVisibility: .visible) {
            Button("Delete notebook", role: .destructive) {
                // ダイアログを開いている間に同期等で他のノートが消え、残り1冊になっていることがあるため、
                // 確定の直前にも「最後の1冊は消せない」を検証する。
                if notebooks.count < 2 {
                    return
                }
                modelContext.delete(notebook)
                // 直後にアプリが kill されても削除の結果が残るよう明示保存する(平常時は autosave が保存する)。
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This deletes “\(notebook.name)” and its template. Entries in this notebook are kept.")
        }
        .onDisappear {
            // 直後にアプリが kill されても編集内容が残るよう、画面を離れるときに明示保存する(平常時は autosave が保存する)。
            try? modelContext.save()
        }
    }

    /// 名前の入力をノートへ書き戻す。作成フォームと同じく、名前のないノートが一覧・既定のノートの選択に
    /// 並ばないよう、空白だけの入力は書き戻さない(入力欄を離れると元の名前に戻る)。
    private func setName(name: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        notebook.setName(name: name)
    }

    /// 書き出しの入力をテンプレートへ書き戻す。作成フォームと意味を揃え、空白だけの書き出しは
    /// 「テンプレートなし(ノートを選んだとき本文を置き換えない)」としてテンプレートごと削除する。
    /// テンプレートを持たないノートで入力が始まったら、このタイミングで作って紐付ける。
    private func setTemplateMarkdown(markdown: String) {
        if markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            for template in notebook.templates ?? [] {
                modelContext.delete(template)
            }
            return
        }
        if let template = notebook.template {
            template.setMarkdown(markdown: markdown)
        } else {
            let template = JournalTemplate(name: notebook.name, markdown: markdown, sortOrder: 0)
            modelContext.insert(template)
            notebook.add(template: template)
        }
    }
}

struct NotebookEditPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotebookEditPage(notebook: SampleData.notebooks[1])
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
