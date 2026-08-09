import Foundation

/// アプリ全体で共有する定数。
enum Const {
    /// App Groups の suite 名。@AppStorage の保存先(UserDefaults.appGroups)と、将来の Extension とのデータ共有に使う。
    static let iOSAppGroupsKey = "group.com.bannzai.Nikki"

    /// RevenueCat の App「Nikki (App Store)」の Public API key。アプリに同梱される公開値で、秘匿情報ではない。
    static let revenueCatAPIKey = "appl_OaKduBTXogxMLpflYqDUCppEull"

    /// Nikki Plus の解放判定に使う RevenueCat の entitlement ID。
    static let revenueCatPlusEntitlementID = "plus"
}
