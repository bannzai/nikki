import SwiftUI

/// エディタ各状態の共通外枠(紙地 + ナビ + 本文スロット)。戻りは NavigationStack の標準の戻るボタンに任せる。
struct EditorScreenScaffold<Content: View>: View {
    let caption: String
    // ナビ右端の操作を持つのはエディタ本体だけのため、カタログの静的表示が既定のまま使えるようボタンなしを既定にする。
    /// ナビ右端のボタンの文言。nil のときはボタンを出さない。
    var trailingButtonText: String? = nil
    /// ナビ右端のボタンのアクション。エディタのテンプレート選択のような画面ごとの操作を置く。
    var onTrailingButtonTap: (() -> Void)? = nil
    @ViewBuilder var content: Content

    @Environment(\.paperColor) private var paperColor

    var body: some View {
        ZStack {
            paperColor.ignoresSafeArea()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .inkNavigationBarCaption(caption: caption)
        .toolbar {
            if let trailingButtonText {
                InkNavigationBarTrailingButton(text: trailingButtonText, action: { onTrailingButtonTap?() })
            }
        }
    }
}

struct EditorScreenScaffold_Previews: PreviewProvider {
    static var previews: some View {
        // キャプションはナビゲーションバーに載るため、NavigationStack の中でだけ見える。
        NavigationStack {
            EditorScreenScaffold(caption: "7月18日 土曜日") {
                Text(verbatim: "本文")
                    .padding()
            }
        }
    }
}
