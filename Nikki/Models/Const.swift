import Foundation

/// アプリ全体で共有する定数。
enum Const {
    /// App Groups の suite 名。@AppStorage の保存先(UserDefaults.appGroups)と、将来の Extension とのデータ共有に使う。
    static let iOSAppGroupsKey = "group.com.bannzai.Nikki"
}
