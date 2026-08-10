import SwiftUI

/// ペイウォール上部の日記帳アイコン +「Nikki Plus」ヘッダ。
struct PaywallHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            // 枠線の太さに負けて薄く見えないよう weight を上げる (OnboardingLogoMark と同じ調整)。
            Image(systemName: InkIcons.book)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.ink, lineWidth: 2)
                )
            Text("Nikki Plus")
                .font(.ink(22, .bold))
                .tracking(0.44)
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
        }
    }
}

struct PaywallHeader_Previews: PreviewProvider {
    static var previews: some View {
        PaywallHeader()
            .padding()
            .background(Color.inkPaper)
    }
}
