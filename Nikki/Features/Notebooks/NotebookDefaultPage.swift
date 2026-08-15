import SwiftUI
import SwiftData

/// 設定 > 既定のノート の選択一覧。新規日記の書き出しに使うノートを選ぶ。
/// macOS の confirmationDialog(NSAlert)はボタン4個までしか出せず、ノートは自由に増やせるため、
/// ダイアログではなく一覧画面で選ぶ。
struct NotebookDefaultPage: View {
    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]

    /// 既定のノートの id(UUID 文字列)。空のときは未設定。
    @AppStorage(.defaultNotebookID) var defaultNotebookID: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // 未設定のときは新規作成と同じ解決(先頭のノート)を選択中として見せる。
        let defaultNotebook = notebooks.first { $0.id.uuidString == defaultNotebookID } ?? notebooks.first
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title("既定のノート"), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    InkListSection {
                        ForEach(Array(notebooks.enumerated()), id: \.element.id) { index, notebook in
                            InkListRow(
                                title: notebook.name,
                                showsChevron: false,
                                showsSeparator: index < notebooks.count - 1,
                                trailing: notebook == defaultNotebook
                                    ? AnyView(
                                        Image(systemName: InkIcons.checkmark)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Color.ink)
                                    )
                                    : nil,
                                action: {
                                    defaultNotebookID = notebook.id.uuidString
                                    dismiss()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .background(Color.inkPaper.ignoresSafeArea())
        .inkNavigationBarHidden()
    }
}

struct NotebookDefaultPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotebookDefaultPage()
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
