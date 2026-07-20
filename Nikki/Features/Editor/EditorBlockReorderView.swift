import SwiftUI

/// エディタ ブロック並び替え(1k)。各ブロック左に6点ハンドルを置き、
/// 「買ったもの」カードがドラッグ中(浮き上がり)、その上に挿入インジケータラインを描く静的表現。
struct EditorBlockReorderView: View {
    let entry: JournalEntry

    init(entry: JournalEntry = SampleData.sampleEntry) {
        self.entry = entry
    }

    private var paragraphs: [String] { EditorBlockPicker.paragraphTexts(entry) }
    private var headings: [String] { EditorBlockPicker.headingTexts(entry) }

    var body: some View {
        EditorScreenScaffold(caption: "並び替え — 指を離すと確定") {
            VStack(alignment: .leading, spacing: 10) {
                staticRow {
                    Text(entry.title)
                        .font(InkTypography.font(20, .bold))
                        .foregroundStyle(InkColors.ink)
                }

                if let first = paragraphs.first {
                    staticRow {
                        reorderText(first)
                    }
                }

                insertionIndicator

                draggingCard

                if headings.count > 1 {
                    staticRow {
                        Text(headings[1])
                            .font(InkTypography.font(16, .bold))
                            .foregroundStyle(EditorPalette.inkGray)
                    }
                }

                if let last = paragraphs.last, paragraphs.count > 1 {
                    staticRow {
                        reorderText(last)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
    }

    /// 非ドラッグ行(半透明の白カード + 灰ハンドル)。
    private func staticRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        reorderRow(active: false, content: content)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(InkColors.surface.opacity(0.6))
            )
    }

    private func reorderRow<Content: View>(active: Bool, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            EditorDragHandle(active: active)
                .padding(.top, 5)
            content()
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private func reorderText(_ text: String) -> some View {
        Text(text)
            .font(InkTypography.font(14, .regular))
            .lineSpacing(InkTypography.lineSpacing(fontSize: 14, multiplier: 1.95))
            .foregroundStyle(EditorPalette.inkGray)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 挿入予定位置を示す 2.5px の墨インジケータライン。
    private var insertionIndicator: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(InkColors.ink)
            .frame(height: 2.5)
            .padding(.horizontal, 6)
    }

    /// ドラッグ中のカード(「買ったもの」見出し+チェックリスト)。浮き上がり演出付き。
    private var draggingCard: some View {
        reorderRow(active: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(headings.first ?? "")
                    .font(InkTypography.font(16, .bold))
                    .foregroundStyle(InkColors.ink)
                EditorChecklistBlock(
                    items: EditorBlockPicker.firstChecklist(entry),
                    boxSize: 17,
                    fontSize: 14,
                    rowSpacing: 7,
                    boxSpacing: 10
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(InkColors.surface)
        )
        .shadow(color: InkColors.ink.opacity(0.22), radius: 22, x: 0, y: 18)
        .rotationEffect(.degrees(-1.2))
        .scaleEffect(1.02)
    }
}
