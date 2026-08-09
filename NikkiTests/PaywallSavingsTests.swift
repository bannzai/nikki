import Testing
@testable import Nikki

struct PaywallSavingsTests {
    @Test("¥300/月・¥3,000/年 は2ヶ月ぶんお得")
    func standardPricing() {
        #expect(annualSavingsMonths(monthlyPrice: 300, annualPrice: 3000) == 2)
    }

    @Test("割引がない・年額の方が高い価格ではバッジを出さない")
    func noSavings() {
        #expect(annualSavingsMonths(monthlyPrice: 300, annualPrice: 3600) == nil)
        #expect(annualSavingsMonths(monthlyPrice: 300, annualPrice: 4000) == nil)
    }

    @Test("1ヶ月未満の差は出さず、端数は切り捨てる")
    func flooring() {
        #expect(annualSavingsMonths(monthlyPrice: 300, annualPrice: 3500) == nil)
        #expect(annualSavingsMonths(monthlyPrice: 300, annualPrice: 2500) == 3)
    }

    @Test("月額が0以下なら算出しない")
    func invalidMonthlyPrice() {
        #expect(annualSavingsMonths(monthlyPrice: 0, annualPrice: 3000) == nil)
    }
}
