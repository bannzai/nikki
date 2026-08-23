import SwiftUI

/// 見出し・段落の入力欄。記法(#)は画面に出さず、見出しは見出しの書体・段落は本文の書体で
/// 文字だけを編集できるようにする(見出しレベルはブロックが持つ)。
struct EditorTextBlockField: View {
    /// 描画する見出し・段落。編集中のブロック列から取り出した現在の値で、書き戻し先は blocks の方。
    let block: Block
    /// 編集中の本文ブロック列。
    @Binding var blocks: [Block]
    @FocusState.Binding var focusedFieldID: UUID?
    /// 段落の文字の大きさ。設定「文字の大きさ」を反映する(見出しは見出しの書体で固定)。
    let bodyFontSize: CGFloat

    var body: some View {
        TextField("", text: editableText, prompt: prompt, axis: .vertical)
            .textFieldStyle(.plain)
            .font(font)
            .lineSpacing(lineSpacing)
            .foregroundStyle(Color.ink)
            .focused($focusedFieldID, equals: block.id)
            // Return が改行ではなく確定として届くプラットフォームでは、この経路で次の段落を用意する
            // (改行として届くプラットフォームでは editableText 側が改行でブロックを分ける)。
            .onSubmit {
                if let fieldID = blocks.insertParagraph(afterBlockID: block.id) {
                    focusedFieldID = fieldID
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 入力欄と編集中のブロック列をつなぐ。書き込み先を @State のブロック列だけにして、
    /// キーストロークごとに日記(@Model)へ触れない(issue #86)。
    private var editableText: Binding<String> {
        Binding(
            get: { block.editableText ?? "" },
            set: { text in
                if let fieldID = blocks.updateEditableText(blockID: block.id, text: text) {
                    // 記法変換・分割の直後は移動先の入力欄がまだ描画されていないため、即時に代入すると
                    // macOS で first responder が失われて続きの入力が消える。次の runloop で移す。
                    DispatchQueue.main.async {
                        focusedFieldID = fieldID
                    }
                }
            }
        )
    }

    /// 本文をまだ何も書いていないときだけ出す、書きはじめの案内。
    private var prompt: Text? {
        if blocks.count == 1, case .paragraph(_, let text) = block, text.isEmpty {
            return Text("Write here…")
                .font(.ink(bodyFontSize))
                .foregroundStyle(Color.inkTextTertiary)
        }
        return nil
    }

    /// 見出しは見出しの書体、段落は設定「文字の大きさ」を反映した本文の書体。
    private var font: Font {
        if case .heading(_, let level, _) = block {
            return EditorHeadingFont.font(for: level)
        }
        return .ink(bodyFontSize)
    }

    /// 段落は見本(1i)の本文の行間。見出しは行間を広げず見出しの書体のまま出す。
    private var lineSpacing: CGFloat {
        if case .heading = block {
            return 0
        }
        return inkLineSpacing(fontSize: bodyFontSize, multiplier: 2.05)
    }
}
