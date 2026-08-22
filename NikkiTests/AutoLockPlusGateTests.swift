import Testing
@testable import Nikki

struct AutoLockPlusGateTests {
    @Test("プリセットの秒数は加入状態によらずそのまま適用する")
    func presetSecondsApplyRegardlessOfPlus() {
        for seconds in autoLockPresetSeconds {
            #expect(effectiveAutoLockSeconds(storedSeconds: seconds, plusActive: false) == seconds)
            #expect(effectiveAutoLockSeconds(storedSeconds: seconds, plusActive: true) == seconds)
        }
    }

    @Test("カスタム秒数は Plus 加入中だけ適用し、失効中は既定の5秒へ倒す")
    func customSecondsRequirePlus() {
        #expect(effectiveAutoLockSeconds(storedSeconds: 45, plusActive: true) == 45)
        #expect(effectiveAutoLockSeconds(storedSeconds: 45, plusActive: false) == 5)
        #expect(effectiveAutoLockSeconds(storedSeconds: 1, plusActive: true) == 1)
        #expect(effectiveAutoLockSeconds(storedSeconds: 3600, plusActive: true) == 3600)
    }

    @Test("範囲外の保存値は加入状態によらず既定の5秒へ倒す")
    func outOfRangeSecondsFallBack() {
        #expect(effectiveAutoLockSeconds(storedSeconds: 0, plusActive: true) == 5)
        #expect(effectiveAutoLockSeconds(storedSeconds: -1, plusActive: false) == 5)
        #expect(effectiveAutoLockSeconds(storedSeconds: 3601, plusActive: true) == 5)
    }
}
