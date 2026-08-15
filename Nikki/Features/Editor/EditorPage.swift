import SwiftUI
import SwiftData

/// エディタ。タイトルと本文 markdown をそのまま編集し、変更のたびに日記へ書き戻す。
/// entry(@Model)が唯一の状態で、Binding のセッター経由でドメインメソッドに書き戻す。
/// ナビ右端の「ノート」からノート一覧(1l)へ進み、選んだノートのテンプレートの内容で本文を置き換えられる。
/// 選択ツールバー(1j)・ブロック並び替え(1k)は静的表現のままで、この画面はテキスト編集に徹する。
struct EditorPage: View {
    let entry: JournalEntry

    /// ノート一覧(1l)への遷移状態。ノートが決まらないまま新規作成したときは、
    /// 呼び出し側が true を渡して「ページができる → ノートを選ぶ」の順で選択から入る。
    @State var notebookListIsPresented: Bool = false

    @AppStorage(.textSize) var textSize: TextSize = .standard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.resetAutoLockTimer) private var resetAutoLockTimer

    var body: some View {
        // 設定「文字の大きさ」は書く時間が長い本文にだけ反映する。標準は見本の 15pt、前後は読みやすさを保つ 2pt 刻み。
        let bodyFontSize: CGFloat = switch textSize {
        case .small: 13
        case .standard: 15
        case .large: 17
        }
        EditorScreenScaffold(
            caption: editorDateText(date: entry.date),
            onDismiss: { dismiss() },
            trailing: .text("ノート"),
            onTrailing: { notebookListIsPresented = true }
        ) {
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
                    .font(.ink(bodyFontSize))
                    .lineSpacing(inkLineSpacing(fontSize: bodyFontSize, multiplier: 2.05))
                    .foregroundStyle(Color.ink)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
        .inkNavigationBarHidden()
        .navigationDestination(isPresented: $notebookListIsPresented) {
            NotebookListPage(entry: entry)
        }
        // キーボード入力はタッチとして拾えないため、書き込み(updatedAt の更新)を無操作タイマーのリセットにする。
        .onChange(of: entry.updatedAt) {
            resetAutoLockTimer()
        }
        .onDisappear {
            // 直後にアプリが kill されても書きかけが残るよう、画面を離れるときに明示保存する(平常時は autosave が保存する)。
            try? modelContext.save()
        }
    }
}
