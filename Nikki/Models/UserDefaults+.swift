import Foundation
import SwiftUI

// MARK: - Bool

extension UserDefaults {
    /// Bool を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum BoolKey: String, CaseIterable {
        case onboardingCompleted
        case faceIDUnlockEnabled
        case passkeyRegistered

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
        case defaultTemplateID

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
