import SwiftUI

/// エディタ 執筆中(1i)の静的表現。カタログモードのデザイン検証用。
/// ツールバー・装飾は出さず、2つ目の段落末尾に点滅キャレットを置く。
struct EditorWritingPage: View {
    let entry: JournalEntry

    var body: some View {
        EditorScreenScaffold(caption: editorDateText(date: entry.date), onDismiss: {}) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    let paragraphs = entry.blocks.paragraphTexts
                    Text(entry.title)
                        .font(.inkEntryTitle)
                        .lineSpacing(inkLineSpacing(fontSize: 22, multiplier: 1.6))
                        .foregroundStyle(Color.ink)
                        .padding(.bottom, 14)

                    // SwiftUI の lineSpacing は CSS の line-height と違い段落端に half-leading を
                    // 付けないため、行間(2.05)相当の余白を段落の上下に補ってから段落マージン 12pt を足す。
                    // これで段落間ギャップが行内の行間より広くなり、見本どおり段落の切れ目が読める。
                    let paragraphHalfLeading = inkLineSpacing(fontSize: 15, multiplier: 2.05) / 2

                    if let first = paragraphs.first {
                        EditorParagraphBlock(text: first)
                            .padding(.vertical, paragraphHalfLeading)
                    }
                    if paragraphs.count > 1 {
                        EditorWritingParagraph(text: paragraphs[1])
                            .padding(.vertical, paragraphHalfLeading)
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 10)
            }
        }
    }
}
