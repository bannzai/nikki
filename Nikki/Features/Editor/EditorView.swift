import SwiftUI

/// エディタ 執筆中(1i)。ツールバー・装飾は出さず、2つ目の段落末尾に点滅キャレットを置く。
struct EditorView: View {
    let entry: JournalEntry

    init(entry: JournalEntry = SampleData.sampleEntry) {
        self.entry = entry
    }

    private var paragraphs: [String] { EditorBlockPicker.paragraphTexts(entry) }

    var body: some View {
        EditorScreenScaffold(caption: EditorDateText.caption(for: entry.date)) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.title)
                        .font(InkTypography.entryTitle)
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 22, multiplier: 1.6))
                        .foregroundStyle(InkColors.ink)
                        .padding(.bottom, 14)

                    if let first = paragraphs.first {
                        EditorParagraphBlock(text: first)
                    }
                    if paragraphs.count > 1 {
                        EditorWritingParagraph(text: paragraphs[1])
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 10)
            }
        }
    }
}
