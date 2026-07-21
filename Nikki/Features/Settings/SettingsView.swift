import SwiftUI

/// 設定画面(1r)。iOS 標準のグループ化リスト形式で各設定項目を表示する。
struct SettingsView: View {
    /// Face ID で解除するかどうか。既定値は見本(1r)が ON 状態のため true。
    @State var faceIDUnlockEnabled = true

    var body: some View {
        ZStack(alignment: .top) {
            InkColors.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("設定"))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionLabel("書くこと")
                        InkListSection {
                            InkListRow("既定のテンプレート", value: "一日の振り返り")
                            InkListRow("自動ロック", value: "5秒", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        sectionLabel("鍵")
                        InkListSection {
                            InkListRow("Face ID で解除", trailing: AnyView(SettingsToggle(isOn: $faceIDUnlockEnabled)))
                            InkListRow("パスキー", value: "登録済み", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        sectionLabel("外観")
                        InkListSection {
                            InkListRow("テーマ", value: "生成")
                            InkListRow("文字の大きさ", value: "標準", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        sectionLabel("データ")
                        InkListSection {
                            InkListRow("Markdown で書き出す")
                            InkListRow("Nikki Plus", value: "未加入", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        Text("Nikki 1.0.0 — あなたの日記は、この端末の中に。")
                            .font(InkTypography.font(11, .regular))
                            .foregroundStyle(InkColors.textQuaternary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
    }

    /// グループ化リストのセクション見出し(小さな灰色ラベル)。
    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(InkTypography.font(12, .medium))
            .foregroundStyle(InkColors.textTertiary)
            .padding(.horizontal, 2)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 設定画面の墨色トグル(44×26・墨地・白ノブ)。見本(1r)の COMPONENTS 形状に合わせた自作トグル。
struct SettingsToggle: View {
    /// トグルの ON/OFF 状態。
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { isOn.toggle() }
        } label: {
            Capsule()
                .fill(isOn ? InkColors.ink : InkColors.disabledBackground)
                .frame(width: 44, height: 26)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(.leading, 2)
                        .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                        .offset(x: isOn ? 18 : 0)
                }
        }
        .buttonStyle(.plain)
    }
}
