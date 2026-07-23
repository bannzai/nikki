import SwiftUI

/// ホーム上部のヘッダ。左に「Nikki」ロゴ、右にアカウントアイコンボタンを置く。
struct HomeHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Nikki")
                .font(InkTypography.screenTitle)
                .tracking(20 * 0.03)
                .foregroundStyle(InkColors.ink)
            Spacer(minLength: 0)
            // アカウント画面は未実装のため、ボタンはまだ何もしない。
            Button(action: {}) {
                Image(systemName: "person")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color(hex: 0x52514E))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
    }
}
