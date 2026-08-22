import SwiftUI
import SwiftData

/// テンプレートの編集(設定 > テンプレート > テンプレートの行から)。書き出し(markdown)は直接編集し、
/// 変更のたびにドメインメソッドで書き戻す(エディタと同じ即時反映)。
/// 名前は編集バッファに持ち、画面を離れるときにまとめて確定する。即時反映にすると1文字ずつ削除する
/// 過程の「非空の途中状態」が都度書き戻され、空にして離れたときに最後の1文字が残るため(issue #79)。
/// 削除しても、このテンプレートで書いた日記はどのノートにも属さないまま残る(モデルの削除ルール)。
struct NotebookEditPage: View {
    let notebook: JournalNotebook

    /// 名前欄の編集バッファ。画面を離れるとき・アプリがバックグラウンドへ移るときに notebook へ確定する。
    @State var name: String

    /// 確定済みの名前(編集開始時点、以降は確定のたびに更新)。この画面で編集していないのに確定すると、
    /// 表示中に CloudKit 同期などで変わった保存済みの名前を古い値で上書きするため、差分がある時だけ確定する。
    @State var originalName: String

    @State var deleteConfirmationDialogIsPresented = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor
    @Environment(\.scenePhase) private var scenePhase

    // @State(名前の編集バッファと確定済みの名前)の初期値を notebook から導出するため、カスタム init を定義する。
    init(notebook: JournalNotebook) {
        self.notebook = notebook
        self._name = State(initialValue: notebook.name)
        self._originalName = State(initialValue: notebook.name)
    }

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(String(localized: "Edit template")), onLeading: { dismiss() })
            NotebookFormFields(
                name: $name,
                markdown: Binding(get: { notebook.template?.markdown ?? "" }, set: { setTemplateMarkdown(markdown: $0) })
            )
            // 最後の1件まで削除できる(テンプレート0件の新規日記は白紙で始まり、
            // 既定のテンプレートは設定 > テンプレート の「既定のテンプレートを復元」で戻せる)。
            InkListSection {
                // 遷移ではなく確認ダイアログを開くアクション行のため、シェブロンは出さない。
                InkListRow(
                    title: String(localized: "Delete template"),
                    showsChevron: false,
                    showsSeparator: false,
                    action: { deleteConfirmationDialogIsPresented = true }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(paperColor.ignoresSafeArea())
        .inkNavigationBarHidden()
        .confirmationDialog("Delete template", isPresented: $deleteConfirmationDialogIsPresented, titleVisibility: .visible) {
            Button("Delete template", role: .destructive) {
                modelContext.delete(notebook)
                // 直後にアプリが kill されても削除の結果が残るよう明示保存する(平常時は autosave が保存する)。
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This deletes “\(notebook.name)”. Entries written with this template are kept.")
        }
        .onDisappear {
            commitName()
            // 直後にアプリが kill されても編集内容が残るよう、画面を離れるときに明示保存する(平常時は autosave が保存する)。
            try? modelContext.save()
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            // 画面を開いたままアプリが OS に終了されると onDisappear は実行されないため、
            // バックグラウンドへ移るときにも確定・保存して編集内容を残す。
            if newScenePhase == .background {
                commitName()
                try? modelContext.save()
            }
        }
    }

    /// 名前の編集内容をテンプレートへ確定する。この画面で編集していない(確定済みの名前と差分がない)ときは、
    /// 表示中に同期などで変わった保存済みの名前を上書きしないよう何もしない。
    /// 作成フォームと同じく、名前のないテンプレートが一覧・既定のテンプレートの選択に並ばないよう、
    /// 空白だけの名前は確定しない(空にしたまま離れると編集開始時点の名前のまま残る)。
    /// 削除して閉じたときは、コンテキストから外れたモデルに触れないよう書き戻さない。
    private func commitName() {
        if name == originalName {
            return
        }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        if notebook.isDeleted || notebook.modelContext == nil {
            return
        }
        notebook.setName(name: name)
        originalName = name
    }

    /// 書き出しの入力を JournalTemplate へ書き戻す。作成フォームと意味を揃え、空白だけの書き出しは
    /// 「差し込む内容なし(選んだとき本文を置き換えない)」として JournalTemplate ごと削除する。
    /// 書き出しを持たないテンプレートで入力が始まったら、このタイミングで作って紐付ける。
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
