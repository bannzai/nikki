import SwiftUI

/// オンボーディング 1c: 12 語の復元フレーズを 2 列グリッドで提示し、控えを促す。
struct OnboardingPhraseBackupView: View {
    let phrase: [String]
    var onSaved: () -> Void = {}
    var onLater: () -> Void = {}

    init(phrase: [String] = SampleData.mnemonic, onSaved: @escaping () -> Void = {}, onLater: @escaping () -> Void = {}) {
        self.phrase = phrase
        self.onSaved = onSaved
        self.onLater = onLater
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                InkStepIndicator(step: 2, total: 3)

                Text("12の言葉が、\n合鍵になります。")
                    .inkTextStyle(InkTypography.onboardingHeadline)
                    .foregroundStyle(InkColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                Text("端末を失くしたとき、日記を取り戻せるのはこの言葉だけ。紙に書いて、大切な場所へ。")
                    .font(InkTypography.font(13, .regular))
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 13, multiplier: 2.0))
                    .foregroundStyle(InkColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(phrase.enumerated()), id: \.offset) { index, word in
                        wordCell(number: index + 1, word: word)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                HStack(spacing: 10) {
                    Image(systemName: InkIcons.pen)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(InkColors.textTertiary)
                    Text("スクリーンショットではなく、紙がおすすめです")
                        .font(InkTypography.font(12, .regular))
                        .foregroundStyle(InkColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 18)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    InkPrimaryButton("書き留めました", action: onSaved)
                    InkTextLink("あとで設定する", action: onLater)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
    }

    private func wordCell(number: Int, word: String) -> some View {
        HStack(spacing: 9) {
            Text("\(number)")
                .font(InkTypography.mono(11))
                .foregroundStyle(InkColors.textTertiary)
                .frame(width: 14, alignment: .leading)
            Text(word)
                .font(InkTypography.mono(14, weight: .medium))
                .foregroundStyle(InkColors.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(InkColors.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(InkColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingPhraseBackupView(phrase: SampleData.mnemonic)
}
