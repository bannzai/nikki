import SwiftUI

/// 自動ロック秒数のプリセット(設定 > 自動ロック)。既定の5秒(README)を最短に、離席しがちな使い方向けの緩い選択肢を並べる。
let autoLockPresetSeconds = [5, 10, 30, 60]

/// 設定 > 自動ロック の選択画面。無操作でロックするまでの秒数をプリセットから選ぶ。
/// 1秒きざみの自由入力(カスタム)は Nikki Plus 限定で、未加入のタップはペイウォールを開く。
/// macOS の confirmationDialog(NSAlert)はボタン4個までしか出せず、プリセット+カスタムが収まらないため一覧画面で選ぶ。
struct AutoLockPage: View {
    // README の「5秒タイプがなかったらロック」に合わせた既定値。
    @AppStorage(.autoLockSeconds) var autoLockSeconds: Int = 5

    /// カスタム秒数の入力バッファ。確定できる値のときだけ保存値へ書き戻し、途中入力では保存値を変えない。
    @State var customSecondsText: String = ""

    @State var paywallSheetIsPresented = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.paperColor) private var paperColor
    @Environment(\.plusActive) private var plusActive

    var body: some View {
        // Plus 失効中はプリセット外の保存値を既定へ倒した実効値で選択中を見せる(実際のロックも同じ値で動く)。
        let effectiveSeconds = effectiveAutoLockSeconds(storedSeconds: autoLockSeconds, plusActive: plusActive)
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title(String(localized: "Auto-lock")), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    InkListSection {
                        ForEach(autoLockPresetSeconds, id: \.self) { seconds in
                            InkListRow(
                                title: String(localized: "\(seconds) seconds"),
                                showsChevron: false,
                                trailing: effectiveSeconds == seconds
                                    ? AnyView(
                                        Image(systemName: InkIcons.checkmark)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Color.ink)
                                    )
                                    : nil,
                                action: {
                                    autoLockSeconds = seconds
                                    customSecondsText = ""
                                }
                            )
                        }
                        if plusActive {
                            // TextField が行内の操作のため action は持たせず、入力の確定だけで保存する。
                            InkListRow(
                                title: String(localized: "Custom"),
                                showsChevron: false,
                                showsSeparator: false,
                                trailing: AnyView(AutoLockCustomSecondsField(
                                    customSecondsText: $customSecondsText,
                                    autoLockSeconds: $autoLockSeconds
                                ))
                            )
                        } else {
                            InkListRow(
                                title: String(localized: "Custom"),
                                showsChevron: false,
                                showsSeparator: false,
                                trailing: AnyView(
                                    Image(systemName: InkIcons.lock)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.inkTextSecondary)
                                ),
                                action: { paywallSheetIsPresented = true }
                            )
                        }
                    }

                    Text("With Nikki Plus, set the seconds until auto-lock exactly how you like, down to the second.")
                        .font(.ink(11.5, .regular))
                        .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                        .foregroundStyle(Color.inkTextTertiary)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .background(paperColor.ignoresSafeArea())
        .inkNavigationBarHidden()
        .sheet(isPresented: $paywallSheetIsPresented) {
            PaywallPage()
        }
        .onAppear {
            // カスタム秒数を使っているときは、開き直しても入力欄に現在値が見えるようにする。
            if !autoLockPresetSeconds.contains(autoLockSeconds) {
                customSecondsText = String(autoLockSeconds)
            }
        }
    }
}

/// 自動ロックのカスタム秒数として保存できる範囲。
/// 下限はプレミアム機能「1秒きざみ」の最小単位、上限は1時間(それ以上は実質ロックしないのと同じで、
/// 開きっぱなしの端末を守る機能として意味を失うため)。
let autoLockCustomSecondsRange = 1...3600

/// 実際に自動ロックへ適用する秒数。1秒きざみの自由入力は Nikki Plus 限定のため、
/// 未加入の間はプリセット外の保存値を既定の5秒(README)へ倒す。保存値自体は書き換えない(再加入で元の設定に戻すため)。
/// プライバシーを守る機能のため、フォールバックは長い側ではなく最短の既定値にする。
/// 保存値が範囲外(将来のバージョンが書いた値の同期等)の場合も、ロックが止まらないよう同じ既定へ倒す。
func effectiveAutoLockSeconds(storedSeconds: Int, plusActive: Bool) -> Int {
    if autoLockPresetSeconds.contains(storedSeconds) {
        return storedSeconds
    }
    if plusActive && autoLockCustomSecondsRange.contains(storedSeconds) {
        return storedSeconds
    }
    return 5
}

struct AutoLockPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AutoLockPage()
        }
    }
}
