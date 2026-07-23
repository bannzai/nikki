import SwiftUI

/// ペイウォール上部のロゴ「日」+「Nikki Plus」ヘッダ。
struct PaywallHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("日")
                .font(.ink(18, .bold))
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
