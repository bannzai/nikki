import SwiftUI

/// details ブロック。枠線カード + ▶ + summary。開いている間はシェブロンを下向きにする。
struct EditorDetailsBlock: View {
    let summary: String
    // 見本(1j)の details はたたんだ状態で描かれており、カタログの静的表示もその見た目のため既定にする。
    /// たたんでいるかどうか。markdown の open 属性の裏返しで、開いている間は下向きのシェブロンにする。
    var isCollapsed: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isCollapsed ? InkIcons.chevronRight : InkIcons.chevronDown)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.inkTextSecondary)
            Text("details — \(summary)")
                .font(.ink(14, .regular))
                .foregroundStyle(Color.inkTextSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.12), lineWidth: 1)
        )
    }
}

struct EditorDetailsBlock_Previews: PreviewProvider {
    static var previews: some View {
        EditorDetailsBlock(summary: "病院メモ(たたんでおく)")
            .padding()
            .background(Color.inkPaper)
    }
}
