import SwiftUI
import LicenseList

/// ライブラリ1件のライセンス本文画面。本文中の URL のリンク化は LicenseList の LicenseView に任せる。
struct LicenseDetailPage: View {
    let library: Library

    @Environment(\.paperColor) private var paperColor

    var body: some View {
        ZStack {
            paperColor.ignoresSafeArea()
            VStack(spacing: 0) {
                LicenseView(library: library)
                    // 既定のスタイルはリポジトリリンクをナビゲーションバーへ載せるが、
                    // この画面のナビゲーションバーはライブラリ名だけを見せる場所にしたいため、リンクを持たない .plain にする。
                    .licenseViewStyle(.plain)
            }
        }
        .inkNavigationBar(title: library.name)
    }
}

struct LicenseDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LicenseDetailPage(library: Library(name: "LicenseList", url: "https://github.com/cybozu/LicenseList", licenseBody: "MIT License\n\nCopyright (c) 2022 Cybozu"))
        }
    }
}
