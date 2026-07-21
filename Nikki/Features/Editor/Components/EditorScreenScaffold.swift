import SwiftUI

/// エディタ各状態の共通外枠(紙地 + ナビ + 本文スロット)。
struct EditorScreenScaffold<Content: View>: View {
    let caption: String
    /// ナビ左端の閉じるボタンのアクション。カタログの静的表示では nil(何もしない)。
    var onDismiss: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .dismiss, center: .caption(caption), onLeading: onDismiss)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
