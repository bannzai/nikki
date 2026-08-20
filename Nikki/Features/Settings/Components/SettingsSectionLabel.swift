import SwiftUI

/// グループ化リストのセクション見出し(小さな灰色ラベル)。
struct SettingsSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.ink(12, .medium))
            .foregroundStyle(Color.inkTextTertiary)
            .padding(.horizontal, 2)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsSectionLabel_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSectionLabel(text: "Writing")
            .padding()
            .background(Color.inkPaper)
    }
}
