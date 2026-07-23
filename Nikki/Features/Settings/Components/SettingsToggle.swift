import SwiftUI

/// 設定画面の墨色トグル(44×26・墨地・白ノブ)。見本(1r)の COMPONENTS 形状に合わせた自作トグル。
struct SettingsToggle: View {
    /// トグルの ON/OFF 状態。
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { isOn.toggle() }
        } label: {
            Capsule()
                .fill(isOn ? Color.ink : Color.inkDisabledBackground)
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

struct SettingsToggle_Previews: PreviewProvider {
    static var previews: some View {
        SettingsToggle(isOn: .constant(true))
            .padding()
            .background(Color.inkPaper)
    }
}
