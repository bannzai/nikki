import SwiftData
import Testing
@testable import Nikki

struct CloudSyncPlusGateTests {
    // ModelConfiguration.CloudKitDatabase は Equatable に準拠しない(switch の case パターンも使えない)ため、
    // String(describing:) で内部の case・関連値を比較する。
    @Test("Plus 加入時のみ CloudKit private database と同期する")
    func syncsOnlyWhenPlusActive() {
        #expect(
            String(describing: effectiveCloudKitDatabase(plusActive: true))
                == String(describing: ModelConfiguration.CloudKitDatabase.private("iCloud.com.bannzai.Nikki"))
        )
        #expect(
            String(describing: effectiveCloudKitDatabase(plusActive: false))
                == String(describing: ModelConfiguration.CloudKitDatabase.none)
        )
    }
}
