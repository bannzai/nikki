import SwiftUI

enum InkColors {
    static let paper = Color(hex: 0xFAFAF9)
    static let surface = Color(hex: 0xFFFFFF)
    static let surfaceInset = Color(hex: 0xF0EFEA)
    static let segmentBackground = Color(hex: 0xECEBE6)
    static let ink = Color(hex: 0x1C1B1A)
    static let textSecondary = Color(hex: 0x6E6D69)
    static let textTertiary = Color(hex: 0xA3A29D)
    static let textQuaternary = Color(hex: 0xC7C6C2)
    static let disabledBackground = Color(hex: 0xDBDAD5)
    static let labelGray = Color(hex: 0x8A8985)
    static let primaryButtonText = Color(hex: 0xFAFAF9)

    static let border = Color(red: 0, green: 0, blue: 0, opacity: 0.08)
    static let separator = Color(hex: 0x1C1B1A, opacity: 0.10)
    static let selectionHighlight = Color(hex: 0x1C1B1A, opacity: 0.14)
    static let secondaryButtonBorder = Color(hex: 0x1C1B1A, opacity: 0.25)
}

enum PaperColorPreset: String, CaseIterable, Identifiable {
    case white
    case ecru
    case ash
    case celadon
    case sakura

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white: return Color(hex: 0xFFFFFF)
        case .ecru: return Color(hex: 0xF7F4EC)
        case .ash: return Color(hex: 0xECECEA)
        case .celadon: return Color(hex: 0xE9EDEA)
        case .sakura: return Color(hex: 0xF2EAE4)
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
