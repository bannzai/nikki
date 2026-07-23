import SwiftUI

/// 本文段落。15px・行間2.05。
struct EditorParagraphBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.ink(15))
            .lineSpacing(inkLineSpacing(fontSize: 15, multiplier: 2.05))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct EditorParagraphBlock_Previews: PreviewProvider {
    static var previews: some View {
        EditorParagraphBlock(text: "朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。")
            .padding()
            .background(Color.inkPaper)
    }
}
