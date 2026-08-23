import SwiftUI

/// エディタ本文の1ブロック。ブロックの種類ごとに、文字を書き換えるもの(見出し・段落・チェックリスト)は
/// 入力欄へ、img はプレースホルダ表示へ、details は開閉するカードへ振り分ける。
struct EditorBlockRow: View {
    /// 描画するブロック。編集中のブロック列から取り出した現在の値で、書き戻し先は blocks の方。
    let block: Block
    /// 編集中の本文ブロック列。ブロックの追加・削除・種類の変更もこの配列を書き換えて反映する。
    @Binding var blocks: [Block]
    @FocusState.Binding var focusedFieldID: UUID?
    /// 段落・チェックリストの文字の大きさ。設定「文字の大きさ」を反映する。
    let bodyFontSize: CGFloat

    var body: some View {
        switch block {
        case .heading, .paragraph:
            EditorTextBlockField(
                block: block,
                blocks: $blocks,
                focusedFieldID: $focusedFieldID,
                bodyFontSize: bodyFontSize
            )
        case .checklist:
            EditorChecklistField(
                block: block,
                blocks: $blocks,
                focusedFieldID: $focusedFieldID,
                bodyFontSize: bodyFontSize
            )
        case .image(_, let label):
            EditorImageBlock(label: label)
        case .details(_, let summary, let isCollapsed):
            Button {
                blocks.toggleDetails(blockID: block.id)
            } label: {
                EditorDetailsBlock(summary: summary, isCollapsed: isCollapsed)
            }
            .buttonStyle(.plain)
        }
    }
}
