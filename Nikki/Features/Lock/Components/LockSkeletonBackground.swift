import SwiftUI

/// 日記本文をスケルトン化し blur(7)+opacity(.55) で敷いた背景。中身を守る演出。
struct LockSkeletonBackground: View {
    /// スケルトンの見出し風バーの色(#C9C8C3)。日記のタイトル行を抽象化した矩形に使う。
    private static let titleColor = Color(hex: 0xC9C8C3)
    /// スケルトンの本文風バーの色(#DDDCD7)。日記の本文行を抽象化した矩形に使う。
    private static let bodyColor = Color(hex: 0xDDDCD7)

    /// 背景スケルトンのバー定義。幅は本文エリア(横パディングを除いた幅)に対する比率で指定する。
    private static let bars: [LockSkeletonBar] = [
        LockSkeletonBar(widthRatio: 0.56, height: 20, color: titleColor),
        LockSkeletonBar(widthRatio: 0.92, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.88, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.95, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.60, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.40, height: 16, color: titleColor, topMargin: 14),
        LockSkeletonBar(widthRatio: 0.90, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.84, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.93, height: 12, color: bodyColor),
        LockSkeletonBar(widthRatio: 0.52, height: 12, color: bodyColor),
    ]

    var body: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width - 64  // 横 32px パディング × 2
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(Self.bars.enumerated()), id: \.offset) { _, bar in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(bar.color)
                        .frame(width: contentWidth * bar.widthRatio, height: bar.height)
                        .padding(.top, bar.topMargin)
                }
            }
            .padding(.top, 120)
            .padding(.leading, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .blur(radius: 7)
        .opacity(0.55)
    }
}

/// 背景スケルトンのバー1本の定義。日記本文の1行を抽象化した矩形。
struct LockSkeletonBar {
    /// 本文エリア幅に対する横幅の比率。
    let widthRatio: CGFloat
    /// バーの高さ。
    let height: CGFloat
    /// バーの塗り色。
    let color: Color
    /// 段落の区切りを表す上マージン。
    var topMargin: CGFloat = 0
}

struct LockSkeletonBackground_Previews: PreviewProvider {
    static var previews: some View {
        LockSkeletonBackground()
            .background(Color.inkPaper)
    }
}
