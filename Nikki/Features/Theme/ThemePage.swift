import SwiftUI

/// テーマ設定画面(1n)。選択中の紙色をライブプレビューに反映し、紙色スウォッチと背景画像の選択を提供する。
/// 選択は AppStorage へ永続化する。外観(ライト/ダーク)トグルは持たない — ライト固定。
struct ThemePage: View {
    // 見本(1n)の初期選択が「生成」(プリセット2番目)のため。
    @AppStorage(.paperColorPresetIndex) var paperColorPresetIndex: Int = 1

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // 保存済みの index がプリセットの範囲外(将来のプリセット変更等)でも落ちないよう既定の「生成」に倒す。
        let paperColor = Color.paperColorPreset.indices.contains(paperColorPresetIndex)
            ? Color.paperColorPreset[paperColorPresetIndex]
            : Color.paperColorPreset[1]
        ZStack {
            Color.inkPaper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("テーマ"), onLeading: { dismiss() })
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ThemePreviewCard(paperColor: paperColor)
                            .padding(.bottom, 22)
                        ThemeSectionLabel(text: "紙の色")
                            .padding(.bottom, 10)

                        HStack(spacing: 14) {
                            ForEach(Color.paperColorPreset.indices, id: \.self) { index in
                                ThemeColorSwatch(
                                    index: index,
                                    label: paperColorPresetLabel(index: index),
                                    selectedIndex: $paperColorPresetIndex
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
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// 紙色プリセットの表示名(Color.paperColorPreset と同順)。
/// テーマ画面のスウォッチと設定画面(1r)の「テーマ」行の値表示で使う。
func paperColorPresetLabel(index: Int) -> String {
    switch index {
    case 0: return "白"
    case 1: return "生成"
    case 2: return "薄鼠"
    case 3: return "青磁"
    case 4: return "桜鼠"
    default: return ""
    }
}
