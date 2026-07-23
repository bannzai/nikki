import SwiftUI

/// img プレースホルダ。45°ストライプ地 + mono ラベル。
struct EditorImageBlock: View {
    let label: String

    var body: some View {
        ZStack {
            EditorDiagonalStripes()
            Text("img: \(label)")
                .font(.inkMono(11))
                .foregroundStyle(Color.inkLabelGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.inkPaper.opacity(0.9))
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
