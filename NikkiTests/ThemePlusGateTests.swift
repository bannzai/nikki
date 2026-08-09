import Testing
@testable import Nikki

struct ThemePlusGateTests {
    @Test("紙色プリセットは白・生成が無料、それ以降が Nikki Plus 限定")
    func paperColorPresetBoundary() {
        #expect(paperColorPresetRequiresPlus(index: 0) == false)
        #expect(paperColorPresetRequiresPlus(index: 1) == false)
        #expect(paperColorPresetRequiresPlus(index: 2) == true)
        #expect(paperColorPresetRequiresPlus(index: 3) == true)
        #expect(paperColorPresetRequiresPlus(index: 4) == true)
    }
}
