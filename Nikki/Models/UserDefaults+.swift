import Foundation
import SwiftUI

// MARK: - Bool

extension UserDefaults {
    /// Bool を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum BoolKey: String, CaseIterable {
        case onboardingCompleted
        case faceIDUnlockEnabled
        /// 既定のテンプレートのシード(または既存データの確認)をこの端末で終えたかどうか。
        /// 「すべてのテンプレートを削除」した空の状態を、次回起動のシードが勝手に復活させないための目印。
        case notebooksSeeded
        /// 旧既定テンプレート「白紙」から「日記」への名前の移行(issue #92)をこの端末で終えたかどうか。
        /// 対象が無くなったあとの起動が毎回全件を調べ直さないための目印。
        case blankPageRenamedToJournal
        /// 直近の customerInfo から得た Nikki Plus 加入状態のキャッシュ(#93)。
        /// ModelContainer は起動時に一度だけ構成され、CloudKit 同期の有効/無効を実行中に切り替えられないため、
        /// 次回起動時にこのキャッシュ値で判定する。RootPage が customerInfoStream の更新のたびに書き込む。
        case cloudSyncPlusActiveCache

        var key: String {
            "BoolKey_\(rawValue)"
        }
    }
}

extension AppStorage {
    typealias BoolKey = UserDefaults.BoolKey

    init(wrappedValue: Value, _ key: BoolKey, store: UserDefaults? = nil) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.key, store: store)
    }
}

// MARK: - Int

extension UserDefaults {
    /// Int を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum IntKey: String, CaseIterable {
        case autoLockSeconds
        case paperColorPresetIndex
        /// 背景画像ファイル(ThemeBackgroundImage)の変更回数(#96)。画像はファイル保存で SwiftUI の
        /// 状態にならないため、保存・削除のたびに増やして RootPage の再評価(実画面への即時反映)を起こす。
        case themeBackgroundImageVersion

        var key: String {
            "IntKey_\(rawValue)"
        }
    }
}

extension AppStorage {
    typealias IntKey = UserDefaults.IntKey

    init(wrappedValue: Value, _ key: IntKey, store: UserDefaults? = nil) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.key, store: store)
    }
}

// MARK: - String

extension UserDefaults {
    /// String を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum StringKey: String, CaseIterable {
        case defaultNotebookID

        var key: String {
            "StringKey_\(rawValue)"
        }
    }
}

extension AppStorage {
    typealias StringKey = UserDefaults.StringKey

    init(wrappedValue: Value, _ key: StringKey, store: UserDefaults? = nil) where Value == String {
        self.init(wrappedValue: wrappedValue, key.key, store: store)
    }
}

// MARK: - Data

extension UserDefaults {
    /// Data を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum DataKey: String, CaseIterable {
        /// 登録済みパスキーの識別子(issue #84)。空なら未登録で、登録状態はこの値の有無で表す。
        case passkeyCredentialID
        /// 登録済みパスキーの公開鍵(X9.63 表現)。ロック解除時の署名検証に使う。
        case passkeyPublicKey

        var key: String {
            "DataKey_\(rawValue)"
        }
    }
}

extension AppStorage {
    typealias DataKey = UserDefaults.DataKey

    init(wrappedValue: Value, _ key: DataKey, store: UserDefaults? = nil) where Value == Data {
        self.init(wrappedValue: wrappedValue, key.key, store: store)
    }
}

// MARK: - Enum String

extension UserDefaults {
    /// RawValue が String の enum を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum StringEnumKey: String, CaseIterable {
        case onboardingStep
        case textSize

        var key: String {
            "StringEnumKey_\(rawValue)"
        }
    }
}

extension AppStorage {
    typealias StringEnumKey = UserDefaults.StringEnumKey

    init(wrappedValue: Value, _ key: StringEnumKey, store: UserDefaults? = nil) where Value: RawRepresentable, Value.RawValue == String {
        self.init(wrappedValue: wrappedValue, key.key, store: store)
    }
}

// MARK: - Enum Int

extension UserDefaults {
    /// RawValue が Int の enum を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum IntEnumKey: String, CaseIterable {
        case homePageMode

        var key: String {
            "IntEnumKey_\(rawValue)"
        }
    }
}

extension AppStorage {
    typealias IntEnumKey = UserDefaults.IntEnumKey

    init(wrappedValue: Value, _ key: IntEnumKey, store: UserDefaults? = nil) where Value: RawRepresentable, Value.RawValue == Int {
        self.init(wrappedValue: wrappedValue, key.key, store: store)
    }
}

// MARK: - AppGroups

extension UserDefaults {
    /// App Groups 共有の suite。@AppStorage は .defaultAppStorage(.appGroups) 経由でこれを既定にする。
    static let appGroups: UserDefaults = .init(suiteName: Const.iOSAppGroupsKey)!
}
