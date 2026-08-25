import SwiftUI
#if os(iOS)
import UIKit
#endif

extension View {
    /// システム標準のナビゲーション UI を隠し、InkNavBar による独自ヘッダに一本化する。
    /// macOS は ToolbarPlacement.navigationBar が存在せず、ウィンドウツールバーごと隠すと
    /// タイトルバー(閉じる・最小化ボタンやドラッグ領域)まで消えてしまうため、
    /// タイトルバーは残して NavigationStack が出す戻るボタン(InkNavBar の戻ると重複する)だけを隠す。
    func inkNavigationBarHidden() -> some View {
        #if os(macOS)
        navigationBarBackButtonHidden(true)
        #else
        // toolbar(.hidden, for: .navigationBar) は UIKit の interactivePopGestureRecognizer も
        // 道連れに無効化する(ナビゲーションバー非表示に連動する既知の挙動)ため、
        // 右エッジスワイプでの「戻る」が効かなくなる(issue #92)。inkSwipeBackEnabled() で戻す。
        toolbar(.hidden, for: .navigationBar)
            .inkSwipeBackEnabled()
        #endif
    }
}

#if os(iOS)
extension View {
    /// システムのナビゲーションバーを隠していても、右エッジスワイプでの「戻る」ジェスチャを有効にする。
    /// inkNavigationBarHidden() の一部として適用するため、通常はこちらを直接使わない。
    fileprivate func inkSwipeBackEnabled() -> some View {
        background(InkSwipeBackGestureEnabler())
    }
}

/// 親の UINavigationController を見つけ、隠れたナビゲーションバーに連動して無効化された
/// interactivePopGestureRecognizer を有効化し直すための橋渡し View。
private struct InkSwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InkSwipeBackGestureEnablerViewController {
        InkSwipeBackGestureEnablerViewController()
    }

    func updateUIViewController(_ uiViewController: InkSwipeBackGestureEnablerViewController, context: Context) {}
}

private final class InkSwipeBackGestureEnablerViewController: UIViewController, UIGestureRecognizerDelegate {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let navigationController else {
            return
        }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        // 既定の delegate はナビゲーションバーの表示状態(戻るボタンの有無)を見てジェスチャを拒否するため、
        // 自前の delegate に差し替え、戻り先があるか(スタックの深さ)だけで判定する。
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }

    /// 戻り先のないルート画面でジェスチャが始まると、完了先のない遷移でナビゲーションが操作不能になり得るため、
    /// スタックに戻り先がある時だけ開始を許可する。
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
#endif
