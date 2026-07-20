import SwiftUI

/// 新しい端末で復元フレーズ(12語)を順番に入力して日記を取り戻す画面(デザイン ID 1p)。
/// 候補チップのタップで現在のスロットへ単語を入れて次へ進む。実キーボード入力は扱わない。
struct RestoreView: View {
    let suggestions: [String]
    var onRestore: () -> Void

    /// 先頭から順に確定した単語。要素数が現在の入力位置(= 次に入力するスロットの index)になる。
    @State private var enteredWords: [String] = []

    /// 復元フレーズのスロット総数。
    private let slotCount = 12

    init(suggestions: [String] = SampleData.restoreSuggestions, onRestore: @escaping () -> Void = {}) {
        self.suggestions = suggestions
        self.onRestore = onRestore
    }

    /// 12スロットすべてが埋まり、復元を実行できる状態か。
    private var isComplete: Bool { enteredWords.count >= slotCount }

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("おかえりなさい。")
                    .inkTextStyle(InkTypography.onboardingHeadline)
                    .foregroundStyle(InkColors.ink)

                Text("あの12の言葉を、順番どおりに。日記はこの端末の中で、もう一度開かれます。")
                    .font(InkTypography.font(13, .regular))
                    .lineSpacing(InkTypography.lineSpacing(fontSize: 13, multiplier: 2))
                    .foregroundStyle(InkColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                slotGrid
                    .padding(.top, 26)
                    .padding(.bottom, 14)

                suggestionChips

                Spacer(minLength: 24)

                Text("大文字・小文字は気にしなくて大丈夫です")
                    .font(InkTypography.font(11.5, .regular))
                    .foregroundStyle(InkColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 14)

                InkPrimaryButton("復元する", isEnabled: isComplete, action: onRestore)
            }
            .padding(.horizontal, 28)
            .padding(.top, 44)
            .padding(.bottom, 8)
        }
    }

    /// 12スロットの2列グリッド。入力位置より前は確定単語、入力位置は墨枠+カーソル、以降は空。
    private var slotGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(0..<slotCount, id: \.self) { index in
                RestoreSlotCell(
                    number: index + 1,
                    word: index < enteredWords.count ? enteredWords[index] : nil,
                    isCurrent: index == enteredWords.count,
                    onTap: index == enteredWords.count - 1 ? { removeLastWord() } : nil
                )
            }
        }
    }

    /// オートコンプリート候補チップ群。suggestions を左寄せで横並びにする。
    private var suggestionChips: some View {
        HStack(spacing: 8) {
            ForEach(suggestions, id: \.self) { word in
                RestoreSuggestionChip(word: word) { fill(word) }
            }
            Spacer(minLength: 0)
        }
    }

    /// 現在の入力位置へ単語を確定し、次のスロットへ進める。
    /// タップのたびに1語追加するイベントハンドラのため冪等ではない。
    private func fill(_ word: String) {
        guard enteredWords.count < slotCount else { return }
        enteredWords.append(word)
    }

    /// 直近に確定した単語(最後のスロット)を取り消して誤入力を戻す。
    private func removeLastWord() {
        guard !enteredWords.isEmpty else { return }
        enteredWords.removeLast()
    }
}

/// 復元フレーズの1スロットを表す白カード。番号 + 状態(確定単語 / 入力中カーソル / 空)を描く。
private struct RestoreSlotCell: View {
    let number: Int
    let word: String?
    let isCurrent: Bool
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 9) {
            Text("\(number)")
                .font(InkTypography.mono(11))
                .foregroundStyle(InkColors.textTertiary)
                .frame(width: 14, alignment: .leading)

            if let word {
                Text(word)
                    .font(InkTypography.monoWord)
                    .foregroundStyle(InkColors.ink)
            } else if isCurrent {
                RestoreCursor()
            }

            Spacer(minLength: 0)
        }
        .frame(height: 18)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(InkColors.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isCurrent ? InkColors.ink : InkColors.border, lineWidth: isCurrent ? 1.5 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture { onTap?() }
    }
}

/// オートコンプリート候補チップ。タップで現在のスロットへ単語を入れる。
private struct RestoreSuggestionChip: View {
    let word: String
    let action: () -> Void

    var body: some View {
        Text(word)
            .font(InkTypography.mono(13, weight: .medium))
            .foregroundStyle(InkColors.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(InkColors.secondaryButtonBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onTapGesture { action() }
    }
}

/// 入力中スロットに表示する 2px 幅の墨色カーソル。点滅でテキスト入力位置を示す。
private struct RestoreCursor: View {
    @State private var visible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(InkColors.ink)
            .frame(width: 2, height: 16)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}
