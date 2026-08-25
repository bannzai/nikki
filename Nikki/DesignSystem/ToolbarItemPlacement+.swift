import SwiftUI

extension ToolbarItemPlacement {
    /// ナビゲーションバー左端。iOS と macOS で名前が違うため、画面側に #if を散らさずここへ寄せる。
    static var inkNavigationBarLeading: ToolbarItemPlacement {
        #if os(macOS)
        .navigation
        #else
        .topBarLeading
        #endif
    }

    /// ナビゲーションバー右端。iOS と macOS で名前が違うため、画面側に #if を散らさずここへ寄せる。
    static var inkNavigationBarTrailing: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }
}
