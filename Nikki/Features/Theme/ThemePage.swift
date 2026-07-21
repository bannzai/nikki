import SwiftUI

/// テーマ設定画面(1n)。選択中の紙色をライブプレビューに反映し、紙色スウォッチと背景画像の選択を提供する。
/// 外観(ライト/ダーク)トグルは持たない — ライト固定。
struct ThemePage: View {
    /// 紙色プリセットの選択状態。プレビューの地色とスウォッチの選択表示に連動する。
    @State var selectedPreset: PaperColorPreset

    // @State selectedPreset の初期値を selected 引数から決めるため custom init を用いる。
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
                        ThemePreviewCard(paperColor: selectedPreset.color)
                            .padding(.bottom, 22)
                        ThemeSectionLabel(text: "紙の色")
                            .padding(.bottom, 10)

                        HStack(spacing: 14) {
                            ForEach(PaperColorPreset.allCases) { preset in
                                ThemeColorSwatch(preset: preset, isSelected: preset == selectedPreset) {
                                    selectedPreset = preset
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24)

                        ThemeSectionLabel(text: "背景画像")
                            .padding(.bottom, 10)
                        ThemeBackgroundImageCard()
                            .padding(.bottom, 24)

                        Text("テーマはこの端末の中だけに保存されます。")
                            .font(InkTypography.font(11.5, .regular))
                            .lineSpacing(InkTypography.lineSpacing(fontSize: 11.5, multiplier: 1.9))
                            .foregroundStyle(InkColors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}
