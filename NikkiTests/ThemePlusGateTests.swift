import SwiftUI
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

    @Test("Plus 失効中は Plus 限定の保存値を生成へ倒し、無料の保存値と加入中はそのまま")
    func effectiveIndexFallsBackWhenPlusInactive() {
        #expect(effectivePaperColorPresetIndex(storedIndex: 3, plusActive: false) == 1)
        #expect(effectivePaperColorPresetIndex(storedIndex: 3, plusActive: true) == 3)
        #expect(effectivePaperColorPresetIndex(storedIndex: 0, plusActive: false) == 0)
        #expect(effectivePaperColorPresetIndex(storedIndex: 1, plusActive: false) == 1)
    }
}

extension ThemePlusGateTests {
    @Test("実画面の紙色は失効を倒した添字のプリセット色になり、範囲外の保存値は生成に倒す")
    func effectivePaperColorResolvesPreset() {
        #expect(effectivePaperColor(storedIndex: 3, plusActive: true) == Color.paperColorPreset[3])
        #expect(effectivePaperColor(storedIndex: 3, plusActive: false) == Color.paperColorPreset[1])
        #expect(effectivePaperColor(storedIndex: 0, plusActive: false) == Color.paperColorPreset[0])
        #expect(effectivePaperColor(storedIndex: 99, plusActive: true) == Color.paperColorPreset[1])
    }
}
