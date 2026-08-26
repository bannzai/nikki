#if os(iOS)
import XCTest

/// push 遷移した画面から前の画面へ戻れることを、通常フロー(RootPage)の配下で検証する (issue #104)。
/// 独自ヘッダ時代は toolbar(.hidden, for: .navigationBar) が interactivePopGestureRecognizer を
/// 道連れに無効化してスワイプで戻れなくなっていた (issue #92)。システムのナビゲーションバーへ
/// 移行して標準挙動に戻したため、回避策なしで戻れることを実イベントで検証する。
///
/// 起動を NIKKI_SCREEN=root にして RootPage を通すのは、戻る操作を壊し得る仕組みが RootPage 配下に
/// あるため。自動ロック用の無操作検出はウィンドウ上のジェスチャで、タッチを消費する実装
/// (simultaneousGesture の DragGesture) に戻ると戻るボタンのタップを奪う。カタログモードの
/// 画面直接起動では RootPage を迂回してしまい、その回帰を素通りさせる。
/// スワイプバックは iOS のジェスチャのため macOS ではコンパイルしない。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// setUp をオーバーライドできずビルドが通らないため、クラスは nonisolated にする (NotebookEditUITests と同じ)。
nonisolated final class NavigationSwipeBackUITests: XCTestCase {
    override func setUp() {
        // 遷移先の要素が見つからない時点で後続の assert に意味がないため、最初の失敗で止める。
        continueAfterFailure = false
    }

    /// 通常フロー(RootPage)のホームを開いたアプリを返す。
    /// NIKKI_SCREEN=root は RootPage を in-memory ストアとオンボーディング完了済みの
    /// 専用 UserDefaults suite で起動する指定 (Nikki/App/NikkiApp.swift)。
    @MainActor
    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NIKKI_SCREEN"] = "root"
        // 無操作の自動ロックが検証の途中で割り込まないようにする。
        app.launchEnvironment["NIKKI_AUTOLOCK_DISABLED"] = "1"
        // 文言は String Catalog で端末の言語に追従するため、シミュレータの言語設定によらず日本語の文言で要素を引けるよう固定する。
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        return app
    }

    /// ホームの歯車から設定画面へ push し、設定画面が出ていることを確かめる。
    @MainActor
    private func pushedSettings(app: XCUIApplication) {
        // ホームのナビゲーションバー右端は「+」(カレンダーモードのみ) と歯車。歯車は最後の1つ。
        let settingsButton = app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1)
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "ホームのナビゲーションバーに設定への入り口が表示されること")
        settingsButton.tap()

        XCTAssertTrue(
            app.staticTexts["書くこと"].waitForExistence(timeout: 5),
            "設定画面へ push 遷移すること"
        )
    }

    /// ホームに戻っていることを、ホームだけにある表示モードのセグメントで確かめる。
    @MainActor
    private func assertBackOnHome(app: XCUIApplication, message: String) {
        XCTAssertTrue(app.buttons["カレンダー"].waitForExistence(timeout: 5), message)
    }

    /// 設定画面から左エッジのスワイプでホームへ戻れる。
    @MainActor
    func testSwipeBackReturnsToPreviousScreen() throws {
        let app = launchedApp()
        pushedSettings(app: app)

        // 左エッジから右へのドラッグで interactivePopGestureRecognizer を発火させる。
        // 開始点はエッジ判定 (UIScreenEdgePanGestureRecognizer) に入るよう画面の最左端に置き、
        // タップ扱いにならない最短の押下からゆっくりドラッグして、確定まで指を離した状態を作る。
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
            .press(
                forDuration: 0.05,
                thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)),
                withVelocity: .slow,
                thenHoldForDuration: 0.3
            )

        assertBackOnHome(app: app, message: "左エッジのスワイプでホームへ戻ること")
    }

    /// 設定画面からシステムの戻るボタンのタップでホームへ戻れる。
    /// 無操作検出がタッチを消費する実装に戻ると、このタップが奪われて戻れなくなる (issue #104 で実際に踏んだ)。
    @MainActor
    func testBackButtonReturnsToPreviousScreen() throws {
        let app = launchedApp()
        pushedSettings(app: app)

        // アプリ外のボタン (キーボード等) を引かないよう、ナビゲーションバーの中に絞って先頭 (戻る) を押す。
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "設定画面にシステムの戻るボタンが表示されること")
        backButton.tap()

        assertBackOnHome(app: app, message: "戻るボタンのタップでホームへ戻ること")
    }
}
#endif
