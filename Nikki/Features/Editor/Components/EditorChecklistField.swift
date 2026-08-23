import SwiftUI

/// 編集できるチェックリスト。見た目はカタログの EditorChecklistBlock と同じ(完了項目は打ち消し線+灰)で、
/// チェックボックスのタップで完了を切り替え、項目の文字はその場で書き換えられる。
struct EditorChecklistField: View {
    /// 描画するチェックリスト。編集中のブロック列から取り出した現在の値で、書き戻し先は blocks の方。
    let block: Block
    /// 編集中の本文ブロック列。
    @Binding var blocks: [Block]
    @FocusState.Binding var focusedFieldID: UUID?
    /// 項目の文字の大きさ。設定「文字の大きさ」を反映する。
    let bodyFontSize: CGFloat

    var body: some View {
        // 行の間隔とチェックボックスの間隔はカタログの EditorChecklistBlock に合わせる。
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                HStack(spacing: 11) {
                    // EditorCheckboxToggleStyle はラベルごと Button に包むため、ラベルに入力欄を置くと
                    // 文字をタップしても編集に入れない。チェックボックスだけをこのスタイルで描き、
                    // ボックスとラベルの間隔はこの HStack が持つ。
                    Toggle(isOn: doneBinding(itemID: item.id)) {
                        EmptyView()
                    }
                    .toggleStyle(EditorCheckboxToggleStyle(boxSpacing: 0))
                    // ラベルが EmptyView のため、VoiceOver が項目を区別できるよう項目の本文を名前にする。
                    .accessibilityLabel(item.text)

                    // 完了した項目は入力欄ではなくカタログと同じ静的な文字にする。TextField は
                    // 打ち消し線を描画せず、macOS では完了の切り替え直後に文字色も更新されないため
                    // (1操作遅れで反映される)、完了の見た目は Text で描画する。文字を直したいときは
                    // チェックを外してから編集する。
                    // ただし本文が空の項目(「- [x] 」の変換直後)と入力中の項目は、入力欄が無いと項目名を
                    // 書けない・入力の途中で欄が消えるため、完了でも TextField のまま出す。
                    if item.done && !item.text.isEmpty && focusedFieldID != item.id {
                        Text(item.text)
                            .font(.ink(bodyFontSize, .regular))
                            .foregroundStyle(Color.inkTextTertiary)
                            .strikethrough(color: Color.inkTextTertiary)
                    } else {
                        TextField("", text: textBinding(itemID: item.id), axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.ink(bodyFontSize, .regular))
                            .foregroundStyle(item.done ? Color.inkTextTertiary : Color.ink)
                            .focused($focusedFieldID, equals: item.id)
                            // Return が改行ではなく確定として届くプラットフォームでは、この経路で次の項目を用意する
                            // (改行として届くプラットフォームでは textBinding 側が改行で項目を分ける)。
                            .onSubmit {
                                if let fieldID = blocks.insertChecklistItem(afterItemID: item.id) {
                                    focusedFieldID = fieldID
                                }
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 描画するチェックリストの項目。
    private var items: [ChecklistItem] {
        if case .checklist(_, let items) = block {
            return items
        }
        return []
    }

    /// チェックボックスと編集中のブロック列をつなぐ。
    private func doneBinding(itemID: UUID) -> Binding<Bool> {
        Binding(
            get: { items.first { $0.id == itemID }?.done ?? false },
            set: { done in blocks.setChecklistItemDone(itemID: itemID, done: done) }
        )
    }

    /// 項目の入力欄と編集中のブロック列をつなぐ。書き込み先を @State のブロック列だけにして、
    /// キーストロークごとに日記(@Model)へ触れない(issue #86)。
    private func textBinding(itemID: UUID) -> Binding<String> {
        Binding(
            get: { items.first { $0.id == itemID }?.text ?? "" },
            set: { text in
                if let fieldID = blocks.updateChecklistItem(itemID: itemID, text: text) {
                    // 項目の分割・リスト脱出の直後は移動先の入力欄がまだ描画されていないため、即時に代入すると
                    // macOS で first responder が失われて続きの入力が消える。次の runloop で移す。
                    DispatchQueue.main.async {
                        focusedFieldID = fieldID
                    }
                }
            }
        )
    }
}
