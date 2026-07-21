import SwiftUI

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

struct InkTextStyle {
    var font: Font
    var lineSpacing: CGFloat
    var tracking: CGFloat

    // lineSpacing / tracking にデフォルト(0)を与えるための init。
    init(font: Font, lineSpacing: CGFloat = 0, tracking: CGFloat = 0) {
        self.font = font
        self.lineSpacing = lineSpacing
        self.tracking = tracking
    }
}

enum InkTypography {
    static func font(_ size: CGFloat, _ weight: InkFontWeight = .regular) -> Font {
        Font.custom(weight.postScriptName, size: size).weight(weight.systemWeight)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }

    /// CSS の line-height 乗率から SwiftUI の追加行間を近似する。
    /// SwiftUI の既定行高(約 1.2em)を差し引いた残りを追加行間として与える。
    static func lineSpacing(fontSize: CGFloat, multiplier: CGFloat) -> CGFloat {
        max(0, fontSize * (multiplier - 1.2))
    }

    static var screenTitle: Font { font(20, .bold) }
    static var navTitle: Font { font(15, .bold) }

    static var onboardingHeadline: InkTextStyle {
        InkTextStyle(font: font(24, .bold), lineSpacing: lineSpacing(fontSize: 24, multiplier: 1.65))
    }

    static var entryTitle: Font { font(22, .bold) }
    static var listItemTitle: Font { font(15, .bold) }

    static var body: InkTextStyle {
        InkTextStyle(font: font(15, .regular), lineSpacing: lineSpacing(fontSize: 15, multiplier: 2.05))
    }

    static var excerpt: InkTextStyle {
        InkTextStyle(font: font(13, .regular), lineSpacing: lineSpacing(fontSize: 13, multiplier: 1.8))
    }

    static var caption: Font { font(12, .regular) }
    static var captionSecondary: Font { font(13, .regular) }

    static var sectionLabel: InkTextStyle {
        InkTextStyle(font: font(12, .bold), tracking: 0.5)
    }

    static var monoLabel: InkTextStyle {
        InkTextStyle(font: mono(11, weight: .semibold), tracking: 11 * 0.15)
    }

    static var monoBody: Font { mono(11.5) }
    static var monoWord: Font { mono(14, weight: .medium) }
}

extension View {
    func inkTextStyle(_ style: InkTextStyle) -> some View {
        self.font(style.font)
            .lineSpacing(style.lineSpacing)
            .tracking(style.tracking)
    }
}
