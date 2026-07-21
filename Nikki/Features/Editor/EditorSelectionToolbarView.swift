import SwiftUI

/// エディタ 選択ツールバー(1j)。選択中の見出しにハイライト+ハンドルを付け、
/// その 52px 上にフローティングツールバーを浮かせる。他ブロック例も並べる。
struct EditorSelectionToolbarView: View {
    let entry: JournalEntry

    init(entry: JournalEntry = SampleData.sampleEntry) {
        self.entry = entry
    }

    var body: some View {
        EditorScreenScaffold(caption: EditorDateText.caption(for: entry.date)) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    let firstParagraph = EditorBlockPicker.paragraphTexts(entry).first
                    let selectedHeading = EditorBlockPicker.headingTexts(entry).first
                    Text(entry.title)
                        .font(InkTypography.entryTitle)
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 22, multiplier: 1.6))
                        .foregroundStyle(InkColors.ink)
                        .padding(.bottom, 14)

                    if let firstParagraph {
                        EditorParagraphBlock(text: firstParagraph)
                    }

                    if let selectedHeading {
                        EditorSelectedHeading(text: selectedHeading)
                            .padding(.top, 26)
                            .overlay(alignment: .topLeading) {
                                EditorSelectionToolbar()
                                    .fixedSize()
                                    .offset(y: -52)
                            }
                    }

                    EditorChecklistBlock(items: EditorBlockPicker.firstChecklist(entry))
                        .padding(.top, 16)

                    if let label = EditorBlockPicker.firstImageLabel(entry) {
                        EditorImageBlock(label: label)
                            .padding(.top, 22)
                    }

                    if let summary = EditorBlockPicker.firstDetailsSummary(entry) {
                        EditorDetailsBlock(summary: summary)
                            .padding(.top, 18)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 10)
            }
        }
    }
}
