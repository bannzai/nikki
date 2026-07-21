import SwiftUI

/// エディタ 執筆中(1i)。ツールバー・装飾は出さず、2つ目の段落末尾に点滅キャレットを置く。
struct EditorPage: View {
    var entry: JournalEntry = SampleData.sampleEntry

    var body: some View {
        EditorScreenScaffold(caption: EditorDateText.caption(for: entry.date)) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    let paragraphs = EditorBlockPicker.paragraphTexts(entry)
                    Text(entry.title)
                        .font(InkTypography.entryTitle)
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 22, multiplier: 1.6))
                        .foregroundStyle(InkColors.ink)
                        .padding(.bottom, 14)

                    // SwiftUI の lineSpacing は CSS の line-height と違い段落端に half-leading を
                    // 付けないため、行間(2.05)相当の余白を段落の上下に補ってから段落マージン 12pt を足す。
                    // これで段落間ギャップが行内の行間より広くなり、見本どおり段落の切れ目が読める。
                    let paragraphHalfLeading = InkTypography.body.lineSpacing / 2

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
