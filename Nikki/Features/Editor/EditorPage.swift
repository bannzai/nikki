import SwiftUI
import SwiftData

/// エディタ。本文全体を1つのテキストビュー (EditorTextView) で markdown のまま編集し、
/// 記法は行単位の装飾で表示する (Obsidian の Live Preview 方式。issue #111)。
/// 編集中は draftMarkdown(@State)が唯一の編集先で、entry(@Model)へは
/// 離脱・バックグラウンド移行・アプリ終了のタイミングで書き戻す(理由は draftMarkdown のコメント参照)。
/// タイトル入力は持たない。日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめを
/// わかりにくくしていたため、開いたら本文へフォーカスしてすぐ書ける形にする。
/// 過去に入力されたタイトルは、開いたときに本文先頭の見出しへ移して見えるまま残す。
/// 新規日記は既定のテンプレートの内容で書きはじまるため選択は求めず、変えたい人だけが
/// ナビ右端の「テンプレート」からテンプレート一覧(1l)で選び直せる(issue #82)。
/// 選択ツールバー(1j)・ブロック並び替え(1k)は静的表現のままで、この画面は本文の編集に徹する。
struct EditorPage: View {
    let entry: JournalEntry

    /// テンプレート一覧(1l)への遷移状態。
    @State var notebookListIsPresented: Bool = false

    /// 編集中の本文 markdown。キーストロークごとに entry(@Model) へ書き込むと、SwiftData の観測で
    /// body が再評価され、macOS の日本語入力の変換中テキストが破棄される(issue #86)。
    /// そのため編集中はこの @State を唯一の編集先にし、entry へは編集の切れ目
    /// (離脱・バックグラウンド移行・アプリ終了)でだけ書き戻す。
    @State var draftMarkdown: String = ""

    /// 開いた時点の本文 markdown。この画面で編集していないまま離脱したとき、表示中に CloudKit 同期などで
    /// entry 側が進んでいた場合に、開いた時点の古い draft で entry を上書きしないための目印。
    @State var openedMarkdown: String = ""

    @AppStorage(.textSize) var textSize: TextSize = .standard

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
            trailingButtonText: String(localized: "Template"),
            onTrailingButtonTap: { notebookListIsPresented = true }
        ) {
            ZStack(alignment: .topLeading) {
                EditorTextView(text: $draftMarkdown, bodyFontSize: bodyFontSize)
                if draftMarkdown.isEmpty {
                    // 本文をまだ何も書いていないときだけ出す、書きはじめの案内。
                    // 位置は EditorTextView の textContainerInset (水平28・上10) に合わせる。
                    Text("Write here…")
                        .font(.ink(bodyFontSize))
                        .foregroundStyle(Color.inkTextTertiary)
                        .padding(.horizontal, 28)
                        .padding(.top, 10)
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            // タイトル入力の廃止前に書かれた日記のタイトルを、本文先頭の見出しとして見えるまま残す。
            entry.mergeTitleIntoBodyMarkdown()
            loadDraftMarkdown()
        }
        // キーボード入力はタッチとして拾えないため、編集中の本文の変化を無操作タイマーのリセットにする。
        .onChange(of: draftMarkdown) {
            resetAutoLockTimer()
        }
        .navigationDestination(isPresented: $notebookListIsPresented) {
            NotebookListPage(entry: entry)
        }
        // テンプレート一覧から戻ったとき、テンプレートの適用で entry 側が書き換わった内容を編集中の本文へ反映する
        // (一覧へ遷移した時点の書きかけは、遷移時の onDisappear が entry へ書き戻し済み)。
        .onChange(of: notebookListIsPresented) {
            if !notebookListIsPresented {
                loadDraftMarkdown()
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

    /// entry の本文を編集中の markdown へ読み直す。本文があるときは末尾に空の行を1つ足し、
    /// 日記の続きを書く位置 (キャレットは EditorTextView が本文末尾に置く) を用意する。
    /// 足した空の行は、書かないまま離脱すれば書き戻し (withoutEmptyText の往復) で落ちる。
    /// 開いたときとテンプレート適用後の再同期で使う(同じ本文なら何度呼んでも同じ状態になる)。
    private func loadDraftMarkdown() {
        let bodyMarkdown = entry.bodyMarkdown
        if bodyMarkdown.isEmpty || bodyMarkdown.hasSuffix("\n\n") {
            draftMarkdown = bodyMarkdown
        } else {
            draftMarkdown = bodyMarkdown + "\n\n"
        }
        // 再同期は entry を正とした引き直しのため、この時点の本文を未編集の基準に置き直す。
        openedMarkdown = draftMarkdown
    }

    /// 編集中の本文を entry へ書き戻して保存する。この画面で編集していない・変更がない場合は
    /// 書き戻しを行わない(冪等)。編集していない間に CloudKit 同期などで entry 側が進んでいても、
    /// 開いた時点の古い draft で上書きしないようにする。
    /// 書き戻す前に、記法の断片だけが残った空のブロックを取り除く往復 (blocks → withoutEmptyText →
    /// markdown) を現行どおり通す。
    private func commitDraft() {
        if draftMarkdown != openedMarkdown {
            let bodyMarkdown = Block.markdown(blocks: Block.blocks(fromMarkdown: draftMarkdown).withoutEmptyText)
            if entry.bodyMarkdown != bodyMarkdown {
                entry.setBodyMarkdown(bodyMarkdown)
            }
            // 書き戻した時点の状態を新しい未編集の基準にする。バックグラウンド移行の中間保存の後に
            // 開いた時点の内容へ手で戻した場合も、次の書き戻しで「編集」として保存されるようにする。
            openedMarkdown = draftMarkdown
        }
        try? modelContext.save()
    }
}
