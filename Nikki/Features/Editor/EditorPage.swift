import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

/// エディタ。本文をブロック単位で装飾表示しながら編集し、画面を離れるときに日記へ書き戻す。
/// 編集中は draftBlocks(@State)が唯一の編集先で、entry(@Model)へは
/// 離脱・バックグラウンド移行・アプリ終了のタイミングで書き戻す(理由は draftBlocks のコメント参照)。
/// タイトル入力は持たない。日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめを
/// わかりにくくしていたため、開いたら本文へフォーカスしてすぐ書ける形にする。
/// 過去に入力されたタイトルは、開いたときに本文先頭の見出しへ移して見えるまま残す。
/// 新規日記は既定のテンプレートの内容で書きはじまるため選択は求めず、変えたい人だけが
/// ナビ右端の「テンプレート」からテンプレート一覧(1l)で選び直せる(issue #82)。
/// 選択ツールバー(1j)・ブロック並び替え(1k)は静的表現のままで、この画面はブロックの中身の編集に徹する。
struct EditorPage: View {
    let entry: JournalEntry

    /// テンプレート一覧(1l)への遷移状態。
    @State var notebookListIsPresented: Bool = false

    /// 編集中の本文ブロック。キーストロークごとに entry(@Model) へ書き込むと、SwiftData の観測で
    /// body が再評価され、macOS の日本語入力の変換中テキストが破棄される(issue #86)。
    /// そのため編集中はこの @State を唯一の編集先にし、entry へは編集の切れ目
    /// (離脱・バックグラウンド移行・アプリ終了)でだけ書き戻す。
    /// 同じ理由で、キーストロークごとに本文全体を markdown から読み直すこともしない
    /// (ブロックの id が変わり、入力欄の同一性が壊れる)。
    @State var draftBlocks: [Block] = []

    /// 開いた時点の本文ブロック。この画面で編集していないまま離脱したとき、表示中に CloudKit 同期などで
    /// entry 側が進んでいた場合に、開いた時点の古い draft で entry を上書きしないための目印。
    @State var openedBlocks: [Block] = []

    /// 入力中の欄。見出し・段落はブロックの id、チェックリストは項目の id を指す。
    /// 開いたら本文の先頭へ当て、どこに書けばいいか迷わせない。
    @FocusState var focusedFieldID: UUID?

    @AppStorage(.textSize) var textSize: TextSize = .standard

    #if os(macOS)
    /// 空のチェックリスト項目でのバックスペースを拾うキー入力監視の解除用トークン。
    /// SwiftUI の onKeyPress は macOS では編集中の入力欄(field editor)にイベントを消費されて
    /// 発火しないため(issue #108)、エディタ表示中だけ NSEvent のローカル監視で拾う。
    @State var checklistBackspaceMonitor: Any?
    #endif

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
            ScrollView(.vertical, showsIndicators: false) {
                // ブロックの間隔は、見本(1j)が並べるブロック例の間隔に合わせる。
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(draftBlocks) { block in
                        EditorBlockRow(
                            block: block,
                            blocks: $draftBlocks,
                            focusedFieldID: $focusedFieldID,
                            bodyFontSize: bodyFontSize
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 10)
            }
            .editorCopyAllContextMenu(blocks: draftBlocks)
        }
        .inkNavigationBarHidden()
        .onAppear {
            // タイトル入力の廃止前に書かれた日記のタイトルを、本文先頭の見出しとして見えるまま残す。
            entry.mergeTitleIntoBodyMarkdown()
            loadDraftBlocks()
            #if os(macOS)
            installChecklistBackspaceMonitor()
            #endif
        }
        // キーボード入力はタッチとして拾えないため、編集中の本文の変化を無操作タイマーのリセットにする。
        .onChange(of: draftBlocks) {
            resetAutoLockTimer()
        }
        .navigationDestination(isPresented: $notebookListIsPresented) {
            NotebookListPage(entry: entry)
        }
        // テンプレート一覧から戻ったとき、テンプレートの適用で entry 側が書き換わった内容を編集中の本文へ反映する
        // (一覧へ遷移した時点の書きかけは、遷移時の onDisappear が entry へ書き戻し済み)。
        .onChange(of: notebookListIsPresented) {
            if !notebookListIsPresented {
                loadDraftBlocks()
            }
        }
        .onDisappear {
            #if os(macOS)
            removeChecklistBackspaceMonitor()
            #endif
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

    /// entry の本文を編集中のブロック列へ読み直し、末尾に足した空の段落へフォーカスする。
    /// 開いたときとテンプレート適用後の再同期で使う(同じ本文なら何度呼んでも同じ状態になる)。
    /// 末尾の空の段落へフォーカスするのは、日記の続きを書く位置がそこなのに加え、
    /// macOS の入力欄はフォーカスで本文を全選択するため、文字のあるブロックへ当てると
    /// 開いた直後のキー入力がそのブロックを丸ごと置き換えてしまうから(空の段落なら害がない)。
    private func loadDraftBlocks() {
        var blocks = entry.blocks
        // 足した空の段落は、書かないまま離脱すれば書き戻すときに落ちる。
        switch blocks.last {
        case .paragraph(_, let text) where text.isEmpty:
            // 末尾が既に空の段落なら足さない(再同期を冪等にする)。
            break
        default:
            blocks.append(.paragraph(text: ""))
        }
        draftBlocks = blocks
        // 再同期は entry を正とした引き直しのため、この時点のブロック列を未編集の基準に置き直す。
        openedBlocks = draftBlocks
        focusedFieldID = draftBlocks.last?.id
    }

    /// 編集中の本文を entry へ書き戻して保存する。この画面で編集していない・変更がない場合は
    /// 書き戻しを行わない(冪等)。編集していない間に CloudKit 同期などで entry 側が進んでいても、
    /// 開いた時点の古い draft で上書きしないようにする。
    private func commitDraft() {
        if draftBlocks != openedBlocks {
            let bodyMarkdown = Block.markdown(blocks: draftBlocks.withoutEmptyText)
            if entry.bodyMarkdown != bodyMarkdown {
                entry.setBodyMarkdown(bodyMarkdown)
            }
            // 書き戻した時点の状態を新しい未編集の基準にする。バックグラウンド移行の中間保存の後に
            // 開いた時点の内容へ手で戻した場合も、次の書き戻しで「編集」として保存されるようにする。
            openedBlocks = draftBlocks
        }
        try? modelContext.save()
    }

    #if os(macOS)
    /// 空のチェックリスト項目でのバックスペースでチェックボックスを外すためのキー入力監視を始める。
    /// onAppear はテンプレート一覧から戻るときにも呼ばれるため、監視中なら何もしない(冪等)。
    private func installChecklistBackspaceMonitor() {
        if checklistBackspaceMonitor != nil {
            return
        }
        checklistBackspaceMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 51 は delete (バックスペース) のキーコード (Carbon の kVK_Delete)。
            // 修飾キー付き (⌘⌫・⌥⌫ 等) は別の削除操作のため拾わずに通す。
            // 入力中の欄が空のチェックリスト項目のときだけ拾う判定は exitChecklist(emptyItemID:) が行い、
            // 見出し・段落や本文のある項目、日本語入力の変換中 (変換中テキストが項目の本文に入り
            // 空でなくなる) では nil が返ってイベントをそのまま通す。
            if event.keyCode == 51, event.modifierFlags.intersection([.command, .option, .control]).isEmpty,
               let fieldID = focusedFieldID, let paragraphFieldID = draftBlocks.exitChecklist(emptyItemID: fieldID) {
                // リスト脱出の直後は移動先の入力欄がまだ描画されていないため、即時に代入すると
                // first responder が失われて続きの入力が消える。次の runloop で移す。
                DispatchQueue.main.async {
                    focusedFieldID = paragraphFieldID
                }
                return nil
            }
            return event
        }
    }

    /// チェックリスト用のキー入力監視を止める。監視していなければ何もしない(冪等)。
    private func removeChecklistBackspaceMonitor() {
        if let checklistBackspaceMonitor {
            NSEvent.removeMonitor(checklistBackspaceMonitor)
        }
        checklistBackspaceMonitor = nil
    }
    #endif
}
