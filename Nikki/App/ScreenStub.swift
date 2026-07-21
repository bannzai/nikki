import SwiftUI

/// 画面実装エージェントが差し替える前提のプレースホルダ。
/// 紙色の地に画面名を中央表示するだけの最小 View。
struct ScreenStub: View {
    let title: String
    var subtitle: String?
    var background: Color = InkColors.paper

    // title をラベル省略で受け取り、subtitle / background を任意にするための init。
    init(_ title: String, subtitle: String? = nil, background: Color = InkColors.paper) {
        self.title = title
        self.subtitle = subtitle
        self.background = background
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            VStack(spacing: 8) {
                Text(title)
                    .font(InkTypography.entryTitle)
                    .foregroundStyle(InkColors.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(InkTypography.captionSecondary)
                        .foregroundStyle(InkColors.textSecondary)
                }
            }
            .padding()
        }
    }
}
