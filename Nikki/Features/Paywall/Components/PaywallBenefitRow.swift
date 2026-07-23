import SwiftUI

/// 特典1件(チェック + タイトル + 説明)。
struct PaywallBenefitRow: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: InkIcons.checkmark)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ink)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ink(14.5, .bold))
                    .foregroundStyle(Color.ink)
                Text(description)
                    .font(.ink(12.5, .regular))
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
            }
            Spacer(minLength: 0)
        }
    }
}

struct PaywallBenefitRow_Previews: PreviewProvider {
    static var previews: some View {
        PaywallBenefitRow(title: "複数端末で同期", description: "iPhone・Mac・Web。暗号化されたまま届きます。")
            .padding()
            .background(Color.inkPaper)
    }
}
