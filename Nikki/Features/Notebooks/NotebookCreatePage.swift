import SwiftUI
import SwiftData

/// 新しいテンプレートの作成フォーム(設定 > テンプレート、またはテンプレート一覧の「＋ 新しいテンプレート」から)。
/// 名前と書き出し(markdown)を入力して JournalNotebook + JournalTemplate を作成する。
/// リマインドの頻度は、通知のスケジューリングが未実装のうちはフォームに出さず「なし」で作る
/// (実際に通知されない設定を見せない)。
struct NotebookCreatePage: View {
    @State var name: String = ""
    // 初回シードの白紙と同じ、日付見出しだけの書き出しを起点にする。
    @State var markdown: String = "# {{date}}"

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(
                leading: .back,
                center: .title(String(localized: "New template")),
                trailing: .text(String(localized: "Create")),
                onLeading: { dismiss() },
                onTrailing: { create() }
            )
            NotebookFormFields(name: $name, markdown: $markdown)
        }
        .background(paperColor.ignoresSafeArea())
        .inkNavigationBarHidden()
    }

    /// テンプレートを作成・保存して一覧へ戻る。
    private func create() {
        // 名前のないテンプレートが一覧や既定のテンプレートの選択に並ばないよう、名前が空のままでは作成しない。
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        // 一覧の末尾に並ぶよう、既存の最大 sortOrder の次にする。
        let notebook = JournalNotebook(name: name, reminderFrequency: .none, sortOrder: (notebooks.last?.sortOrder ?? -1) + 1)
        modelContext.insert(notebook)
        // 書き出しが空のテンプレートは差し込む内容を持たない(選んだときに本文を置き換えない)ため、空の JournalTemplate は作らない。
        if !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let template = JournalTemplate(name: name, markdown: markdown, sortOrder: 0)
            modelContext.insert(template)
            notebook.add(template: template)
        }
        // 直後にアプリが kill されても作成したテンプレートが残るよう明示保存する(平常時は autosave が保存する)。
        try? modelContext.save()
        dismiss()
    }
}

struct NotebookCreatePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotebookCreatePage()
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
