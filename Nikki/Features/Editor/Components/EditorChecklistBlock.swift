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
                // チェック操作は静的表現のままのため、isOn は定数で渡す。
                Toggle(isOn: .constant(item.done)) {
                    Text(item.text)
                        .font(.ink(fontSize, .regular))
                        .foregroundStyle(item.done ? Color.inkTextTertiary : Color.ink)
                        .strikethrough(item.done, color: Color.inkTextTertiary)
                }
                .toggleStyle(EditorCheckboxToggleStyle(boxSize: boxSize, boxSpacing: boxSpacing))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
