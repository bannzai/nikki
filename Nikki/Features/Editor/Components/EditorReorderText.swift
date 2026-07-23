import SwiftUI

/// 並び替え行の本文テキスト(14px・濃灰)。
struct EditorReorderText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.ink(14, .regular))
            .lineSpacing(inkLineSpacing(fontSize: 14, multiplier: 1.95))
            .foregroundStyle(EditorPalette.inkGray)
            .fixedSize(horizontal: false, vertical: true)
    }
}
