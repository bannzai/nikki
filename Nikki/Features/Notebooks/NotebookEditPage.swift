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
            InkNavBar(leading: .back, center: .title("ノートの編集"), onLeading: { dismiss() })
            NotebookFormFields(
                name: Binding(get: { notebook.name }, set: { notebook.setName(name: $0) }),
                markdown: Binding(get: { notebook.template?.markdown ?? "" }, set: { setTemplateMarkdown(markdown: $0) })
            )
            // 最後の1冊まで消すと、新規日記の書き出し(既定のノートのテンプレート)が次回起動の
            // 入れ直しまで無くなるため、2冊以上あるときだけ削除できる。
            if notebooks.count >= 2 {
                InkListSection {
                    // 遷移ではなく確認ダイアログを開くアクション行のため、シェブロンは出さない。
                    InkListRow(
                        title: "ノートを削除",
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
        .confirmationDialog("ノートを削除", isPresented: $deleteConfirmationDialogIsPresented, titleVisibility: .visible) {
            Button("ノートを削除", role: .destructive) {
                modelContext.delete(notebook)
                // 直後にアプリが kill されても削除の結果が残るよう明示保存する(平常時は autosave が保存する)。
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("「\(notebook.name)」と書き出しのテンプレートを削除します。このノートの日記は削除されずに残ります。")
        }
        .onDisappear {
            // 直後にアプリが kill されても編集内容が残るよう、画面を離れるときに明示保存する(平常時は autosave が保存する)。
            try? modelContext.save()
        }
    }

    /// 書き出しの入力をテンプレートへ書き戻す。テンプレートを持たないノート(書き出しを空で作成した等)は、
    /// 入力が始まったこのタイミングで作って紐付ける。
    private func setTemplateMarkdown(markdown: String) {
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
