import SwiftUI
import LicenseList

/// ライブラリ1件のライセンス本文画面。本文中の URL のリンク化は LicenseList の LicenseView に任せる。
struct LicenseDetailPage: View {
    let library: Library

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title(library.name), onLeading: { dismiss() })
                LicenseView(library: library)
                    // 既定のスタイルが持つリポジトリリンクはナビゲーションバー上に出るが、
                    // 本アプリはナビゲーションバーを隠して InkNavBar を使うため表示されない。
                    .licenseViewStyle(.plain)
            }
        }
        .inkNavigationBarHidden()
    }
}

struct LicenseDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LicenseDetailPage(library: Library(name: "LicenseList", url: "https://github.com/cybozu/LicenseList", licenseBody: "MIT License\n\nCopyright (c) 2022 Cybozu"))
        }
    }
}
