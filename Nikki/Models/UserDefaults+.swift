import Foundation
import SwiftUI

// MARK: - Bool

extension UserDefaults {
    /// Bool を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum BoolKey: String, CaseIterable {
        case onboardingCompleted

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

// MARK: - Enum String

extension UserDefaults {
    /// RawValue が String の enum を保存する UserDefaults キー。@AppStorage には対応する AppStorage.init を通して渡す。
    enum StringEnumKey: String, CaseIterable {
        case onboardingStep

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

// MARK: - AppGroups

extension UserDefaults {
    /// App Groups 共有の suite。@AppStorage は .defaultAppStorage(.appGroups) 経由でこれを既定にする。
    static let appGroups: UserDefaults = .init(suiteName: Const.iOSAppGroupsKey)!
}
