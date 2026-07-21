import SwiftUI

/// 執筆中の段落。末尾に点滅する 2×18 相当の墨キャレットを付ける。
struct EditorWritingParagraph: View {
    let text: String

    var body: some View {
        // 0.6 秒周期は一般的なテキストカーソルの点滅間隔に合わせている。
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let visible = Int(context.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 0
            (
                Text(text).foregroundStyle(InkColors.ink)
                + Text("\u{258F}").foregroundStyle(visible ? InkColors.ink : Color.clear)
            )
            .font(InkTypography.body.font)
            .lineSpacing(InkTypography.body.lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
