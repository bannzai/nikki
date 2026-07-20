import SwiftUI

/// オンボーディング 1d: 復元フレーズの 3・7・11 番目を順に選ばせ、控えたことを確認する。
struct OnboardingPhraseConfirmView: View {
    let phrase: [String]
    var onConfirmed: () -> Void = {}

    init(phrase: [String] = SampleData.mnemonic, onConfirmed: @escaping () -> Void = {}) {
        self.phrase = phrase
        self.onConfirmed = onConfirmed
    }

    /// 確認対象の単語インデックス(0 始まり)。表示番号は +1 した 3・7・11。
    private let questionSlots = [2, 6, 10]

    /// 候補チップに並べる単語のインデックス。正解 3 語 + ダミー 3 語で、見本(1d)の並びに対応する。
    private let choiceSlots = [6, 11, 8, 2, 10, 9]

    /// 選んだ単語を選択順に保持する。要素数がそのまま「埋まったスロット数」になる。
    @State private var selectedWords: [String] = []

    private var answerWords: [String] {
        questionSlots.compactMap { phrase.indices.contains($0) ? phrase[$0] : nil }
    }

    private var choiceWords: [String] {
        choiceSlots.compactMap { phrase.indices.contains($0) ? phrase[$0] : nil }
    }

    private var isConfirmEnabled: Bool {
        selectedWords.count == answerWords.count
    }

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 2, total: 3)

                Text("たしかめましょう。")
                    .inkTextStyle(InkTypography.onboardingHeadline)
                    .foregroundStyle(InkColors.ink)
                    .padding(.top, 14)

                Text("3番目・7番目・11番目の言葉を、順に選んでください。")
                    .font(InkTypography.font(13, .regular))
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 13, multiplier: 2.0))
                    .foregroundStyle(InkColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                VStack(spacing: 10) {
                    ForEach(Array(questionSlots.enumerated()), id: \.offset) { index, _ in
                        slotRow(index)
                    }
                }
                .padding(.vertical, 26)

                OnboardingFlowLayout(spacing: 9) {
                    ForEach(choiceWords, id: \.self) { word in
                        chip(word)
                    }
                }

                Spacer(minLength: 0)

                InkPrimaryButton("確認する", isEnabled: isConfirmEnabled, action: onConfirmed)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
    }

    private func slotRow(_ index: Int) -> some View {
        let isFilled = index < selectedWords.count
        let isActive = index == selectedWords.count
        return HStack(spacing: 12) {
            Text("\(questionSlots[index] + 1)")
                .font(InkTypography.mono(11))
                .foregroundStyle(InkColors.textTertiary)
                .frame(width: 22, alignment: .leading)
            if isFilled {
                Text(selectedWords[index])
                    .font(InkTypography.mono(15, weight: .medium))
                    .foregroundStyle(InkColors.ink)
                Spacer(minLength: 0)
                Image(systemName: InkIcons.checkmark)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(InkColors.ink)
            } else if isActive {
                Rectangle()
                    .fill(InkColors.ink)
                    .frame(width: 2, height: 18)
                Spacer(minLength: 0)
            } else {
                Text("･･･")
                    .font(InkTypography.mono(15, weight: .medium))
                    .foregroundStyle(InkColors.textQuaternary)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(InkColors.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isActive ? InkColors.ink : InkColors.border, lineWidth: isActive ? 1.5 : 1)
        )
    }

    private func chip(_ word: String) -> some View {
        let isSelected = selectedWords.contains(word)
        return Text(word)
            .font(InkTypography.mono(13.5, weight: .medium))
            .strikethrough(isSelected, color: InkColors.textQuaternary)
            .foregroundStyle(isSelected ? InkColors.textQuaternary : InkColors.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(InkColors.segmentBackground)
                }
            }
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(InkColors.secondaryButtonBorder, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onTapGesture { tapChip(word) }
    }

    /// チップのタップ処理。選択済みならその語以降を解除し、未選択なら正解の順序に一致する時だけ受け付ける。
    private func tapChip(_ word: String) {
        if let index = selectedWords.firstIndex(of: word) {
            selectedWords.removeSubrange(index...)
            return
        }
        guard selectedWords.count < answerWords.count, word == answerWords[selectedWords.count] else { return }
        selectedWords.append(word)
    }
}

/// チップなどを左詰めで折り返し配置するフローレイアウト。
struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 9

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + spacing + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += (x > 0 ? spacing : 0) + size.width
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingPhraseConfirmView(phrase: SampleData.mnemonic)
}
