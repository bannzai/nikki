import SwiftUI

/// エディタ内で使う、DesignSystem に定義の無い補助色。
enum EditorPalette {
    /// ツールバー文字・並び替え本文・シェブロンに使う濃いグレー(#52514E)。
    static let inkGray = Color(hex: 0x52514E)
    /// img プレースホルダの 45°ストライプ(明)。
    static let stripeLight = Color(hex: 0xF1F0EC)
    /// img プレースホルダの 45°ストライプ(暗)。
    static let stripeDark = Color(hex: 0xE8E7E2)
}
