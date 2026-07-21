import SwiftUI

/// 背後の画面をディムした地。#DBDAD5 の上に半透明の紙色を重ね、ぼかした本文の見立てとして
/// スケルトンバーを 1 本置く。
struct TemplateVariableBackdrop: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            InkColors.disabledBackground
            InkColors.paper.opacity(0.5)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0xDDDCD7))
                .frame(width: 170, height: 16)
                .padding(.top, 90)
                .padding(.leading, 24)
        }
    }
}
