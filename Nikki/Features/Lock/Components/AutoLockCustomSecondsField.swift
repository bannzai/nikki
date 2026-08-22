import SwiftUI

/// 自動ロックのカスタム秒数の入力欄(AutoLockPage の「カスタム」行の trailing)。
/// 入力途中の接頭辞(「3601」と打つ途中の「360」等)を保存しないよう、保存は編集完了
/// (リターン・フォーカス喪失)時にだけ行い、値全体を検証してから書き戻す。
/// 範囲外・数値でない入力は保存値を変えず、入力欄を保存値の表示に戻す。
struct AutoLockCustomSecondsField: View {
    @Binding var customSecondsText: String
    @Binding var autoLockSeconds: Int

    /// 入力欄のフォーカス。フォーカスが外れたタイミングを編集完了として保存する。
    @FocusState var fieldIsFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            TextField(String(autoLockSeconds), text: $customSecondsText)
                .font(.ink(13.5, .regular))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
                // 「3600」の4桁が収まり、行の題を圧迫しない幅。
                .frame(width: 64)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .focused($fieldIsFocused)
                .onSubmit {
                    commitCustomSeconds()
                }
                .onChange(of: fieldIsFocused) {
                    if !fieldIsFocused {
                        commitCustomSeconds()
                    }
                }
            Text("seconds")
                .font(.ink(13.5, .regular))
                .foregroundStyle(Color.inkTextSecondary)
        }
    }

    /// 編集完了時に入力の全体を検証して保存する。空のまま(未入力・プリセット選択中)は何もしない。
    private func commitCustomSeconds() {
        if customSecondsText.isEmpty {
            return
        }
        if let seconds = Int(customSecondsText), autoLockCustomSecondsRange.contains(seconds) {
            autoLockSeconds = seconds
        } else {
            customSecondsText = String(autoLockSeconds)
        }
    }
}

struct AutoLockCustomSecondsField_Previews: PreviewProvider {
    static var previews: some View {
        AutoLockCustomSecondsField(customSecondsText: .constant("45"), autoLockSeconds: .constant(45))
            .padding()
            .background(Color.inkPaper)
    }
}
