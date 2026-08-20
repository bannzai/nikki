import SwiftUI
import LicenseList

/// 一覧に表示する OSS。LicenseList の BuildToolPlugin が SwiftPM の依存関係(SourcePackages)から
/// 収集したものへ、SwiftPM 経由ではない同梱フォントを加える。
private let licenseLibraries: [Library] = {
    // 同梱フォント Zen Kaku Gothic New はバンドルへコピーされる OFL.txt を本文の正とする。
    if let oflURL = Bundle.main.url(forResource: "OFL", withExtension: "txt"),
       let ofl = try? String(contentsOf: oflURL, encoding: .utf8) {
        return Library.libraries + [
            Library(
                name: "Zen Kaku Gothic New",
                // OFL.txt の著作権表記が挙げるプロジェクトのリポジトリ。
                url: "https://github.com/googlefonts/zen-kakugothic",
                licenseBody: ofl
            )
        ]
    }
    return Library.libraries
}()

/// OSS ライセンス一覧画面。
struct LicensePage: View {
    /// 本文を表示するライブラリ。行のタップで決まる。
    @State var selectedLibrary: Library?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title(String(localized: "Open source licenses")), onLeading: { dismiss() })
                ScrollView {
                    // LicenseList の LicenseListView は List + NavigationLink で一覧を組むが、その行のタップは
                    // RootPage が自動ロック用に張る simultaneousGesture(DragGesture) に奪われて本文へ遷移しない。
                    // 他画面と同じ InkListRow(Button) なら同じジェスチャ下でも遷移できるため、一覧はアプリ側で組む。
                    InkListSection {
                        ForEach(licenseLibraries) { library in
                            InkListRow(
                                title: library.name,
                                showsSeparator: library.id != licenseLibraries.last?.id,
                                action: { selectedLibrary = library }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
        .inkNavigationBarHidden()
        .navigationDestination(item: $selectedLibrary) { library in
            LicenseDetailPage(library: library)
        }
    }
}

struct LicensePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LicensePage()
        }
    }
}
