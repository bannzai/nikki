import SwiftUI

extension ToolbarContent {
    /// iOS 26 / macOS 26 の Liquid Glass がツールバー項目に敷くカプセル / 円形の地を消す。
    /// ガラスの光沢が Nikki の紙のような静かな外観と合わないため、全ツールバー項目で使う。
    @ToolbarContentBuilder
    func inkSharedBackgroundHidden() -> some ToolbarContent {
        if #available(iOS 26.0, macOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
