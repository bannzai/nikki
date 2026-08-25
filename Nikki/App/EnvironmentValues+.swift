import SwiftUI

extension EnvironmentValues {
    /// 配下の画面が「今日」として扱う日付。
    /// RootPage がフォアグラウンド復帰・日付変更のタイミングでのみ更新して配る(毎分のクロックは使わない)。
    @Entry var today: Date = .now

    /// 自動ロックの無操作タイマーを起点からやり直す。
    /// RootPage のタッチ検知では拾えない操作(キーボード入力等)を受け付ける画面が呼ぶ。
    @Entry var resetAutoLockTimer: @MainActor () -> Void = {}

    /// Nikki Plus(entitlement `plus`)が有効かどうか。
    /// RootPage が RevenueCat の customerInfoStream から更新して配る。未 configure(カタログ・テスト)では常に false。
    @Entry var plusActive: Bool = false

    /// 実画面の紙地に使う色。テーマ(1n)の紙色プリセットを Plus の加入状態で倒した結果。
    /// RootPage が AppStorage と plusActive から解決して配る。未注入(プレビュー・テスト)では既定の紙地。
    @Entry var paperColor: Color = .inkPaper

    /// 背景画像。テーマ(1n)で選択した画像を Plus の加入状態で倒した結果(#96)。
    /// RootPage が ThemeBackgroundImage と plusActive から解決して配る。未加入・未選択・未注入では nil(紙色のみ表示)。
    @Entry var themeBackgroundImage: Image? = nil

    /// 現在の ModelContainer が CloudKit private database と同期しているかどうか(#93)。
    /// ModelContainer は起動時に一度だけ構成されるため、この値は加入状態が変わっても次回起動まで変化しない。
    /// plusActive との不一致は「変更の反映に再起動が必要」を示す。NikkiApp が起動時に一度だけ配る。
    @Entry var cloudSyncActive: Bool = false
}
