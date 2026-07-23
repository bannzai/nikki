import SwiftUI

/// ホーム上部のヘッダ。左に「Nikki」ロゴ、右に人物アイコンボタンを置く。
/// アカウント画面は未実装のため、人物アイコンは設定画面(1r)への入り口にしている。
struct HomeHeader: View {
    /// 設定画面(1r)への遷移状態。
    @State var settingsIsPresented = false

    var body: some View {
        HStack(spacing: 0) {
            Text("Nikki")
                .font(.inkScreenTitle)
                .tracking(20 * 0.03)
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
            Button {
                settingsIsPresented = true
            } label: {
                Image(systemName: "person")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color(hex: 0x52514E))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .navigationDestination(isPresented: $settingsIsPresented) {
            SettingsPage()
        }
    }
}

struct HomeHeader_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeHeader()
                .padding()
                .background(Color.inkPaper)
        }
    }
}
