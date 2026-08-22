import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

/// エディタ。本文 markdown をそのまま編集し、画面を離れるときに日記へ書き戻す。
/// 編集中は draftBodyMarkdown(@State)が唯一の編集先で、entry(@Model)へは
/// 離脱・バックグラウンド移行・アプリ終了のタイミングで書き戻す(理由は draftBodyMarkdown のコメント参照)。
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

    /// 編集中の本文。キーストロークごとに entry(@Model) へ書き込むと、SwiftData の観測で
    /// body が再評価され、macOS の日本語入力の変換中テキストが破棄される(issue #86)。
    /// そのため編集中はこの @State を唯一の編集先にし、entry へは編集の切れ目
    /// (離脱・バックグラウンド移行・アプリ終了)でだけ書き戻す。
    @State var draftBodyMarkdown: String = ""

    /// この画面で本文が編集されたかどうか。未編集のまま離脱したとき、表示中に CloudKit 同期などで
    /// entry 側が進んでいた場合に、開いた時点の古い draft で entry を上書きしないための目印。
    @State var draftBodyMarkdownIsEdited: Bool = false

    /// 本文のフォーカス。開いたら本文へ当て、どこに書けばいいか迷わせない。
    @FocusState var bodyFieldIsFocused: Bool

    @AppStorage(.textSize) var textSize: TextSize = .standard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.resetAutoLockTimer) private var resetAutoLockTimer
    @Environment(\.scenePhase) private var scenePhase

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
            TextEditor(text: $draftBodyMarkdown)
                .font(.ink(bodyFontSize))
                .lineSpacing(inkLineSpacing(fontSize: bodyFontSize, multiplier: 2.05))
                .foregroundStyle(Color.ink)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .focused($bodyFieldIsFocused)
                .overlay(alignment: .topLeading) {
                    if draftBodyMarkdown.isEmpty {
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
            draftBodyMarkdown = entry.bodyMarkdown
            bodyFieldIsFocused = true
        }
        // キーボード入力はタッチとして拾えないため、編集中の本文の変化を無操作タイマーのリセットにする。
        .onChange(of: draftBodyMarkdown) {
            // entry と同じ値への変化は、開いた直後の初期化やテンプレート適用後の再同期であって編集ではない。
            if draftBodyMarkdown != entry.bodyMarkdown {
                draftBodyMarkdownIsEdited = true
            }
            resetAutoLockTimer()
        }
        .navigationDestination(isPresented: $notebookListIsPresented) {
            NotebookListPage(entry: entry)
        }
        // テンプレート一覧から戻ったとき、テンプレートの適用で entry 側が書き換わった内容を編集中の本文へ反映する
        // (一覧へ遷移した時点の書きかけは、遷移時の onDisappear が entry へ書き戻し済み)。
        .onChange(of: notebookListIsPresented) {
            if !notebookListIsPresented {
                draftBodyMarkdown = entry.bodyMarkdown
                // 遷移前の書きかけは遷移時に書き戻し済みで、この再同期は entry を正とした引き直しのため、未編集の状態に戻す。
                draftBodyMarkdownIsEdited = false
            }
        }
        .onDisappear {
            commitDraft()
        }
        // アプリがバックグラウンドへ移った直後に kill されても書きかけが残るよう、非アクティブ化で書き戻して保存する。
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                commitDraft()
            }
        }
        #if os(macOS)
        // macOS の ⌘Q ではエディタの onDisappear が呼ばれないため、アプリ終了の通知で書き戻して保存する。
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            commitDraft()
        }
        #endif
    }

    /// 編集中の本文を entry へ書き戻して保存する。この画面で編集していない・変更がない場合は
    /// 書き戻しを行わない(冪等)。編集していない間に CloudKit 同期などで entry 側が進んでいても、
    /// 開いた時点の古い draft で上書きしないようにする。
    private func commitDraft() {
        if draftBodyMarkdownIsEdited && entry.bodyMarkdown != draftBodyMarkdown {
            entry.setBodyMarkdown(draftBodyMarkdown)
        }
        try? modelContext.save()
    }
}
