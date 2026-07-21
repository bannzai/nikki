import SwiftUI

/// 6点ドラッグハンドル(2列×3行)。掴んでいる行は墨、他は微灰。
struct EditorDragHandle: View {
    var active: Bool

    var body: some View {
        let color = active ? InkColors.ink : InkColors.textQuaternary
        VStack(spacing: 2.3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 1.8) {
                    EditorDragDot(color: color)
                    EditorDragDot(color: color)
                }
            }
        }
    }
}

/// ドラッグハンドルの点1つ。
struct EditorDragDot: View {
    let color: Color

    var body: some View {
        Circle().fill(color).frame(width: 3.2, height: 3.2)
    }
}
