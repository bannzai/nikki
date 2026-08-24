import Testing
@testable import Nikki

struct NotebookPlusGateTests {
    @Test("無料ユーザーは無料枠(2件)未満のときだけノートを作成できる")
    func freeUserBoundedByFreeLimit() {
        #expect(canCreateNotebook(existingNotebookCount: 0, plusActive: false) == true)
        #expect(canCreateNotebook(existingNotebookCount: freeNotebookLimit - 1, plusActive: false) == true)
        #expect(canCreateNotebook(existingNotebookCount: freeNotebookLimit, plusActive: false) == false)
        #expect(canCreateNotebook(existingNotebookCount: freeNotebookLimit + 1, plusActive: false) == false)
    }

    @Test("Plus 加入中はノート数に上限がない")
    func plusUserHasNoLimit() {
        #expect(canCreateNotebook(existingNotebookCount: freeNotebookLimit, plusActive: true) == true)
        #expect(canCreateNotebook(existingNotebookCount: freeNotebookLimit * 10, plusActive: true) == true)
    }
}
