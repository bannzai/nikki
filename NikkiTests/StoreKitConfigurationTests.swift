import StoreKit
import StoreKitTest
import XCTest

/// StoreKit Configuration file (Nikki.storekit) の検証。
/// SKTestSession がテストバンドル内の .storekit を読み込むため、App Store Connect にも
/// ネットワークにも触れず、CLI (xcodebuild test) だけで
/// 「商品解決 → 購入 → entitlement 付与」まで確認できる。
/// simctl launch には StoreKit Configuration を渡す手段が無いため、CLI からの課金検証はこの経路を使う。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// init をオーバーライドできずビルドが通らないため、クラスは nonisolated にする(AppStoreScreenshotRenderTests と同じ)。
nonisolated final class StoreKitConfigurationTests: XCTestCase {
    /// iOS 26.5 の simulator では xcodebuild test 経由の StoreKit Testing が機能しない既知の問題があるため skip する。
    /// SKTestSession の init は成功するのに設定が適用されず、商品解決が実ストア (sandbox) に落ち、
    /// buyProduct は StoreKitError.notEntitled を投げる (2026-08-15 実測: iOS 26.5 で再現・iOS 26.2 で全項目 pass。
    /// 署名の有無は無関係。Apple Developer Forums でも iOS 26.5 simulator の CI 利用で同様の報告あり)。
    /// 将来の runtime で解消されている可能性があるため、26.5 より新しい runtime ではまず skip を外して実測する
    private func skipOnBrokenSimulatorRuntime() throws {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        try XCTSkipIf(
            version.majorVersion == 26 && version.minorVersion == 5,
            "iOS 26.5 simulator では StoreKit Testing が StoreKitError.notEntitled で機能しない (iOS 26.2 以下の runtime で実行する)"
        )
    }

    /// .storekit を読み込み、前回のテストの購入履歴を持ち越さない状態にした SKTestSession を返す
    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Nikki")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    /// サブスクリプション 2 種が .storekit の定義どおりの価格・期間で解決され、無料トライアルを持たないこと
    func testSubscriptionsResolveWithConfirmedPricesAndPeriods() async throws {
        try skipOnBrokenSimulatorRuntime()
        let session = try makeSession()
        defer {
            session.clearTransactions()
        }

        let products = try await Product.products(for: [
            "nikki_plus_monthly",
            "nikki_plus_annual",
        ])
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        XCTAssertEqual(productsByID.count, 2)

        XCTAssertEqual(productsByID["nikki_plus_monthly"]?.price, 300)
        XCTAssertEqual(productsByID["nikki_plus_monthly"]?.type, .autoRenewable)
        XCTAssertEqual(productsByID["nikki_plus_monthly"]?.subscription?.subscriptionPeriod.unit, .month)
        XCTAssertEqual(productsByID["nikki_plus_monthly"]?.subscription?.subscriptionPeriod.value, 1)
        XCTAssertNil(productsByID["nikki_plus_monthly"]?.subscription?.introductoryOffer)

        XCTAssertEqual(productsByID["nikki_plus_annual"]?.price, 3000)
        XCTAssertEqual(productsByID["nikki_plus_annual"]?.type, .autoRenewable)
        XCTAssertEqual(productsByID["nikki_plus_annual"]?.subscription?.subscriptionPeriod.unit, .year)
        XCTAssertEqual(productsByID["nikki_plus_annual"]?.subscription?.subscriptionPeriod.value, 1)
        XCTAssertNil(productsByID["nikki_plus_annual"]?.subscription?.introductoryOffer)

        // 月額と年額は同じサブスクリプショングループに属し、片方だけが有効になる関係であること
        XCTAssertEqual(
            productsByID["nikki_plus_monthly"]?.subscription?.subscriptionGroupID,
            productsByID["nikki_plus_annual"]?.subscription?.subscriptionGroupID
        )
    }

    /// 買い切りが .storekit の定義どおりの価格で解決され、サブスクリプションとして扱われないこと
    func testLifetimeResolvesAsNonConsumable() async throws {
        try skipOnBrokenSimulatorRuntime()
        let session = try makeSession()
        defer {
            session.clearTransactions()
        }

        let products = try await Product.products(for: ["nikki_plus_lifetime2"])

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.price, 12000)
        XCTAssertEqual(products.first?.type, .nonConsumable)
        XCTAssertNil(products.first?.subscription)
    }

    /// 月額サブスクリプションのテスト購入でトランザクションが成立し、現在の entitlement に現れること
    func testBuyMonthlyGrantsEntitlement() async throws {
        try skipOnBrokenSimulatorRuntime()
        let session = try makeSession()
        defer {
            session.clearTransactions()
        }

        _ = try await session.buyProduct(identifier: "nikki_plus_monthly")

        let granted = await waitUntilEntitled(productID: "nikki_plus_monthly")
        XCTAssertTrue(granted)
    }

    /// 年額サブスクリプションのテスト購入でトランザクションが成立し、現在の entitlement に現れること
    func testBuyAnnualGrantsEntitlement() async throws {
        try skipOnBrokenSimulatorRuntime()
        let session = try makeSession()
        defer {
            session.clearTransactions()
        }

        _ = try await session.buyProduct(identifier: "nikki_plus_annual")

        let granted = await waitUntilEntitled(productID: "nikki_plus_annual")
        XCTAssertTrue(granted)
    }

    /// 買い切りのテスト購入でトランザクションが成立し、現在の entitlement に現れること
    func testBuyLifetimeGrantsEntitlement() async throws {
        try skipOnBrokenSimulatorRuntime()
        let session = try makeSession()
        defer {
            session.clearTransactions()
        }

        _ = try await session.buyProduct(identifier: "nikki_plus_lifetime2")

        let granted = await waitUntilEntitled(productID: "nikki_plus_lifetime2")
        XCTAssertTrue(granted)
    }

    /// buyProduct 後のトランザクションが Transaction.currentEntitlements へ反映されるまで待って、付与されたかを返す。
    /// 反映は同期ではなく、CI の遅い runner ではポーリングなしの即時参照で取りこぼす (実測: iOS 26.2 で 2/5 件失敗)。
    /// タイムアウトは CI の実測失敗が 1 秒未満のラグ起因のため、桁の余裕をとって 10 秒にしている
    private func waitUntilEntitled(productID: String, timeout: TimeInterval = 10) async -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if await currentEntitledProductIDs().contains(productID) {
                return true
            }
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                // テストタスクのキャンセル時はポーリングを打ち切って未付与として返す
                return false
            }
        }
        return false
    }

    /// 検証済みトランザクションとして現在付与されている entitlement の productID
    private func currentEntitledProductIDs() async -> Set<String> {
        var productIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                productIDs.insert(transaction.productID)
            }
        }
        return productIDs
    }
}
