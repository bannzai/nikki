import Foundation

/// 設定「文字の大きさ」の選択肢。表示名やポイント数への対応は使用側の View が switch で持つ。
enum TextSize: String, CaseIterable {
    // 小さめ
    case small
    // 標準
    case standard
    // 大きめ
    case large
}
