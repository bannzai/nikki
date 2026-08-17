import XCTest

/// App Store スクリーンショット(iPhone / iPad)の撮影テスト。
/// 環境変数 NIKKI_SCREEN でスクショページを直接起動し、シミュレータのネイティブ解像度で
/// 全画面スクリーンショットを XCTAttachment として保存する。
/// 実行は scripts/generate_screenshots/ のパイプラインから行い、xcresult から画像を抽出する。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// init / setUp をオーバーライドできずビルドが通らないため、クラスは nonisolated にする(ContextMenuUITests と同じ)。
nonisolated final class AppStoreScreenshotSnapshotUITests: XCTestCase {
    override func setUp() {
        // 起動に失敗した時点で後続の撮影に意味がないため、最初の失敗で止める。
        continueAfterFailure = false
    }

    @MainActor
    func testSnapshot() throws {
        // 撮影の再現性のため、アプリのデザイン(ライト固定)と縦向きに揃える。
        XCUIDevice.shared.appearance = .light
        #if !os(macOS)
        XCUIDevice.shared.orientation = .portrait
        #endif

        for language in filteredLanguages() {
            for page in filteredPages() {
                let app = XCUIApplication()
                app.launchEnvironment["NIKKI_SCREEN"] = page
                app.launchEnvironment["NIKKI_APPSTORE_LANG"] = language
                app.launch()
                // カスタムフォントの適用とレイアウト確定を待つ。
                sleep(1)

                // OS の通知バナー(Apple Intelligence の案内等)が画面上部に写り込むことがあるため、
                // 出ていたら自動で消えるまで待ってから撮影する(実測でバナーが1枚に写り込んだ対策)。
                let banner = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                    .otherElements["NotificationShortLookView"]
                    .firstMatch
                if banner.waitForExistence(timeout: 0.5) {
                    _ = banner.waitForNonExistence(timeout: 15)
                }

                let attachment = XCTAttachment(screenshot: app.screenshot())
                // organize スクリプトが「---」区切りでページ・言語をパースするための命名。
                attachment.name = "AppStoreScreenshot---\(page)---\(language)---0"
                attachment.lifetime = .keepAlways
                add(attachment)

                app.terminate()
            }
        }
    }

    /// 撮影する言語。環境変数 SNAPSHOT_LANGUAGES(カンマ区切り)で絞り込める。未指定は日英の全言語。
    private func filteredLanguages() -> [String] {
        let all = ["ja", "en"]
        if let raw = ProcessInfo.processInfo.environment["SNAPSHOT_LANGUAGES"], !raw.isEmpty {
            return raw.split(separator: ",").map(String.init).filter { all.contains($0) }
        }
        return all
    }

    /// 撮影するページ(Screen の rawValue)。環境変数 SNAPSHOT_PAGES(カンマ区切りの番号)で絞り込める。未指定は全6ページ。
    private func filteredPages() -> [String] {
        let all = (1...6).map { "appstore\($0)" }
        if let raw = ProcessInfo.processInfo.environment["SNAPSHOT_PAGES"], !raw.isEmpty {
            return raw.split(separator: ",").map { "appstore\($0)" }.filter { all.contains($0) }
        }
        return all
    }
}
