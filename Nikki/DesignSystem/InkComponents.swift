import SwiftUI

struct InkPrimaryButton: View {
    let title: String
    var icon: String?
    var isEnabled: Bool
    let action: () -> Void

    // title をラベル省略で受け取り、icon / isEnabled を任意にするための init。
    init(_ title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(InkTypography.font(16, .medium).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(isEnabled ? InkColors.primaryButtonText : InkColors.labelGray)
            .background(isEnabled ? InkColors.ink : InkColors.disabledBackground)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct InkSecondaryButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    // title をラベル省略で受け取り、icon を任意にするための init。
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(InkTypography.font(15, .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(InkColors.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .strokeBorder(InkColors.secondaryButtonBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct InkTextLink: View {
    let title: String
    let action: () -> Void

    // title をラベル省略で受け取るための init。
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InkTypography.font(13.5, .regular))
                .foregroundStyle(InkColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(6)
        }
        .buttonStyle(.plain)
    }
}

struct InkSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = index == selectedIndex
                Text(option)
                    .font(InkTypography.font(13, isSelected ? .bold : .regular).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? InkColors.ink : InkColors.textSecondary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 7)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(InkColors.surface)
                                .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedIndex = index }
            }
        }
        .padding(2.5)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(InkColors.segmentBackground)
        )
    }
}

struct InkFAB: View {
    var icon: String
    let action: () -> Void

    // icon にデフォルト(ペン)を与えるための init。
    init(icon: String = InkIcons.pen, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(InkColors.primaryButtonText)
                .frame(width: 58, height: 58)
                .background(Circle().fill(InkColors.ink))
                .shadow(color: InkColors.ink.opacity(0.28), radius: 12, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

struct InkSearchBar: View {
    var placeholder: String
    @Binding var text: String

    // placeholder と Binding の text にプレビュー用デフォルトを与えるための init。
    init(placeholder: String = "日記をさがす", text: Binding<String> = .constant("")) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: InkIcons.search)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(InkColors.textTertiary)
            if text.isEmpty {
                Text(placeholder)
                    .font(InkTypography.font(14, .regular))
                    .foregroundStyle(InkColors.textTertiary)
            } else {
                Text(text)
                    .font(InkTypography.font(14, .regular))
                    .foregroundStyle(InkColors.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InkColors.surfaceInset)
        )
    }
}

struct InkStepIndicator: View {
    let step: Int
    let total: Int

    var body: some View {
        Text("\(step) / \(total)")
            .font(InkTypography.mono(11, weight: .semibold))
            .tracking(11 * 0.15)
            .foregroundStyle(InkColors.textTertiary)
    }
}

struct InkCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var padding: CGFloat? = nil

    func body(content: Content) -> some View {
        content
            .padding(padding ?? 0)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(InkColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(InkColors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 1.5, x: 0, y: 1)
    }
}

extension View {
    func inkCard(cornerRadius: CGFloat = 14, padding: CGFloat? = nil) -> some View {
        modifier(InkCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

/// 白カード内のグループ化リスト。行は InkListRow を並べて使う。
struct InkListSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(InkColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(InkColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct InkListRow: View {
    let title: String
    var value: String?
    var showsChevron: Bool
    var showsSeparator: Bool
    var height: CGFloat
    var trailing: AnyView?
    var action: (() -> Void)?

    // title をラベル省略で受け取り、他要素を任意にするための init。
    init(
        _ title: String,
        value: String? = nil,
        showsChevron: Bool = true,
        showsSeparator: Bool = true,
        height: CGFloat = 52,
        trailing: AnyView? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.showsChevron = showsChevron
        self.showsSeparator = showsSeparator
        self.height = height
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(InkTypography.font(14.5, .regular))
                    .foregroundStyle(InkColors.ink)
                Spacer(minLength: 8)
                if let trailing {
                    trailing
                } else {
                    if let value {
                        Text(value)
                            .font(InkTypography.font(13.5, .regular))
                            .foregroundStyle(InkColors.textSecondary)
                    }
                    if showsChevron {
                        Image(systemName: InkIcons.chevronRight)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(InkColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .contentShape(Rectangle())
            .onTapGesture { action?() }

            if showsSeparator {
                Rectangle()
                    .fill(InkColors.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 16)
            }
        }
    }
}

enum InkNavLeading {
    case none
    case back
    case dismiss
}

enum InkNavCenter {
    case none
    case title(String)
    case caption(String)
}

struct InkNavBar: View {
    var leading: InkNavLeading
    var center: InkNavCenter
    var onLeading: (() -> Void)?

    // leading / center / onLeading にデフォルトを与えるための init。
    init(leading: InkNavLeading = .none, center: InkNavCenter = .none, onLeading: (() -> Void)? = nil) {
        self.leading = leading
        self.center = center
        self.onLeading = onLeading
    }

    var body: some View {
        ZStack {
            switch center {
            case .none:
                EmptyView()
            case .title(let text):
                Text(text)
                    .font(InkTypography.navTitle)
                    .foregroundStyle(InkColors.ink)
            case .caption(let text):
                Text(text)
                    .font(InkTypography.font(12.5, .regular))
                    .foregroundStyle(InkColors.textTertiary)
            }

            HStack {
                leadingButton
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var leadingButton: some View {
        switch leading {
        case .none:
            Color.clear.frame(width: 16, height: 16)
        case .back:
            Button { onLeading?() } label: {
                Image(systemName: InkIcons.chevronLeft)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(InkColors.textSecondary)
            }
            .buttonStyle(.plain)
        case .dismiss:
            Button { onLeading?() } label: {
                Image(systemName: InkIcons.chevronDown)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(InkColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}
