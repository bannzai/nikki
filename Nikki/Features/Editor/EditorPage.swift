import SwiftUI
import SwiftData

/// エディタ。タイトルと本文 markdown をそのまま編集し、変更のたびに日記へ書き戻す。
/// entry(@Model)が唯一の状態で、Binding のセッター経由でドメインメソッドに書き戻すため @State は持たない。
/// 選択ツールバー(1j)・ブロック並び替え(1k)は静的表現のままで、この画面はテキスト編集に徹する。
struct EditorPage: View {
    let entry: JournalEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        EditorScreenScaffold(caption: EditorDateText.caption(for: entry.date), onDismiss: { dismiss() }) {
            VStack(alignment: .leading, spacing: 0) {
                TextField(
                    "タイトル",
                    text: Binding(get: { entry.title }, set: { entry.setTitle($0) }),
                    axis: .vertical
                )
                .font(.inkEntryTitle)
                .foregroundStyle(Color.ink)
                .padding(.bottom, 8)

                TextEditor(text: Binding(get: { entry.bodyMarkdown }, set: { entry.setBodyMarkdown($0) }))
                    .font(.ink(15))
                    .lineSpacing(inkLineSpacing(fontSize: 15, multiplier: 2.05))
                    .foregroundStyle(Color.ink)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            // 直後にアプリが kill されても書きかけが残るよう、画面を離れるときに明示保存する(平常時は autosave が保存する)。
            try? modelContext.save()
        }
    }
}
