import SwiftUI

extension EnvironmentValues {
    /// 配下の画面が「今日」として扱う日付。
    /// RootPage がフォアグラウンド復帰・日付変更のタイミングでのみ更新して配る(毎分のクロックは使わない)。
    @Entry var today: Date = .now

    /// 自動ロックの無操作タイマーを起点からやり直す。
    /// RootPage のタッチ検知では拾えない操作(キーボード入力等)を受け付ける画面が呼ぶ。
    @Entry var resetAutoLockTimer: @MainActor () -> Void = {}
}
