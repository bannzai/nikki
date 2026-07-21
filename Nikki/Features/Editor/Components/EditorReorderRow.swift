import SwiftUI

/// 並び替え画面の1行(6点ハンドル + 内容)。active=false は非ドラッグ行として
/// 半透明の白カード地が付き、active=true は地を持たず呼び出し側が装飾する。
struct EditorReorderRow<Content: View>: View {
    var active: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            EditorDragHandle(active: active)
                .padding(.top, 5)
            content
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? Color.clear : InkColors.surface.opacity(0.6))
        )
    }
}
