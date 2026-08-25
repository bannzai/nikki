import SwiftUI

/// 紙色の上に(選択されていれば)背景画像を重ねた全画面背景(#96)。ホーム・エディタ等の主要画面で使う。
struct JournalBackground: View {
    let paperColor: Color
    let backgroundImage: Image?

    var body: some View {
        ZStack {
            paperColor
            if let backgroundImage {
                backgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    // 画像の上でも本文が読めるよう、紙色を重ねて画像の主張を抑える。
                    .overlay(paperColor.opacity(0.55))
            }
        }
        .ignoresSafeArea()
    }
}

struct JournalBackground_Previews: PreviewProvider {
    static var previews: some View {
        JournalBackground(paperColor: .inkPaper, backgroundImage: nil)
    }
}
