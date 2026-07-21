import SwiftUI
import SwiftData

/// エディタ。タイトルと本文 markdown をそのまま編集し、変更のたびに日記へ書き戻す。
/// 選択ツールバー(1j)・ブロック並び替え(1k)は静的表現のままで、この画面はテキスト編集に徹する。
struct EditorPage: View {
    let entry: JournalEntry

    /// 編集中のタイトル。変更のたびに entry へ書き戻す。
    @State var title: String
    /// 編集中の本文 markdown。変更のたびに entry へ書き戻す。
    @State var bodyMarkdown: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // @State の初期値を entry から導出するため custom init を用いる。
    init(entry: JournalEntry) {
        self.entry = entry
        self._title = State(initialValue: entry.title)
        self._bodyMarkdown = State(initialValue: entry.bodyMarkdown)
    }

    var body: some View {
        EditorScreenScaffold(caption: EditorDateText.caption(for: entry.date), onDismiss: { dismiss() }) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("タイトル", text: $title, axis: .vertical)
                    .font(InkTypography.entryTitle)
                    .foregroundStyle(InkColors.ink)
                    .padding(.bottom, 8)
                TextEditor(text: $bodyMarkdown)
                    .font(InkTypography.body.font)
                    .lineSpacing(InkTypography.body.lineSpacing)
                    .foregroundStyle(InkColors.ink)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: title) {
            entry.setTitle(title)
        }
        .onChange(of: bodyMarkdown) {
            entry.setBodyMarkdown(bodyMarkdown)
        }
        .onDisappear {
            // 直後にアプリが kill されても書きかけが残るよう、画面を離れるときに明示保存する(平常時は autosave が保存する)。
            try? modelContext.save()
        }
    }
}
