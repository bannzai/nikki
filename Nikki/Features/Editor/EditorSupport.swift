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

/// 日付を「7月18日 土曜日」形式(JST)で表す。
enum EditorDateText {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        f.dateFormat = "M月d日 EEEE"
        return f
    }()

    static func caption(for date: Date) -> String { formatter.string(from: date) }
}

/// エディタ各状態が本文ブロックから必要な要素を取り出すヘルパー。
enum EditorBlockPicker {
    static func paragraphTexts(_ entry: JournalEntry) -> [String] {
        entry.blocks.compactMap { if case .paragraph(_, let text) = $0 { return text } else { return nil } }
    }

    static func headingTexts(_ entry: JournalEntry) -> [String] {
        entry.blocks.compactMap { if case .heading(_, _, let text) = $0 { return text } else { return nil } }
    }

    static func firstChecklist(_ entry: JournalEntry) -> [ChecklistItem] {
        entry.blocks.compactMap { if case .checklist(_, let items) = $0 { return items } else { return nil } }.first ?? []
    }

    static func firstImageLabel(_ entry: JournalEntry) -> String? {
        entry.blocks.compactMap { if case .image(_, let label) = $0 { return label } else { return nil } }.first
    }

    static func firstDetailsSummary(_ entry: JournalEntry) -> String? {
        entry.blocks.compactMap { if case .details(_, let summary, _) = $0 { return summary } else { return nil } }.first
    }
}

// MARK: - 本文ブロック(執筆・選択状態で共通)

/// 本文段落。15px・行間2.05。
struct EditorParagraphBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .inkTextStyle(InkTypography.body)
            .foregroundStyle(InkColors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 執筆中の段落。末尾に点滅する 2×18 相当の墨キャレットを付ける。
struct EditorWritingParagraph: View {
    let text: String

    var body: some View {
        // 0.6 秒周期は一般的なテキストカーソルの点滅間隔に合わせている。
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let visible = Int(context.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 0
            (
                Text(text).foregroundStyle(InkColors.ink)
                + Text("\u{258F}").foregroundStyle(visible ? InkColors.ink : Color.clear)
            )
            .font(InkTypography.body.font)
            .lineSpacing(InkTypography.body.lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 見出しブロック。level 2 は 18/700、level 3 は 16/500。
struct EditorHeadingBlock: View {
    let level: Int
    let text: String

    var body: some View {
        Text(text)
            .font(EditorHeadingFont.font(for: level))
            .foregroundStyle(InkColors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 見出しレベルからフォントを決める。
enum EditorHeadingFont {
    static func font(for level: Int) -> Font {
        switch level {
        case ...1: return InkTypography.font(22, .bold)
        case 2: return InkTypography.font(18, .bold)
        default: return InkTypography.font(16, .medium)
        }
    }
}

/// チェックボックス。完了は墨地+白チェック、未完了は角丸枠。
struct EditorCheckbox: View {
    var done: Bool
    var size: CGFloat = 19

    var body: some View {
        if done {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(InkColors.ink)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: InkIcons.checkmark)
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(InkColors.primaryButtonText)
                }
        } else {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(InkColors.ink.opacity(0.35), lineWidth: 1.5)
                .frame(width: size, height: size)
        }
    }
}

/// チェックリスト。完了項目は打ち消し線+灰。
struct EditorChecklistBlock: View {
    let items: [ChecklistItem]
    var boxSize: CGFloat = 19
    var fontSize: CGFloat = 15
    var rowSpacing: CGFloat = 10
    var boxSpacing: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(items) { item in
                HStack(spacing: boxSpacing) {
                    EditorCheckbox(done: item.done, size: boxSize)
                    Text(item.text)
                        .font(InkTypography.font(fontSize, .regular))
                        .foregroundStyle(item.done ? InkColors.textTertiary : InkColors.ink)
                        .strikethrough(item.done, color: InkColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 45°ストライプの地(img プレースホルダ用)。
struct EditorDiagonalStripes: View {
    var body: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(45))
            let extent = size.width + size.height
            var x = -extent
            var index = 0
            while x < extent {
                context.fill(
                    Path(CGRect(x: x, y: -extent, width: 8, height: 2 * extent)),
                    with: .color(index % 2 == 0 ? EditorPalette.stripeLight : EditorPalette.stripeDark)
                )
                x += 8
                index += 1
            }
        }
    }
}

/// img プレースホルダ。45°ストライプ地 + mono ラベル。
struct EditorImageBlock: View {
    let label: String

    var body: some View {
        ZStack {
            EditorDiagonalStripes()
            Text("img: \(label)")
                .font(InkTypography.mono(11))
                .foregroundStyle(InkColors.labelGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(InkColors.paper.opacity(0.9))
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// details ブロック。枠線カード + ▶ + summary。
struct EditorDetailsBlock: View {
    let summary: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: InkIcons.chevronRight)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(InkColors.textSecondary)
            Text("details — \(summary)")
                .font(InkTypography.font(14, .regular))
                .foregroundStyle(InkColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(InkColors.ink.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - 選択ツールバー(1j)

/// テキスト選択時のフローティングツールバー(本文 | H1 H2 H3 | ☑ リスト …)。
struct EditorSelectionToolbar: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("本文")
                .font(InkTypography.font(13.5, .regular))
                .foregroundStyle(EditorPalette.inkGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            divider
            headingLabel("H1", active: false)
            headingLabel("H2", active: true)
            headingLabel("H3", active: false)
            divider
            icon("checkmark.square")
            icon(InkIcons.list)
            Text("…")
                .font(InkTypography.font(14, .regular))
                .tracking(1.4)
                .foregroundStyle(EditorPalette.inkGray)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InkColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(InkColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 13, x: 0, y: 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(InkColors.ink.opacity(0.1))
            .frame(width: 1, height: 18)
    }

    private func headingLabel(_ title: String, active: Bool) -> some View {
        Text(title)
            .font(InkTypography.mono(12.5, weight: .semibold))
            .foregroundStyle(active ? InkColors.primaryButtonText : EditorPalette.inkGray)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(InkColors.ink)
                }
            }
    }

    private func icon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(EditorPalette.inkGray)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
    }
}

/// 選択中の見出し。ハイライト背景 + 両端のセレクションハンドル(縦線+円)。
struct EditorSelectedHeading: View {
    let text: String
    var level: Int = 2

    var body: some View {
        Text(text)
            .font(EditorHeadingFont.font(for: level))
            .foregroundStyle(InkColors.ink)
            .padding(.vertical, 2)
            .background(InkColors.selectionHighlight)
            .overlay(alignment: .leading) {
                handle(circleAlignment: .top, circleOffsetY: -8)
                    .offset(x: -1)
            }
            .overlay(alignment: .trailing) {
                handle(circleAlignment: .bottom, circleOffsetY: 8)
                    .offset(x: 1)
            }
    }

    private func handle(circleAlignment: Alignment, circleOffsetY: CGFloat) -> some View {
        Rectangle()
            .fill(InkColors.ink)
            .frame(width: 2)
            .overlay(alignment: circleAlignment) {
                Circle()
                    .fill(InkColors.ink)
                    .frame(width: 11, height: 11)
                    .offset(y: circleOffsetY)
            }
    }
}

// MARK: - 並び替え(1k)

/// 6点ドラッグハンドル(2列×3行)。掴んでいる行は墨、他は微灰。
struct EditorDragHandle: View {
    var active: Bool

    var body: some View {
        let color = active ? InkColors.ink : InkColors.textQuaternary
        VStack(spacing: 2.3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 1.8) {
                    dot(color)
                    dot(color)
                }
            }
        }
    }

    private func dot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 3.2, height: 3.2)
    }
}

// MARK: - 画面の外枠

/// エディタ各状態の共通外枠(紙地 + ナビ + 本文スロット)。
struct EditorScreenScaffold<Content: View>: View {
    let caption: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .dismiss, center: .caption(caption))
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
