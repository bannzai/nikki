import SwiftUI

/// 見出しブロック。level 2 は 18/700、level 3 は 16/500。
struct EditorHeadingBlock: View {
    let level: Int
    let text: String

    var body: some View {
        Text(text)
            .font(EditorHeadingFont.font(for: level))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 見出しレベルからフォントを決める。
enum EditorHeadingFont {
    static func font(for level: Int) -> Font {
        switch level {
        case ...1: return .ink(22, .bold)
        case 2: return .ink(18, .bold)
        default: return .ink(16, .medium)
        }
    }
}
