import SwiftUI

/// ドラッグ中のカード(「買ったもの」見出し+チェックリスト)。浮き上がり演出付き。
struct EditorDraggingCard: View {
    let entry: JournalEntry

    var body: some View {
        EditorReorderRow(active: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.blocks.headingTexts.first ?? "")
                    .font(.ink(16, .bold))
                    .foregroundStyle(Color.ink)
                EditorChecklistBlock(
                    items: entry.blocks.firstChecklistItems,
                    boxSize: 17,
                    fontSize: 14,
                    rowSpacing: 7,
                    boxSpacing: 10
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.inkSurface)
        )
        .shadow(color: Color.ink.opacity(0.22), radius: 22, x: 0, y: 18)
        .rotationEffect(.degrees(-1.2))
        .scaleEffect(1.02)
    }
}

struct EditorDraggingCard_Previews: PreviewProvider {
    static var previews: some View {
        EditorDraggingCard(entry: SampleData.sampleEntry)
            .padding()
            .background(Color.inkPaper)
    }
}
