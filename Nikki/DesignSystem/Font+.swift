import SwiftUI

/// Zen Kaku Gothic New のウェイトと PostScript 名の対応。
enum InkFontWeight {
    case regular
    case medium
    case bold

    var postScriptName: String {
        switch self {
        case .regular: return "ZenKakuGothicNew-Regular"
        case .medium: return "ZenKakuGothicNew-Medium"
        case .bold: return "ZenKakuGothicNew-Bold"
        }
    }

    var systemWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .bold: return .bold
        }
    }
}

extension Font {
    /// Zen Kaku Gothic New を用いた基本書体。
    static func ink(_ size: CGFloat, _ weight: InkFontWeight = .regular) -> Font {
        Font.custom(weight.postScriptName, size: size).weight(weight.systemWeight)
    }

    /// 等幅書体。{{変数}}・markdown プレビュー・日時ラベルに使う。
    static func inkMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }

    /// 画面タイトル(ホームのロゴなど)。
    static let inkScreenTitle = ink(20, .bold)
    /// ナビバーの中央タイトル。
    static let inkNavTitle = ink(15, .bold)
    /// 日記タイトル(エディタの見出し)。
    static let inkEntryTitle = ink(22, .bold)
    /// リスト行のタイトル。
    static let inkListItemTitle = ink(15, .bold)
    /// キャプション。
    static let inkCaption = ink(12)
    /// やや大きめのキャプション。
    static let inkCaptionSecondary = ink(13)
    /// 等幅の本文(markdown プレビュー)。
    static let inkMonoBody = inkMono(11.5)
    /// 等幅の単語表示。
    static let inkMonoWord = inkMono(14, weight: .medium)
}

/// CSS の line-height 乗率から SwiftUI の追加行間を近似する。
/// SwiftUI の既定行高(約 1.2em)を差し引いた残りを追加行間として与える。
func inkLineSpacing(fontSize: CGFloat, multiplier: CGFloat) -> CGFloat {
    max(0, fontSize * (multiplier - 1.2))
}
