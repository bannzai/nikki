import SwiftUI

/// 自動ロックのカスタム秒数の入力欄(AutoLockPage の「カスタム」行の trailing)。
/// 保存できる値(autoLockCustomSecondsRange の整数)を入力したときだけ保存値へ書き戻し、
/// 途中入力・空・範囲外では保存値を変えない(直前の設定のままロックし続ける)。
struct AutoLockCustomSecondsField: View {
    @Binding var customSecondsText: String
    @Binding var autoLockSeconds: Int

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
                .onChange(of: customSecondsText) {
                    if let seconds = Int(customSecondsText), autoLockCustomSecondsRange.contains(seconds) {
                        autoLockSeconds = seconds
                    }
                }
            Text("seconds")
                .font(.ink(13.5, .regular))
                .foregroundStyle(Color.inkTextSecondary)
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
