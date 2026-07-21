import SwiftUI

/// 設定画面(1r)。iOS 標準のグループ化リスト形式で各設定項目を表示する。
struct SettingsPage: View {
    /// Face ID で解除するかどうか。既定値は見本(1r)が ON 状態のため true。
    @State var faceIDUnlockEnabled = true

    var body: some View {
        ZStack(alignment: .top) {
            InkColors.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("設定"))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsSectionLabel(text: "書くこと")
                        InkListSection {
                            InkListRow("既定のテンプレート", value: "一日の振り返り")
                            InkListRow("自動ロック", value: "5秒", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "鍵")
                        InkListSection {
                            InkListRow("Face ID で解除", trailing: AnyView(SettingsToggle(isOn: $faceIDUnlockEnabled)))
                            InkListRow("パスキー", value: "登録済み", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "外観")
                        InkListSection {
                            InkListRow("テーマ", value: "生成")
                            InkListRow("文字の大きさ", value: "標準", showsSeparator: false)
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "データ")
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
}
