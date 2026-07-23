import SwiftUI

/// details ブロック。枠線カード + ▶ + summary。
struct EditorDetailsBlock: View {
    let summary: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: InkIcons.chevronRight)
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
