import Foundation
import Testing
@testable import Nikki
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// コピーのリッチテキスト表現(editorCopyAttributedString)のテスト。
/// プレーンテキスト表現は Block.markdown(blocks:) そのもののため、BlockMarkdownTests が受け持つ。
struct EditorBlockCopyTests {
    @Test("見出しは記法の # を出さず、見出しの大きさ・太さになる")
    func headingKeepsStyleWithoutSyntax() {
        let attributed = editorCopyAttributedString(blocks: Block.blocks(fromMarkdown: "## 買ったもの"))
        #expect(attributed.string == "買ったもの")
        #if canImport(UIKit)
        let font = attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #else
        let font = attributed.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        #endif
        #expect(font?.pointSize == 18)
    }

    @Test("チェックリストは記法を出さず、チェックボックスの記号と完了の打ち消し線になる")
    func checklistKeepsStyleWithoutSyntax() {
        let attributed = editorCopyAttributedString(blocks: Block.blocks(fromMarkdown: "- [ ] 麦茶のパック\n- [x] 蚊取り線香"))
        #expect(attributed.string == "☐ 麦茶のパック\n☑ 蚊取り線香")
        let doneLocation = (attributed.string as NSString).range(of: "☑").location
        #expect(attributed.attribute(.strikethroughStyle, at: doneLocation, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue)
        #expect(attributed.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)
    }

    @Test("複数ブロックは改行で区切られ、img・details は元の行のまま運ばれる")
    func joinsBlocksWithNewlines() {
        let attributed = editorCopyAttributedString(
            blocks: Block.blocks(fromMarkdown: "## 買ったもの\n\n蝉の声で目が覚めた。\n\n<img alt=\"夕焼けの写真\">")
        )
        #expect(attributed.string == "買ったもの\n蝉の声で目が覚めた。\n<img alt=\"夕焼けの写真\">")
    }
}
