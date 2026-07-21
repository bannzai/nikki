import SwiftUI

/// 南京錠の線画アイコン。デザインの SVG(viewBox 16×18)を等比で 20×24 に収める。
struct LockPadlockIcon: View {
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
struct LockPadlockOutline: Shape {
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
