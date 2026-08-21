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
        let paperColor = effectivePaperColor(storedIndex: paperColorPresetIndex, plusActive: plusActive)
        ZStack {
            paperColor.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title(String(localized: "Theme")), onLeading: { dismiss() })
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ThemePreviewCard(paperColor: paperColor)
                            .padding(.bottom, 22)
                        ThemeSectionLabel(text: String(localized: "Paper color"))
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

                        ThemeSectionLabel(text: String(localized: "Background image"))
                            .padding(.bottom, 10)
                        ThemeBackgroundImageCard()
                            .padding(.bottom, 24)

                        Text("Your theme is saved only on this device.")
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
        .inkNavigationBarHidden()
        .sheet(isPresented: $paywallSheetIsPresented) {
            PaywallPage()
        }
    }
}

/// 紙色プリセットの表示名(Color.paperColorPreset と同順)。
/// テーマ画面のスウォッチと設定画面(1r)の「テーマ」行の値表示で使う。
func paperColorPresetLabel(index: Int) -> String {
    switch index {
    case 0: return String(localized: "White")
    case 1: return String(localized: "Cream")
    case 2: return String(localized: "Ash")
    case 3: return String(localized: "Celadon")
    case 4: return String(localized: "Sakura")
    default: return ""
    }
}

/// 紙色プリセットが Nikki Plus 限定かどうか。
/// 無料の範囲は白・生成(先頭2つ)。既定の「生成」を無課金のまま使い続けられるようにしつつ、それ以降をプレミアムテーマとして解放境界にする。
func paperColorPresetRequiresPlus(index: Int) -> Bool {
    index >= 2
}

/// 実際に適用する紙色プリセットの添字。Plus が無効な間は Plus 限定の保存値を無料の既定「生成」(index 1)へ倒す。
/// 保存済みの index がプリセットの範囲外(将来のプリセット変更等)の場合も、表示名・スウォッチ・紙色のどの利用側でも落ちないよう「生成」へ倒す。
/// 保存値自体は書き換えない(再加入した時に元の選択へ戻すため)。
func effectivePaperColorPresetIndex(storedIndex: Int, plusActive: Bool) -> Int {
    if !Color.paperColorPreset.indices.contains(storedIndex) {
        return 1
    }
    if paperColorPresetRequiresPlus(index: storedIndex) && !plusActive {
        return 1
    }
    return storedIndex
}

/// 実際に紙地へ適用する紙色。effectivePaperColorPresetIndex で正規化した添字のプリセット色。
func effectivePaperColor(storedIndex: Int, plusActive: Bool) -> Color {
    Color.paperColorPreset[effectivePaperColorPresetIndex(storedIndex: storedIndex, plusActive: plusActive)]
}
