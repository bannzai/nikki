import SwiftUI

/// 墨地の主ボタンの ButtonStyle。無効状態の見た目は .disabled() による environment で切り替わる。
struct InkPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ink(16, .medium).weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(isEnabled ? Color.inkPrimaryButtonText : Color.inkLabelGray)
            .background(isEnabled ? Color.ink : Color.inkDisabledBackground)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
    }
}

/// 枠線の二次ボタンの ButtonStyle。
struct InkSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ink(15, .medium))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(Color.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .strokeBorder(Color.inkSecondaryButtonBorder, lineWidth: 1.5)
            )
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
                    .font(.ink(13, isSelected ? .bold : .regular).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.ink : Color.inkTextSecondary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 7)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.inkSurface)
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
                .fill(Color.inkSegmentBackground)
        )
    }
}

/// 右下の丸い新規作成ボタンの ButtonStyle。ラベルにはアイコンを渡す。
struct InkFABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(Color.inkPrimaryButtonText)
            .frame(width: 58, height: 58)
            .background(Circle().fill(Color.ink))
            .shadow(color: Color.ink.opacity(0.28), radius: 12, x: 0, y: 10)
    }
}

/// 検索バー。入力は呼び出し側の Binding に流し、絞り込み自体は呼び出し側が行う。
struct InkSearchBar: View {
    // 見本(1g)のプレースホルダ文言。
    var placeholder: String = "日記をさがす"
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: InkIcons.search)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.inkTextTertiary)
            TextField(
                placeholder,
                text: $text,
                prompt: Text(placeholder)
                    .font(.ink(14, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
            )
            .font(.ink(14, .regular))
            .foregroundStyle(Color.ink)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkSurfaceInset)
        )
    }
}

struct InkStepIndicator: View {
    let step: Int
    let total: Int

    var body: some View {
        Text("\(step) / \(total)")
            .font(.inkMono(11, weight: .semibold))
            .tracking(11 * 0.15)
            .foregroundStyle(Color.inkTextTertiary)
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
                    .fill(Color.inkSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.inkBorder, lineWidth: 1)
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
                .fill(Color.inkSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.inkBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct InkListRow: View {
    let title: String
    var value: String?
    // 見本(1r)の行は既定でシェブロンとセパレータを持つため。
    var showsChevron: Bool = true
    var showsSeparator: Bool = true
    // 見本(1r)の行高。
    var height: CGFloat = 52
    var trailing: AnyView?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.ink(14.5, .regular))
                    .foregroundStyle(Color.ink)
                Spacer(minLength: 8)
                if let trailing {
                    trailing
                } else {
                    if let value {
                        Text(value)
                            .font(.ink(13.5, .regular))
                            .foregroundStyle(Color.inkTextSecondary)
                    }
                    if showsChevron {
                        Image(systemName: InkIcons.chevronRight)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.inkTextTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .contentShape(Rectangle())
            .onTapGesture { action?() }

            if showsSeparator {
                Rectangle()
                    .fill(Color.inkSeparator)
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
    var leading: InkNavLeading = .none
    var center: InkNavCenter = .none
    var onLeading: (() -> Void)? = nil

    var body: some View {
        ZStack {
            switch center {
            case .none:
                EmptyView()
            case .title(let text):
                Text(text)
                    .font(.inkNavTitle)
                    .foregroundStyle(Color.ink)
            case .caption(let text):
                Text(text)
                    .font(.ink(12.5, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
            }

            HStack {
                InkNavBarLeadingButton(leading: leading, onLeading: onLeading)
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
    }
}

/// InkNavBar の左端ボタン(なし / 戻る / 閉じる)。
struct InkNavBarLeadingButton: View {
    let leading: InkNavLeading
    var onLeading: (() -> Void)? = nil

    var body: some View {
        switch leading {
        case .none:
            Color.clear.frame(width: 16, height: 16)
        case .back:
            Button { onLeading?() } label: {
                Image(systemName: InkIcons.chevronLeft)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkTextSecondary)
            }
            .buttonStyle(.plain)
        case .dismiss:
            Button { onLeading?() } label: {
                Image(systemName: InkIcons.chevronDown)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkTextSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}
