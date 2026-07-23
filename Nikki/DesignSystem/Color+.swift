import SwiftUI

// MARK: - Ink パレット

extension Color {
    /// 画面の紙地。
    static let inkPaper = Color(hex: 0xFAFAF9)
    /// カード等の白面。
    static let inkSurface = Color(hex: 0xFFFFFF)
    /// くぼみ地(検索バー・markdown プレビュー)。
    static let inkSurfaceInset = Color(hex: 0xF0EFEA)
    /// セグメントコントロールの地。
    static let inkSegmentBackground = Color(hex: 0xECEBE6)
    /// 墨(主要テキスト・主ボタン地)。
    static let ink = Color(hex: 0x1C1B1A)
    /// 二次テキスト。
    static let inkTextSecondary = Color(hex: 0x6E6D69)
    /// 三次テキスト(補足・ラベル)。
    static let inkTextTertiary = Color(hex: 0xA3A29D)
    /// 四次テキスト(未来日など微色)。
    static let inkTextQuaternary = Color(hex: 0xC7C6C2)
    /// 無効状態のボタン地。
    static let inkDisabledBackground = Color(hex: 0xDBDAD5)
    /// 無効状態のボタン文字。
    static let inkLabelGray = Color(hex: 0x8A8985)
    /// 主ボタンの文字色。
    static let inkPrimaryButtonText = Color(hex: 0xFAFAF9)

    /// カードの枠線。
    static let inkBorder = Color(red: 0, green: 0, blue: 0, opacity: 0.08)
    /// リストのセパレータ。
    static let inkSeparator = Color(hex: 0x1C1B1A, opacity: 0.10)
    /// テキスト選択のハイライト。
    static let inkSelectionHighlight = Color(hex: 0x1C1B1A, opacity: 0.14)
    /// 二次ボタンの枠線。
    static let inkSecondaryButtonBorder = Color(hex: 0x1C1B1A, opacity: 0.25)
}

// MARK: - 紙色プリセット

extension Color {
    /// テーマ設定(1n)の紙色プリセット。先頭から 白 / 生成 / 薄鼠 / 青磁 / 桜鼠。
    static let paperColorPreset: [Color] = [
        Color(hex: 0xFFFFFF),
        Color(hex: 0xF7F4EC),
        Color(hex: 0xECECEA),
        Color(hex: 0xE9EDEA),
        Color(hex: 0xF2EAE4),
    ]
}

// MARK: - hex 初期化

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
