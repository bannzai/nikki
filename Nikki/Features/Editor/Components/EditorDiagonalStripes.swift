import SwiftUI

/// 45°ストライプの地(img プレースホルダ用)。
struct EditorDiagonalStripes: View {
    var body: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(45))
            let extent = size.width + size.height
            var x = -extent
            var index = 0
            while x < extent {
                context.fill(
                    Path(CGRect(x: x, y: -extent, width: 8, height: 2 * extent)),
                    with: .color(index % 2 == 0 ? EditorPalette.stripeLight : EditorPalette.stripeDark)
                )
                x += 8
                index += 1
            }
        }
    }
}
