import SwiftUI

/// テーマ設定画面(1n)。選択中の紙色をライブプレビューに反映し、紙色スウォッチと背景画像の選択を提供する。
/// 外観(ライト/ダーク)トグルは持たない — ライト固定。
struct ThemeSettingsView: View {
    /// 紙色プリセットの選択状態。プレビューの地色とスウォッチの選択表示に連動する。
    @State private var selectedPreset: PaperColorPreset

    init(selected: PaperColorPreset = .ecru) {
        _selectedPreset = State(initialValue: selected)
    }

    var body: some View {
        ZStack {
            InkColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("テーマ"), onLeading: {})
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        previewCard
                            .padding(.bottom, 22)
                        sectionLabel("紙の色")
                            .padding(.bottom, 10)
                        swatchRow
                            .padding(.bottom, 24)
                        sectionLabel("背景画像")
                            .padding(.bottom, 10)
                        backgroundImageCard
                            .padding(.bottom, 24)
                        noteText
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    /// 選択中の紙色を地にしたライブプレビュー。見出し + 本文のサンプルを表示する。
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("プレビュー")
                .font(InkTypography.font(11, .regular))
                .foregroundStyle(InkColors.textTertiary)
                .padding(.bottom, 10)
            Text("梅雨明け")
                .font(InkTypography.font(18, .bold))
                .foregroundStyle(InkColors.ink)
                .padding(.bottom, 8)
            Text("朝から蝉が鳴いていた。今年も夏が来たんだなと思う。")
                .font(InkTypography.font(13, .regular))
                .lineSpacing(InkTypography.lineSpacing(fontSize: 13, multiplier: 2.0))
                .foregroundStyle(InkColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 22, leading: 24, bottom: 22, trailing: 24))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selectedPreset.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(InkColors.border, lineWidth: 1)
        )
    }

    /// 紙色プリセット5種の丸スウォッチを横並びで表示する。タップで選択を切り替える。
    private var swatchRow: some View {
        HStack(spacing: 14) {
            ForEach(PaperColorPreset.allCases) { preset in
                ThemeColorSwatch(preset: preset, isSelected: preset == selectedPreset) {
                    selectedPreset = preset
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 背景画像の選択リスト。「写真から選ぶ」(no-op)と現在選択中の「なし」。
    private var backgroundImageCard: some View {
        InkListSection {
            InkListRow("写真から選ぶ", action: {})
            noneRow
        }
    }

    /// 「なし」を現在の背景選択として示す行。文字は鈍色、右端にチェック。
    private var noneRow: some View {
        HStack(spacing: 8) {
            Text("なし")
                .font(InkTypography.font(14.5, .regular))
                .foregroundStyle(InkColors.textSecondary)
            Spacer(minLength: 8)
            Image(systemName: InkIcons.checkmark)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(InkColors.ink)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
    }

    /// 末尾の保存に関する注記。
    private var noteText: some View {
        Text("テーマはこの端末の中だけに保存されます。")
            .font(InkTypography.font(11.5, .regular))
            .lineSpacing(InkTypography.lineSpacing(fontSize: 11.5, multiplier: 1.9))
            .foregroundStyle(InkColors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// セクション見出し(紙の色 / 背景画像)のスタイル。
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(InkTypography.font(12, .bold))
            .foregroundStyle(InkColors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 紙色プリセット1つを表す丸スウォッチ + ラベル。選択中は墨枠とチェックを表示する。
struct ThemeColorSwatch: View {
    let preset: PaperColorPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(preset.color)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: InkIcons.checkmark)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(InkColors.ink)
                        }
                    }
                Text(preset.label)
                    .font(InkTypography.font(11, isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? InkColors.ink : InkColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    /// 非選択時の枠色。白は紙地(#FAFAF9)に対して輪郭が沈むため、他色(0.08)より濃い 0.12 の枠にする。
    private var borderColor: Color {
        if isSelected { return InkColors.ink }
        return preset == .white ? Color.black.opacity(0.12) : InkColors.border
    }
}
