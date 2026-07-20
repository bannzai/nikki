import SwiftUI

enum InkIcons {
    static let pen = "pencil"
    static let lock = "lock"
    static let search = "magnifyingglass"
    static let faceID = "faceid"
    static let account = "person.crop.circle"
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
    static let chevronDown = "chevron.down"
    static let dragHandle = "line.3.horizontal"
    static let checkmark = "checkmark"
    static let list = "list.bullet"
    static let close = "xmark"
    static let checklist = "checklist"
    static let add = "plus"
}

/// オンボーディングの図解で使う 46px 円 + 1.5px 枠の中に線画アイコンを収めるヘルパー。
struct InkCircledIcon: View {
    let systemName: String
    var diameter: CGFloat = 46
    var iconSize: CGFloat = 18
    var borderColor: Color = InkColors.ink.opacity(0.3)

    init(
        systemName: String,
        diameter: CGFloat = 46,
        iconSize: CGFloat = 18,
        borderColor: Color = InkColors.ink.opacity(0.3)
    ) {
        self.systemName = systemName
        self.diameter = diameter
        self.iconSize = iconSize
        self.borderColor = borderColor
    }

    var body: some View {
        Circle()
            .strokeBorder(borderColor, lineWidth: 1.5)
            .frame(width: diameter, height: diameter)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .regular))
                    .foregroundStyle(InkColors.ink)
            }
    }
}
