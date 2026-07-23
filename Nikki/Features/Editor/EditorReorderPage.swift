import SwiftUI

/// エディタ ブロック並び替え(1k)。各ブロック左に6点ハンドルを置き、
/// 「買ったもの」カードがドラッグ中(浮き上がり)、その上に挿入インジケータラインを描く静的表現。
struct EditorReorderPage: View {
    let entry: JournalEntry

    var body: some View {
        EditorScreenScaffold(caption: "並び替え — 指を離すと確定", onDismiss: {}) {
            VStack(alignment: .leading, spacing: 10) {
                let paragraphs = EditorBlockPicker.paragraphTexts(entry)
                let headings = EditorBlockPicker.headingTexts(entry)
                EditorReorderRow {
                    Text(entry.title)
                        .font(.ink(20, .bold))
                        .foregroundStyle(Color.ink)
                }

                if let first = paragraphs.first {
                    EditorReorderRow {
                        EditorReorderText(text: first)
                    }
                }

                EditorInsertionIndicator()

                EditorDraggingCard(entry: entry)

                if headings.count > 1 {
                    EditorReorderRow {
                        Text(headings[1])
                            .font(.ink(16, .bold))
                            .foregroundStyle(EditorPalette.inkGray)
                    }
                }

                if let last = paragraphs.last, paragraphs.count > 1 {
                    EditorReorderRow {
                        EditorReorderText(text: last)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
    }
}
