import XCTest

/// App Store スクリーンショット(iPhone / iPad / iPhone Duo)の撮影テスト。
/// 環境変数 NIKKI_SCREEN でスクショページを直接起動し、シミュレータのネイティブ解像度で
/// 全画面スクリーンショットを XCTAttachment として保存する。
/// 実行は scripts/generate_screenshots/ のパイプラインから行い、xcresult から画像を抽出する。
///
/// 通常の `xcodebuild test -scheme Nikki` にも含まれるが、パイプラインが渡す SNAPSHOT_ENABLED が無い時は
/// 何もせずスキップする(通常の UI テスト実行に 12 回のアプリ再起動と大型 attachment を足さないため)。
///
/// iPhone Duo の内側ディスプレイは XCTest の API では App Store の仕様の寸法で撮れないため
/// (appstore-screenshot-builder skill の references/iphone-duo.md)、パイプラインが SNAPSHOT_HOST_CAPTURE_DIR を
/// 渡した時は、ページを表示するたびにそのディレクトリへ `{attachment 名}.ready` を書き、ホスト側が
/// `xcrun simctl io <UDID> screenshot --display=primary-1` で撮って `{attachment 名}.done` を書くまで待つ
/// (simulator のテストランナーはホストのファイルシステムに書けるため、ファイルで同期する)。
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
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SNAPSHOT_ENABLED"] == "1",
            "スクリーンショット撮影は scripts/generate_screenshots/ のパイプラインからだけ実行する(SNAPSHOT_ENABLED=1)"
        )

        // パイプラインが撮影するキャンバスを指定した時だけアプリに引き渡す(iPhone Duo の外側・内側の区別に使う。
        // 未指定ならアプリがデバイスから判定する)。
        let canvas = ProcessInfo.processInfo.environment["SNAPSHOT_CANVAS"] ?? ""

        // 撮影の再現性のため、アプリのデザイン(ライト固定)と向きを揃える。
        // Duo の内側ディスプレイは開いた姿勢の simulator が横向き(landscapeRight)になるため横にし
        // (外側の撮影で縦にした向きが残らないように明示する)、それ以外は縦にする。
        XCUIDevice.shared.appearance = .light
        #if !os(macOS)
        XCUIDevice.shared.orientation = canvas == "duoInner" ? .landscapeRight : .portrait
        #endif

        for language in filteredLanguages() {
            for page in filteredPages() {
                let app = XCUIApplication()
                app.launchEnvironment["NIKKI_SCREEN"] = page
                app.launchEnvironment["NIKKI_APPSTORE_LANG"] = language
                if !canvas.isEmpty {
                    app.launchEnvironment["NIKKI_APPSTORE_CANVAS"] = canvas
                }
                app.launch()

                // 起動画面や描画途中を撮らないよう、スクショページのルート要素の出現を待つ。
                // 初回起動やモデルコンテナ・カスタムフォントの初期化で 1 秒を超えることがあるため固定待機にしない。
                let root = app.otherElements["AppStoreScreenshotFrame"].firstMatch
                XCTAssertTrue(root.waitForExistence(timeout: 30), "\(page) (\(language)) のスクショ画面が表示されなかった")

                // OS の通知バナー(Apple Intelligence の案内等)が画面上部に写り込むことがあるため、
                // 出ていたら自動で消えるまで待ってから撮影する(実測でバナーが1枚に写り込んだ対策)。
                // 消えなければ重なった画像を成果物にしないよう失敗させる。
                let banner = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                    .otherElements["NotificationShortLookView"]
                    .firstMatch
                if banner.waitForExistence(timeout: 0.5) {
                    XCTAssertTrue(banner.waitForNonExistence(timeout: 15), "\(page) (\(language)) の撮影前に通知バナーが消えなかった")
                }

                // organize スクリプトとホスト側の撮影ループが「---」区切りでページ・言語をパースするための命名。
                let attachmentName = "AppStoreScreenshot---\(page)---\(language)---0"
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = attachmentName
                attachment.lifetime = .keepAlways
                add(attachment)

                try waitForHostCaptureIfNeeded(attachmentName: attachmentName, page: page, language: language)

                app.terminate()
            }
        }
    }

    /// パイプラインが SNAPSHOT_HOST_CAPTURE_DIR を渡した時だけ、ホスト側の撮影完了を待つ。
    /// `{attachmentName}.ready` を書いて `{attachmentName}.done` が現れるまでポーリングする。
    @MainActor
    private func waitForHostCaptureIfNeeded(attachmentName: String, page: String, language: String) throws {
        guard let hostCaptureDirectoryPath = ProcessInfo.processInfo.environment["SNAPSHOT_HOST_CAPTURE_DIR"],
              !hostCaptureDirectoryPath.isEmpty else {
            return
        }
        let hostCaptureDirectoryURL = URL(fileURLWithPath: hostCaptureDirectoryPath)
        let doneFilePath = hostCaptureDirectoryURL.appendingPathComponent("\(attachmentName).done").path
        XCTAssertTrue(
            FileManager.default.createFile(atPath: hostCaptureDirectoryURL.appendingPathComponent("\(attachmentName).ready").path, contents: nil),
            "\(page) (\(language)) のホスト撮影の合図を \(hostCaptureDirectoryPath) に書けなかった"
        )

        // ホストの 1 枚の撮影(simctl screenshot と alpha の除去)は数秒で終わる。
        // Mac の負荷が高い時の遅れを見込んで余裕を持たせ、それでも来なければホストが止まっているとみなす。
        let deadline = Date.now.addingTimeInterval(120)
        while !FileManager.default.fileExists(atPath: doneFilePath) {
            if Date.now > deadline {
                XCTFail("\(page) (\(language)) のホストの撮影完了 (\(doneFilePath)) が 120 秒以内に来なかった")
                return
            }
            Thread.sleep(forTimeInterval: 0.2)
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
