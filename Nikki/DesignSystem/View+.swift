import SwiftUI

extension View {
    /// システム標準のナビゲーション UI を隠し、InkNavBar による独自ヘッダに一本化する。
    /// macOS は ToolbarPlacement.navigationBar が存在せず、ウィンドウツールバーごと隠すと
    /// タイトルバー(閉じる・最小化ボタンやドラッグ領域)まで消えてしまうため、
    /// タイトルバーは残して NavigationStack が出す戻るボタン(InkNavBar の戻ると重複する)だけを隠す。
    func inkNavigationBarHidden() -> some View {
        #if os(macOS)
        navigationBarBackButtonHidden(true)
        #else
        toolbar(.hidden, for: .navigationBar)
        #endif
    }
}
