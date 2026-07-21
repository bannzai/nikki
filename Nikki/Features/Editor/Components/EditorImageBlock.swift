import SwiftUI

/// img プレースホルダ。45°ストライプ地 + mono ラベル。
struct EditorImageBlock: View {
    let label: String

    var body: some View {
        ZStack {
            EditorDiagonalStripes()
            Text("img: \(label)")
                .font(InkTypography.mono(11))
                .foregroundStyle(InkColors.labelGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(InkColors.paper.opacity(0.9))
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
