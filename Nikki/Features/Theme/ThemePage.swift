import SwiftUI

/// テーマ設定画面(1n)。選択中の紙色をライブプレビューに反映し、紙色スウォッチと背景画像の選択を提供する。
/// 外観(ライト/ダーク)トグルは持たない — ライト固定。
struct ThemePage: View {
    /// 紙色プリセットの選択状態。プレビューの地色とスウォッチの選択表示に連動する。初期値は呼び出し側が決める。
    @State var selectedPaperColor: Color

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("テーマ"), onLeading: {})
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ThemePreviewCard(paperColor: selectedPaperColor)
                            .padding(.bottom, 22)
                        ThemeSectionLabel(text: "紙の色")
                            .padding(.bottom, 10)

                        HStack(spacing: 14) {
                            ForEach(Array(Color.paperColorPreset.enumerated()), id: \.offset) { index, paperColor in
                                ThemeColorSwatch(
                                    paperColor: paperColor,
                                    label: swatchLabel(at: index),
                                    isSelected: paperColor == selectedPaperColor,
                                    action: { selectedPaperColor = paperColor }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24)

                        ThemeSectionLabel(text: "背景画像")
                            .padding(.bottom, 10)
                        ThemeBackgroundImageCard()
                            .padding(.bottom, 24)

                        Text("テーマはこの端末の中だけに保存されます。")
                            .font(.ink(11.5))
                            .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                            .foregroundStyle(Color.inkTextTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    /// スウォッチ下に表示する紙色プリセットの表示名(Color.paperColorPreset と同順)。
    private func swatchLabel(at index: Int) -> String {
        switch index {
        case 0: return "白"
        case 1: return "生成"
        case 2: return "薄鼠"
        case 3: return "青磁"
        case 4: return "桜鼠"
        default: return ""
        }
    }
}
