import SwiftUI

extension ToolbarPlacement {
    /// 画面上部のナビゲーションバー。iOS はナビゲーションバー、macOS はウィンドウツールバーが同じ役割を持つ。
    static var inkNavigationBar: ToolbarPlacement {
        #if os(macOS)
        .windowToolbar
        #else
        .navigationBar
        #endif
    }
}
