import SwiftUI

/// ホーム上部のヘッダ。左に「Nikki」ロゴ、右に歯車アイコンボタンを置く。
/// 歯車アイコンは設定画面(1r)への入り口にしている(issue #92)。
/// カレンダーモードでは、リストのセグメントコントロールが出ないぶん、
/// ここにリスト追加ボタンを置く(issue #92)。
struct HomeHeader: View {
    /// 表示中のモード。カレンダーモードのときだけリスト追加ボタンを出す。
    let homePageMode: HomePageMode

    /// 設定画面(1r)への遷移状態。
    @State var settingsIsPresented = false
    /// 新しいリスト作成画面(NotebookCreatePage)への遷移状態。
    @State var notebookCreateIsPresented = false

    var body: some View {
        HStack(spacing: 0) {
            Text("Nikki")
                .font(.inkScreenTitle)
                .tracking(20 * 0.03)
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
            if homePageMode == .calendar {
                Button {
                    notebookCreateIsPresented = true
                } label: {
                    Image(systemName: InkIcons.add)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(hex: 0x52514E))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
            }
            Button {
                settingsIsPresented = true
            } label: {
                Image(systemName: InkIcons.settings)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color(hex: 0x52514E))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .navigationDestination(isPresented: $settingsIsPresented) {
            SettingsPage()
        }
        .navigationDestination(isPresented: $notebookCreateIsPresented) {
            NotebookCreatePage()
        }
    }
}

struct HomeHeader_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeHeader(homePageMode: .calendar)
                .padding()
                .background(Color.inkPaper)
        }
    }
}
