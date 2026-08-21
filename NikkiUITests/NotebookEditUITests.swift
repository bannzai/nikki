import XCTest

/// ノート編集画面で名前を1文字ずつバックスペースで空にしたまま戻ったとき、削除途中の1文字ではなく
/// 元の名前(編集開始時点の名前)が残ることを検証する (issue #79)。
/// 「1文字ずつ削除して離脱」というイベントの並びが本質の不具合のため、実イベントを送る XCUITest で機械検証する。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// init / setUp をオーバーライドできずビルドが通らないため、クラスは nonisolated にする。
/// そのうえで XCUIElement の操作は MainActor 分離されているため、UI を触るメソッドに @MainActor を付ける。
nonisolated final class NotebookEditUITests: XCTestCase {
    override func setUp() {
        // 行や入力欄が見つからない時点で後続の assert に意味がないため、最初の失敗で止める。
        continueAfterFailure = false
    }

    /// 設定画面を直接起動したアプリを返す。
    /// 通常フローは onboardingCompleted が実行環境の UserDefaults(.appGroups) に依存して起動画面が変わるため、
    /// カタログモード (NIKKI_SCREEN=settings) で in-memory ストア(サンプルノート入り) + 設定画面に固定する。
    @MainActor
    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NIKKI_SCREEN"] = "settings"
        // カタログモードは自動ロックを持つ RootPage を通らないが、既存 UI テスト(issue #45)の前提に合わせて明示しておく。
        app.launchEnvironment["NIKKI_AUTOLOCK_DISABLED"] = "1"
        // 文言は String Catalog で端末の言語に追従するため、シミュレータの言語設定によらず日本語の文言で要素を引けるよう固定する。
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        return app
    }

    /// 設定 > ノート > 「一日の振り返り」の編集画面まで進み、名前の入力欄を返す。
    @MainActor
    private func openedNotebookNameField(app: XCUIApplication) -> XCUIElement {
        // 設定のノート行は「ノート」の題と「4冊」の値が1つのラベルに結合される。「既定のノート」行と
        // 取り違えないよう、冊数の値で引く。
        let notebooksRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "冊")).firstMatch
        XCTAssertTrue(notebooksRow.waitForExistence(timeout: 10), "設定にノートの行が表示されること")
        notebooksRow.tap()

        let notebookRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "一日の振り返り")).firstMatch
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5), "ノート一覧に「一日の振り返り」が表示されること")
        notebookRow.tap()

        // 編集画面の入力欄は名前の TextField 1つだけ(書き出しは TextEditor)。
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "編集画面に名前欄が表示されること")
        return nameField
    }

    /// InkNavBar の戻る。
    /// app.buttons の並び順にはアプリ外のボタン(macOS のウィンドウ枠・変換候補バー、iOS のキーボード)が
    /// 混ざり、添字では取り違えるため、アプリ側で付けた明示の identifier で引く。
    @MainActor
    private func backButton(app: XCUIApplication) -> XCUIElement {
        app.buttons["ink-nav-back"].firstMatch
    }

    /// 名前を末尾から1文字ずつ削除して空にし、そのまま戻ると元の名前のまま残る。
    @MainActor
    func testEmptiedNameKeepsOriginalNameOnLeave() throws {
        let app = launchedApp()
        let nameField = openedNotebookNameField(app: app)

        // 再現手順どおり、末尾にカーソルを置いて名前の文字数以上のバックスペースを送って空にする。
        nameField.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30))

        // iOS はキーボードのキー(次のキーボード等)も app.buttons に並ぶため、リターンで
        // キーボードを閉じてから、InkNavBar の戻るで一覧へ戻る。
        nameField.typeText("\n")
        backButton(app: app).tap()

        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "一日の振り返り")).firstMatch.waitForExistence(timeout: 5),
            "名前を空にしたまま戻ったら、削除途中の1文字ではなく元の名前のまま残ること"
        )
    }
}
