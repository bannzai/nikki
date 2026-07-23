import SwiftUI

/// 選択中の見出し。ハイライト背景 + 両端のセレクションハンドル(縦線+円)。
struct EditorSelectedHeading: View {
    let text: String
    var level: Int = 2

    var body: some View {
        Text(text)
            .font(EditorHeadingFont.font(for: level))
            .foregroundStyle(Color.ink)
            .padding(.vertical, 2)
            .background(Color.inkSelectionHighlight)
            .overlay(alignment: .leading) {
                EditorSelectionHandle(circleAlignment: .top, circleOffsetY: -8)
                    .offset(x: -1)
            }
            .overlay(alignment: .trailing) {
                EditorSelectionHandle(circleAlignment: .bottom, circleOffsetY: 8)
                    .offset(x: 1)
            }
    }
}

/// セレクションハンドル(縦2px線 + 11px円)。
struct EditorSelectionHandle: View {
    /// 円を線のどちらの端に付けるか。
    let circleAlignment: Alignment
    /// 円を線の端からずらす量。
    let circleOffsetY: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.ink)
            .frame(width: 2)
            .overlay(alignment: circleAlignment) {
                Circle()
                    .fill(Color.ink)
                    .frame(width: 11, height: 11)
                    .offset(y: circleOffsetY)
            }
    }
}
