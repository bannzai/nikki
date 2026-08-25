#if os(iOS)
import XCTest

/// push 遷移した画面から左エッジのスワイプで前の画面へ戻れることを検証する (issue #104)。
/// 独自ヘッダ時代は toolbar(.hidden, for: .navigationBar) が interactivePopGestureRecognizer を
/// 道連れに無効化してスワイプで戻れなくなっていた (issue #92)。システムのナビゲーションバーへ
/// 移行して標準挙動に戻したため、回避策なしでスワイプが効くことを実イベントで検証する。
/// スワイプバックは iOS のジェスチャのため macOS ではコンパイルしない。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// setUp をオーバーライドできずビルドが通らないため、クラスは nonisolated にする (NotebookEditUITests と同じ)。
nonisolated final class NavigationSwipeBackUITests: XCTestCase {
    override func setUp() {
        // 遷移先の行が見つからない時点で後続の assert に意味がないため、最初の失敗で止める。
        continueAfterFailure = false
    }

    /// 設定 > テンプレート へ push 遷移し、左エッジのスワイプで設定へ戻れる。
    @MainActor
    func testSwipeBackReturnsToPreviousScreen() throws {
        // 通常フローは onboardingCompleted が実行環境の UserDefaults に依存して起動画面が変わるため、
        // カタログモード (NIKKI_SCREEN=settings) で in-memory ストア + 設定画面に固定する (NotebookEditUITests と同じ)。
        let app = XCUIApplication()
        app.launchEnvironment["NIKKI_SCREEN"] = "settings"
        app.launchEnvironment["NIKKI_AUTOLOCK_DISABLED"] = "1"
        // 文言は String Catalog で端末の言語に追従するため、シミュレータの言語設定によらず日本語の文言で要素を引けるよう固定する。
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()

        // 設定のテンプレート行は「テンプレート」の題と「4件」の値が1つのラベルに結合される。件数の値で引く (NotebookEditUITests と同じ)。
        let notebooksRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "件")).firstMatch
        XCTAssertTrue(notebooksRow.waitForExistence(timeout: 10), "設定にテンプレートの行が表示されること")
        notebooksRow.tap()

        let newTemplateFooter = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "新しいテンプレート")).firstMatch
        XCTAssertTrue(newTemplateFooter.waitForExistence(timeout: 5), "テンプレート管理一覧へ push 遷移すること")

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

        XCTAssertTrue(notebooksRow.waitForExistence(timeout: 5), "スワイプで設定画面へ戻ること")
    }
}
#endif
