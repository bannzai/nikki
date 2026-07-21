import SwiftUI

/// チェックリスト。完了項目は打ち消し線+灰。
struct EditorChecklistBlock: View {
    let items: [ChecklistItem]
    var boxSize: CGFloat = 19
    var fontSize: CGFloat = 15
    var rowSpacing: CGFloat = 10
    var boxSpacing: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(items) { item in
                HStack(spacing: boxSpacing) {
                    EditorCheckbox(done: item.done, size: boxSize)
                    Text(item.text)
                        .font(InkTypography.font(fontSize, .regular))
                        .foregroundStyle(item.done ? InkColors.textTertiary : InkColors.ink)
                        .strikethrough(item.done, color: InkColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
