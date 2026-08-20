import SwiftUI

/// セクション見出し(紙の色 / 背景画像)のスタイル。
struct ThemeSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.ink(12, .bold))
            .foregroundStyle(Color.inkTextTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ThemeSectionLabel_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSectionLabel(text: "Paper color")
            .padding()
            .background(Color.inkPaper)
    }
}
