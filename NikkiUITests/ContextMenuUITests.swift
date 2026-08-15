import XCTest

/// ホームの日記行のコンテキストメニュー (macOS: 右クリック / iOS: 長押し) が実イベント経路で開くことを検証する。
/// CGEvent 合成イベントはアプリに配送されず (issue #45)、AXShowMenu はイベント経路の検証にならないため、
/// testmanagerd がシステム側でイベントを合成する XCUITest で「右クリック/長押し → メニュー表示」を機械検証する。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// init / setUp をオーバーライドできずビルドが通らないため、クラスは nonisolated にする。
/// そのうえで XCUIElement の操作は MainActor 分離されているため、UI を触るメソッドに @MainActor を付ける。
nonisolated final class ContextMenuUITests: XCTestCase {
    override func setUp() {
        // 行が見つからない・メニューが開かない時点で後続の assert に意味がないため、最初の失敗で止める。
        continueAfterFailure = false
    }

    /// サンプルデータ入りのホーム(時系列リスト)を直接起動したアプリを返す。
    /// 通常フローは onboardingCompleted と homePageMode が実行環境の UserDefaults(.appGroups) に依存して
    /// 起動画面が変わるため、カタログモード (NIKKI_SCREEN=entryList) で in-memory ストア + リスト表示に固定する。
    @MainActor
    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NIKKI_SCREEN"] = "entryList"
        // カタログモードは自動ロックを持つ RootPage を通らないが、issue #45 の前提に合わせて明示しておく。
        app.launchEnvironment["NIKKI_AUTOLOCK_DISABLED"] = "1"
        app.launch()
        return app
    }

    /// サンプルデータ先頭の日記「梅雨明け」の行を返す。
    /// 行は NavigationLink のボタンで、日付・タイトル・抜粋が1つのアクセシビリティ要素に結合されるため、
    /// 子テキストではなくラベルの部分一致で引く。
    @MainActor
    private func entryRow(app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "梅雨明け")).firstMatch
    }

    /// コンテキストメニューの「アーカイブ」項目。macOS はメニュー項目、iOS はボタンとして現れる。
    @MainActor
    private func archiveMenuItem(app: XCUIApplication) -> XCUIElement {
        #if os(macOS)
        return app.menuItems["アーカイブ"]
        #else
        return app.buttons["アーカイブ"]
        #endif
    }

    /// 行の本文テキスト上でコンテキストメニューを開くと「アーカイブ」項目が表示される。
    @MainActor
    func testContextMenuOnRowText() throws {
        let app = launchedApp()
        let row = entryRow(app: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "ホームの日記行が表示されること")

        #if os(macOS)
        row.rightClick()
        #else
        // contextMenu の発火閾値に余裕を持たせた長押し時間。
        row.press(forDuration: 1.5)
        #endif

        XCTAssertTrue(
            archiveMenuItem(app: app).waitForExistence(timeout: 5),
            "行のテキスト上でコンテキストメニューが開くこと"
        )
    }

    /// テキストが載っていない行の余白でもコンテキストメニューが開く。
    /// HomeListBody の contentShape(Rectangle()) が無いと透明な余白がヒットテストに乗らず開けない
    /// 回帰 (PR #44) の検証。
    /// 座標は、抜粋テキストの右外側 (末尾スペーサー) と行の下パディングが重なる右下寄りの位置。
    /// 実測で、この座標だけが contentShape の有無で結果が変わる (右辺でも縦中央は抜粋テキストに載るため
    /// contentShape 無しでも開いてしまい、回帰検証にならない)。
    @MainActor
    func testContextMenuOnRowEmptyMargin() throws {
        let app = launchedApp()
        let row = entryRow(app: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "ホームの日記行が表示されること")

        let rowEmptyMargin = row.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.9))

        #if os(macOS)
        rowEmptyMargin.rightClick()
        #else
        // contextMenu の発火閾値に余裕を持たせた長押し時間。
        rowEmptyMargin.press(forDuration: 1.5)
        #endif

        XCTAssertTrue(
            archiveMenuItem(app: app).waitForExistence(timeout: 5),
            "行の余白でもコンテキストメニューが開くこと"
        )
    }
}
