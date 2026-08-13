import SwiftUI

/// エディタ各状態の共通外枠(紙地 + ナビ + 本文スロット)。
struct EditorScreenScaffold<Content: View>: View {
    let caption: String
    /// ナビ左端の閉じるボタンのアクション。カタログの静的表示では空 closure を渡す。
    let onDismiss: () -> Void
    // ナビ右端の操作を持つのはエディタ本体だけのため、カタログの静的表示が既定のまま使えるようボタンなしを既定にする。
    /// ナビ右端のボタンとそのアクション。エディタのテンプレート選択のような画面ごとの操作を置く。
    var trailing: InkNavTrailing = .none
    var onTrailing: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .dismiss, center: .caption(caption), trailing: trailing, onLeading: onDismiss, onTrailing: onTrailing)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct EditorScreenScaffold_Previews: PreviewProvider {
    static var previews: some View {
        EditorScreenScaffold(caption: "7月18日 土曜日", onDismiss: {}) {
            Text("本文")
                .padding()
        }
    }
}
