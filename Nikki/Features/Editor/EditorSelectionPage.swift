import SwiftUI

/// エディタ 選択ツールバー(1j)。選択中の見出しにハイライト+ハンドルを付け、
/// その 52px 上にフローティングツールバーを浮かせる。他ブロック例も並べる。
struct EditorSelectionPage: View {
    let entry: JournalEntry

    var body: some View {
        EditorScreenScaffold(caption: EditorDateText.caption(for: entry.date), onDismiss: {}) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // パースの二重計算を避けるため、body 内でローカル let に束縛して使い回す。
                    let blocks = entry.blocks
                    Text(entry.title)
                        .font(.inkEntryTitle)
                        .lineSpacing(inkLineSpacing(fontSize: 22, multiplier: 1.6))
                        .foregroundStyle(Color.ink)
                        .padding(.bottom, 14)

                    if let firstParagraph = blocks.paragraphTexts.first {
                        EditorParagraphBlock(text: firstParagraph)
                    }

                    if let selectedHeading = blocks.headingTexts.first {
                        EditorSelectedHeading(text: selectedHeading)
                            .padding(.top, 26)
                            .overlay(alignment: .topLeading) {
                                EditorSelectionToolbar()
                                    .fixedSize()
                                    .offset(y: -52)
                            }
                    }

                    EditorChecklistBlock(items: blocks.firstChecklistItems)
                        .padding(.top, 16)

                    if let label = blocks.firstImageLabel {
                        EditorImageBlock(label: label)
                            .padding(.top, 22)
                    }

                    if let summary = blocks.firstDetailsSummary {
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
