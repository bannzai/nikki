import SwiftUI

/// テーマ設定画面(1n)。選択中の紙色をライブプレビューに反映し、紙色スウォッチと背景画像の選択を提供する。
/// 選択は AppStorage へ永続化する。外観(ライト/ダーク)トグルは持たない — ライト固定。
struct ThemePage: View {
    // 見本(1n)の初期選択が「生成」(プリセット2番目)のため。
    @AppStorage(.paperColorPresetIndex) var paperColorPresetIndex: Int = 1

    @State var paywallSheetIsPresented = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.plusActive) private var plusActive

    var body: some View {
        // Plus 失効後は保存値を残したまま無料範囲へ倒した添字で表示する(再加入で元の選択に戻る)。
        let effectiveIndex = effectivePaperColorPresetIndex(storedIndex: paperColorPresetIndex, plusActive: plusActive)
        // 保存済みの index がプリセットの範囲外(将来のプリセット変更等)でも落ちないよう既定の「生成」に倒す。
        let paperColor = Color.paperColorPreset.indices.contains(effectiveIndex)
            ? Color.paperColorPreset[effectiveIndex]
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
                                    // 選択中の見た目も失効時のフォールバック(effectiveIndex)に合わせるため、保存値を直接渡さない。
                                    selectedIndex: Binding(
                                        get: { effectivePaperColorPresetIndex(storedIndex: paperColorPresetIndex, plusActive: plusActive) },
                                        set: { paperColorPresetIndex = $0 }
                                    ),
                                    locked: paperColorPresetRequiresPlus(index: index) && !plusActive,
                                    paywallSheetIsPresented: $paywallSheetIsPresented
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
        .sheet(isPresented: $paywallSheetIsPresented) {
            PaywallPage()
        }
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

/// 紙色プリセットが Nikki Plus 限定かどうか。
/// 無料の範囲は白・生成(先頭2つ)。既定の「生成」を無課金のまま使い続けられるようにしつつ、それ以降をプレミアムテーマとして解放境界にする。
func paperColorPresetRequiresPlus(index: Int) -> Bool {
    index >= 2
}

/// 実際に適用する紙色プリセットの添字。Plus が無効な間は Plus 限定の保存値を無料の既定「生成」(index 1)へ倒す。
/// 保存値自体は書き換えない(再加入した時に元の選択へ戻すため)。
func effectivePaperColorPresetIndex(storedIndex: Int, plusActive: Bool) -> Int {
    if paperColorPresetRequiresPlus(index: storedIndex) && !plusActive {
        return 1
    }
    return storedIndex
}
