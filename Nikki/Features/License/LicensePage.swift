import SwiftUI
import LicenseList

/// OSS ライセンス一覧画面。ライブラリ名と本文は LicenseList の BuildToolPlugin が
/// SwiftPM の依存関係(SourcePackages)から収集したものを表示する。
struct LicensePage: View {
    /// 本文を表示するライブラリ。行のタップで決まる。
    @State var selectedLibrary: Library?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.inkPaper.ignoresSafeArea()
            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("OSS ライセンス"), onLeading: { dismiss() })
                ScrollView {
                    // LicenseList の LicenseListView は List + NavigationLink で一覧を組むが、その行のタップは
                    // RootPage が自動ロック用に張る simultaneousGesture(DragGesture) に奪われて本文へ遷移しない。
                    // 他画面と同じ InkListRow(Button) なら同じジェスチャ下でも遷移できるため、一覧はアプリ側で組む。
                    InkListSection {
                        ForEach(Library.libraries) { library in
                            InkListRow(
                                title: library.name,
                                showsSeparator: library.id != Library.libraries.last?.id,
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
