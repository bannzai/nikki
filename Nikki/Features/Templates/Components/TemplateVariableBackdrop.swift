import SwiftUI

/// 背後の画面をディムした地。#DBDAD5 の上に半透明の紙色を重ね、ぼかした本文の見立てとして
/// スケルトンバーを 1 本置く。
struct TemplateVariableBackdrop: View {
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.inkDisabledBackground
            paperColor.opacity(0.5)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0xDDDCD7))
                .frame(width: 170, height: 16)
                .padding(.top, 90)
                .padding(.leading, 24)
        }
    }
}

struct TemplateVariableBackdrop_Previews: PreviewProvider {
    static var previews: some View {
        TemplateVariableBackdrop()
    }
}
