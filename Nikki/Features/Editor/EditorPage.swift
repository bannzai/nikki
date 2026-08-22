import SwiftUI
import SwiftData

/// エディタ。本文 markdown をそのまま編集し、変更のたびに日記へ書き戻す。
/// entry(@Model)が唯一の状態で、Binding のセッター経由でドメインメソッドに書き戻す。
/// タイトル入力は持たない。日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめを
/// わかりにくくしていたため、開いたら本文へフォーカスしてすぐ書ける形にする。
/// 過去に入力されたタイトルは、開いたときに本文先頭の見出しへ移して見えるまま残す。
/// 新規日記は既定のテンプレートの内容で書きはじまるため選択は求めず、変えたい人だけが
/// ナビ右端の「テンプレート」からテンプレート一覧(1l)で選び直せる(issue #82)。
/// 選択ツールバー(1j)・ブロック並び替え(1k)は静的表現のままで、この画面はテキスト編集に徹する。
struct EditorPage: View {
    let entry: JournalEntry

    /// テンプレート一覧(1l)への遷移状態。
    @State var notebookListIsPresented: Bool = false

    /// 本文のフォーカス。開いたら本文へ当て、どこに書けばいいか迷わせない。
    @FocusState var bodyFieldIsFocused: Bool

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
            trailing: .text(String(localized: "Template")),
            onTrailing: { notebookListIsPresented = true }
        ) {
            TextEditor(text: Binding(get: { entry.bodyMarkdown }, set: { entry.setBodyMarkdown($0) }))
                .font(.ink(bodyFontSize))
                .lineSpacing(inkLineSpacing(fontSize: bodyFontSize, multiplier: 2.05))
                .foregroundStyle(Color.ink)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .focused($bodyFieldIsFocused)
                .overlay(alignment: .topLeading) {
                    if entry.bodyMarkdown.isEmpty {
                        Text("Write here…")
                            .font(.ink(bodyFontSize))
                            .foregroundStyle(Color.inkTextTertiary)
                            // TextEditor のテキスト原点(コンテナの上余白と行フラグメントの左余白)に合わせる。
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 10)
        }
        .inkNavigationBarHidden()
        .onAppear {
            // タイトル入力の廃止前に書かれた日記のタイトルを、本文先頭の見出しとして見えるまま残す。
            entry.mergeTitleIntoBodyMarkdown()
            bodyFieldIsFocused = true
        }
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
