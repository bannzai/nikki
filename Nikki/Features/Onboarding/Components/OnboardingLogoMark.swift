import SwiftUI

/// ようこそ画面のロゴマーク。角丸枠の日記帳アイコンとワードマーク「Nikki」を縦に並べる。
struct OnboardingLogoMark: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.ink, lineWidth: 2)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: InkIcons.book)
                        // 枠線 2px の太さに負けて薄く見えないよう、置き換え前の「日」(24pt bold) に合わせて semibold にする。
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.ink)
                }
            Text("Nikki")
                .font(.ink(30, .bold))
                .tracking(30 * 0.04)
                .foregroundStyle(Color.ink)
        }
    }
}

struct OnboardingLogoMark_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingLogoMark()
            .padding()
            .background(Color.inkPaper)
    }
}
