import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

/// ブロック行の frame・ドラッグ位置を同じ原点で扱うための座標空間の名前。
/// ジェスチャの nonisolated な closure からも参照するため nonisolated にする。
private nonisolated let blockReorderSpaceName = "editorBlockReorder"

/// ドラッグ&ドロップ並び替えのドラッグ中状態。掴んだブロックと指先の現在位置を持つ。
struct EditorBlockDrag {
    /// 掴んでいるブロックの id。
    let blockID: UUID
    /// ドラッグ開始位置からの縦の移動量。掴んだ行を指先へ追従させる。
    var translationHeight: CGFloat
    /// blockReorderSpaceName 座標空間での指先の縦位置。挿入先の計算に使う。
    var locationY: CGFloat
}

/// エディタ。本文をブロック単位で装飾表示しながら編集し、画面を離れるときに日記へ書き戻す。
/// 編集中は draftBlocks(@State)が唯一の編集先で、entry(@Model)へは
/// 離脱・バックグラウンド移行・アプリ終了のタイミングで書き戻す(理由は draftBlocks のコメント参照)。
/// タイトル入力は持たない。日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめを
/// わかりにくくしていたため、開いたら本文へフォーカスしてすぐ書ける形にする。
/// 過去に入力されたタイトルは、開いたときに本文先頭の見出しへ移して見えるまま残す。
/// 新規日記は既定のテンプレートの内容で書きはじまるため選択は求めず、変えたい人だけが
/// ナビ右端の「テンプレート」からテンプレート一覧(1l)で選び直せる(issue #82)。
/// 選択ツールバー(1j)は静的表現のまま。ブロックの並び替えは各ブロック左の6点ハンドルの
/// ドラッグ&ドロップでこの画面が行う(ビジュアルは見本(1k)の EditorReorderPage に合わせる)。
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

    /// ドラッグ&ドロップ並び替えのドラッグ中状態。システムにジェスチャが中断されても
    /// 掴んだ行が浮いたまま残らないよう、自動で nil に戻る @GestureState で持つ。
    @GestureState var blockDrag: EditorBlockDrag? = nil

    /// 各ブロック行の frame(blockReorderSpaceName 座標空間)。挿入先の計算に使う。
    @State var blockRowFrames: [UUID: CGRect] = [:]

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
            ScrollView(.vertical, showsIndicators: false) {
                // ブロックの間隔は、見本(1j)が並べるブロック例の間隔に合わせる。
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(draftBlocks) { block in
                        // ハンドル(leading 6 + 幅16 + 間隔6)で本文の書き出し位置が
                        // ハンドル導入前の horizontal padding 28 と揃うようにする。
                        HStack(alignment: .top, spacing: 6) {
                            if block.id == draftBlocks.last?.id && block.editableText?.isEmpty == true {
                                // 続きを書くために自動で足した末尾の空の段落は、掴める内容が無く
                                // 書き戻しでも落ちるため、ハンドルを出さず位置だけ揃える。
                                Color.clear.frame(width: 16, height: 20)
                            } else {
                                EditorDragHandle(active: blockDrag?.blockID == block.id)
                                    // 6点の見た目(幅約8pt)のままだと掴みにくいため、周囲を含めて当たり判定にする。
                                    .frame(width: 16, height: 20)
                                    .contentShape(Rectangle())
                                    .gesture(reorderGesture(block: block))
                                    // 右クリックはドラッグ(主ボタン)と競合しない。理由は modifier の定義コメント参照。
                                    .editorBlockCopyContextMenuOnMac(block: block, blocks: draftBlocks)
                            }
                            EditorBlockRow(
                                block: block,
                                blocks: $draftBlocks,
                                focusedFieldID: $focusedFieldID,
                                bodyFontSize: bodyFontSize
                            )
                        }
                        .background {
                            // 掴んでいる行だけ、見本(1k)のドラッグ中カードと同じ浮き上がりの地と影を付ける。
                            // レイアウトは変えず、行の外へ少しはみ出してカードに見せる。
                            if blockDrag?.blockID == block.id {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.inkSurface)
                                    .padding(-10)
                                    .shadow(color: Color.ink.opacity(0.22), radius: 22, x: 0, y: 18)
                            }
                        }
                        .rotationEffect(.degrees(blockDrag?.blockID == block.id ? -1.2 : 0))
                        .scaleEffect(blockDrag?.blockID == block.id ? 1.02 : 1)
                        .offset(y: blockDrag?.blockID == block.id ? (blockDrag?.translationHeight ?? 0) : 0)
                        .zIndex(blockDrag?.blockID == block.id ? 1 : 0)
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .named(blockReorderSpaceName))
                        } action: { frame in
                            blockRowFrames[block.id] = frame
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let blockDrag, let indicatorY = insertionIndicatorY(
                        draggingBlockID: blockDrag.blockID,
                        locationY: blockDrag.locationY
                    ) {
                        EditorInsertionIndicator()
                            .offset(y: indicatorY)
                    }
                }
                .coordinateSpace(name: blockReorderSpaceName)
                .padding(.leading, 6)
                .padding(.trailing, 28)
                .padding(.top, 10)
            }
            .editorCopyAllContextMenu(blocks: draftBlocks)
            // ドラッグ中にスクロールが同時に走って挿入位置がずれないようにする。
            .scrollDisabled(blockDrag != nil)
        }
        .inkNavigationBarHidden()
        .onAppear {
            // タイトル入力の廃止前に書かれた日記のタイトルを、本文先頭の見出しとして見えるまま残す。
            entry.mergeTitleIntoBodyMarkdown()
            loadDraftBlocks()
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

    #if os(iOS)
    /// ブロックを並び替えるドラッグ。ScrollView がスクロールとしてタッチを奪い
    /// 子の DragGesture を打ち切るため、長押しの成立を待ってからドラッグを追跡する。
    /// 0.2秒は、スクロールと区別できる最短の長押しとして選んだ(長いほど並び替えの開始が待たされる)。
    private func reorderGesture(block: Block) -> some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(blockReorderSpaceName)))
            .updating($blockDrag) { value, state, _ in
                if case .second(true, let drag) = value {
                    state = EditorBlockDrag(
                        blockID: block.id,
                        translationHeight: drag?.translation.height ?? 0,
                        // 長押しが成立してまだ動かしていない間も、行の現在位置で浮き上がりと
                        // インジケータを出し、掴めたことが伝わるようにする。
                        locationY: drag?.location.y ?? blockRowFrames[block.id]?.midY ?? 0
                    )
                }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value {
                    dropBlock(blockID: block.id, locationY: drag.location.y)
                }
            }
    }
    #else
    /// ブロックを並び替えるドラッグ。macOS のマウスドラッグは ScrollView のスクロールと競合しないため、
    /// 長押しを挟まずそのまま追跡する。
    private func reorderGesture(block: Block) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named(blockReorderSpaceName))
            .updating($blockDrag) { drag, state, _ in
                state = EditorBlockDrag(
                    blockID: block.id,
                    translationHeight: drag.translation.height,
                    locationY: drag.location.y
                )
            }
            .onEnded { drag in
                dropBlock(blockID: block.id, locationY: drag.location.y)
            }
    }
    #endif

    /// ドロップしたブロックを挿入先へ動かす。並びが変わるアニメーションと一緒に反映する。
    private func dropBlock(blockID: UUID, locationY: CGFloat) {
        withAnimation(.spring(duration: 0.3)) {
            draftBlocks.moveBlock(
                blockID: blockID,
                insertionIndex: insertionIndex(draggingBlockID: blockID, locationY: locationY)
            )
        }
    }

    /// ドラッグ位置に対応する挿入先。掴んでいるブロックを除いた行のうち、
    /// 行の中央が指先より上にある行の数(= その行たちの直後に入る)。
    private func insertionIndex(draggingBlockID: UUID, locationY: CGFloat) -> Int {
        draftBlocks
            .filter { $0.id != draggingBlockID }
            .count { blockRowFrames[$0.id].map { $0.midY < locationY } ?? false }
    }

    /// 挿入インジケータラインの縦位置(blockReorderSpaceName 座標空間)。挿入先の前後の行の
    /// ちょうど間(端はブロック間隔の半分だけ外側)に置く。行の frame が未計測なら出さない。
    private func insertionIndicatorY(draggingBlockID: UUID, locationY: CGFloat) -> CGFloat? {
        let remainingBlocks = draftBlocks.filter { $0.id != draggingBlockID }
        let remainingFrames = remainingBlocks.compactMap { blockRowFrames[$0.id] }
        if remainingFrames.count != remainingBlocks.count || remainingFrames.isEmpty {
            return nil
        }
        // ブロック間隔16の半分だけ行の外側に置き、行と重ならず隙間の中央に見えるようにする。
        let index = insertionIndex(draggingBlockID: draggingBlockID, locationY: locationY)
        if index == 0 {
            return remainingFrames[0].minY - 8
        }
        if index == remainingFrames.count {
            return remainingFrames[remainingFrames.count - 1].maxY + 8
        }
        return (remainingFrames[index - 1].maxY + remainingFrames[index].minY) / 2
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
}
