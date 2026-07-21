import SwiftUI

/// 本文段落。15px・行間2.05。
struct EditorParagraphBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .inkTextStyle(InkTypography.body)
            .foregroundStyle(InkColors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
