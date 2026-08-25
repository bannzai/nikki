import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension Image {
    /// 画像データから Image を作る。デコードできないデータの場合は nil。
    init?(data: Data) {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else {
            return nil
        }
        self.init(uiImage: uiImage)
        #else
        guard let nsImage = NSImage(data: data) else {
            return nil
        }
        self.init(nsImage: nsImage)
        #endif
    }
}
