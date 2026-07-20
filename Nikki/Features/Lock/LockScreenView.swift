import SwiftUI

/// 自動ロック時に表示するロック画面(1f)。背景の日記本文をぼかして中身を守り、
/// 中央のオーバーレイで再開を促す。解除後は呼び出し側が直前の画面へ復帰させる。
struct LockScreenView: View {
    /// Face ID ボタンのタップで呼ばれる。実際の生体認証・解除処理は呼び出し側が担う。
    var onUnlock: () -> Void = {}

    /// スケルトンの見出し風バーの色(#C9C8C3)。日記のタイトル行を抽象化した矩形に使う。
    private static let skeletonTitleColor = Color(hex: 0xC9C8C3)
    /// スケルトンの本文風バーの色(#DDDCD7)。日記の本文行を抽象化した矩形に使う。
    private static let skeletonBodyColor = Color(hex: 0xDDDCD7)

    /// 背景スケルトンのバー定義。幅は本文エリア(横パディングを除いた幅)に対する比率で指定する。
    private static let skeletonBars: [LockSkeletonBar] = [
        LockSkeletonBar(widthRatio: 0.56, height: 20, color: skeletonTitleColor),
        LockSkeletonBar(widthRatio: 0.92, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.88, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.95, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.60, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.40, height: 16, color: skeletonTitleColor, topMargin: 14),
        LockSkeletonBar(widthRatio: 0.90, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.84, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.93, height: 12, color: skeletonBodyColor),
        LockSkeletonBar(widthRatio: 0.52, height: 12, color: skeletonBodyColor),
    ]

    var body: some View {
        ZStack {
            InkColors.paper
            skeletonBackground
            centerOverlay
        }
        .ignoresSafeArea()
    }

    /// 日記本文をスケルトン化し blur(7)+opacity(.55) で敷いた背景。中身を守る演出。
    private var skeletonBackground: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width - 64  // 横 32px パディング × 2
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(Self.skeletonBars.enumerated()), id: \.offset) { _, bar in
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

    /// 画面中央のロック解除オーバーレイ(南京錠円・文言・Face ID ボタン・脚注)。
    private var centerOverlay: some View {
        VStack(spacing: 20) {
            lockCircle
            messageBlock
            LockFaceIDButton(action: onUnlock)
                .padding(.top, 8)
            Text("解除すると、さっきの続きに戻ります")
                .font(InkTypography.font(12, .regular))
                .foregroundStyle(InkColors.textTertiary)
        }
        .padding(.horizontal, 28)
    }

    /// 64px 円(半透明地 + 細枠)に南京錠アイコンを収めたシンボル。
    private var lockCircle: some View {
        Circle()
            .fill(InkColors.paper.opacity(0.85))
            .overlay(Circle().strokeBorder(InkColors.ink.opacity(0.3), lineWidth: 1.5))
            .frame(width: 64, height: 64)
            .overlay { LockPadlockIcon() }
    }

    /// 見出しと説明文のブロック。中央揃え。
    private var messageBlock: some View {
        VStack(spacing: 8) {
            Text("鍵をかけておきました")
                .font(InkTypography.font(16, .bold))
                .foregroundStyle(InkColors.ink)
            Text("しばらく手が止まっていたので、\nそっとロックしました。")
                .font(InkTypography.font(12.5, .regular))
                .foregroundStyle(InkColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(InkTypography.lineSpacing(fontSize: 12.5, multiplier: 1.9))
        }
    }
}

/// 背景スケルトンのバー1本の定義。日記本文の1行を抽象化した矩形。
private struct LockSkeletonBar {
    /// 本文エリア幅に対する横幅の比率。
    let widthRatio: CGFloat
    /// バーの高さ。
    let height: CGFloat
    /// バーの塗り色。
    let color: Color
    /// 段落の区切りを表す上マージン。
    var topMargin: CGFloat = 0
}

/// 「Face ID で開く」墨 pill ボタン。高さ50・横パディング26・角丸25。
private struct LockFaceIDButton: View {
    /// タップ時のアクション。
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: InkIcons.faceID)
                    .font(.system(size: 18, weight: .regular))
                Text("Face ID で開く")
                    .font(InkTypography.font(15, .medium).weight(.semibold))
            }
            .foregroundStyle(InkColors.primaryButtonText)
            .frame(height: 50)
            .padding(.horizontal, 26)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(InkColors.ink)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 南京錠の線画アイコン。デザインの SVG(viewBox 16×18)を等比で 20×24 に収める。
private struct LockPadlockIcon: View {
    /// viewBox(16×18)を 20×24 にアスペクト比保持で収めたときの拡大率(= 20/16)。
    private let scale: CGFloat = 1.25
    /// 等比縮小で content(高さ 22.5)を 24 に収めた際の上下中央寄せオフセット。
    private let verticalOffset: CGFloat = (24 - 18 * 1.25) / 2

    var body: some View {
        ZStack {
            LockPadlockOutline()
                .stroke(
                    InkColors.ink,
                    style: StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round, lineJoin: .round)
                )
            // 鍵穴: circle cx=8 cy=12.5 r=1.5(viewBox 座標)
            Circle()
                .fill(InkColors.ink)
                .frame(width: 1.5 * 2 * scale, height: 1.5 * 2 * scale)
                .position(x: 8 * scale, y: 12.5 * scale + verticalOffset)
        }
        .frame(width: 20, height: 24)
    }
}

/// 南京錠の本体(角丸矩形)とシャックル(弧)を描く輪郭。鍵穴は別途重ねる。
private struct LockPadlockOutline: Shape {
    func path(in rect: CGRect) -> Path {
        // viewBox 0..16(x) / 0..18(y) を rect にアスペクト比保持で収める(SVG の meet 相当)。
        let scale = min(rect.width / 16, rect.height / 18)
        let offsetX = rect.midX - 16 * scale / 2
        let offsetY = rect.midY - 18 * scale / 2
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: offsetX + x * scale, y: offsetY + y * scale)
        }

        var path = Path()
        // 本体: rect x=1 y=8 w=14 h=9 rx=2
        path.addRoundedRect(
            in: CGRect(x: offsetX + 1 * scale, y: offsetY + 8 * scale, width: 14 * scale, height: 9 * scale),
            cornerSize: CGSize(width: 2 * scale, height: 2 * scale)
        )
        // シャックル: M4 8 V5.5 C4 3 5.8 1 8 1 S12 3 12 5.5 V8
        path.move(to: point(4, 8))
        path.addLine(to: point(4, 5.5))
        path.addCurve(to: point(8, 1), control1: point(4, 3), control2: point(5.8, 1))
        path.addCurve(to: point(12, 5.5), control1: point(10.2, 1), control2: point(12, 3))
        path.addLine(to: point(12, 8))
        return path
    }
}

#Preview {
    LockScreenView()
}
