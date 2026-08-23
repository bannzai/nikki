import Foundation
import Testing
@testable import Nikki

/// エディタがブロックを直接書き換えるヘルパー(Block / [Block] の「編集」セクション)のテスト。
struct BlockEditingTests {
    @Test("チェックを付け外しすると - [x] / - [ ] として書き出される")
    func togglesChecklistItemDone() {
        var blocks = Block.blocks(fromMarkdown: "- [ ] 麦茶のパック\n- [x] 蚊取り線香")
        let itemIDs = blocks.firstChecklistItems.map(\.id)
        blocks.setChecklistItemDone(itemID: itemIDs[0], done: true)
        blocks.setChecklistItemDone(itemID: itemIDs[1], done: false)
        #expect(Block.markdown(blocks: blocks) == "- [x] 麦茶のパック\n- [ ] 蚊取り線香")
    }

    @Test("details を開くと open 属性として書き出される")
    func togglesDetailsOpen() {
        var blocks = Block.blocks(fromMarkdown: "<details><summary>病院メモ</summary></details>")
        let blockID = blocks[0].id
        blocks.toggleDetails(blockID: blockID)
        #expect(Block.markdown(blocks: blocks) == "<details open><summary>病院メモ</summary></details>")

        blocks.toggleDetails(blockID: blockID)
        #expect(Block.markdown(blocks: blocks) == "<details><summary>病院メモ</summary></details>")
    }

    @Test("先頭以外の位置の open 属性も重複させずに付け外しできる")
    func togglesDetailsOpenAttributeAtAnyPosition() {
        // open が後方の属性でも「開いている」と読む。
        var blocks = Block.blocks(fromMarkdown: "<details class=\"memo\" open><summary>病院メモ</summary></details>")
        let blockID = blocks[0].id
        if case .details(_, _, let isCollapsed, _) = blocks[0] {
            #expect(isCollapsed == false)
        } else {
            Issue.record("details としてパースされていない: \(blocks)")
        }

        // たたむと後方の open だけが外れ、開き直しても open は1つのまま。
        blocks.toggleDetails(blockID: blockID)
        #expect(Block.markdown(blocks: blocks) == "<details class=\"memo\"><summary>病院メモ</summary></details>")
        blocks.toggleDetails(blockID: blockID)
        #expect(Block.markdown(blocks: blocks) == "<details open class=\"memo\"><summary>病院メモ</summary></details>")

        // summary の文中の「open」には反応しない。
        let summaryBlocks = Block.blocks(fromMarkdown: "<details><summary>open 予定の店</summary></details>")
        if case .details(_, _, let isCollapsed, _) = summaryBlocks[0] {
            #expect(isCollapsed == true)
        } else {
            Issue.record("details としてパースされていない: \(summaryBlocks)")
        }
    }

    @Test("値付きの open 属性も開いていると読み、たたむと丸ごと外れる")
    func togglesValuedOpenAttribute() {
        var blocks = Block.blocks(fromMarkdown: "<details open=\"\"><summary>病院メモ</summary></details>")
        let blockID = blocks[0].id
        if case .details(_, _, let isCollapsed, _) = blocks[0] {
            #expect(isCollapsed == false)
        } else {
            Issue.record("details としてパースされていない: \(blocks)")
        }

        // たたむと open="" が丸ごと外れ、開き直しても open は1つだけになる。
        blocks.toggleDetails(blockID: blockID)
        #expect(Block.markdown(blocks: blocks) == "<details><summary>病院メモ</summary></details>")
        blocks.toggleDetails(blockID: blockID)
        #expect(Block.markdown(blocks: blocks) == "<details open><summary>病院メモ</summary></details>")
    }

    @Test("本文が空のブロックと項目は書き出しから外れる")
    func dropsEmptyText() {
        let blocks: [Block] = [
            .paragraph(text: "朝から蝉が鳴いていた。"),
            .paragraph(text: ""),
            .heading(level: 2, text: ""),
            .checklist(items: [ChecklistItem(text: "麦茶", done: false), ChecklistItem(text: "", done: false)]),
            .checklist(items: [ChecklistItem(text: "", done: false)]),
            .image(label: "夕焼けの写真", rawMarkdown: "<img alt=\"夕焼けの写真\">"),
        ]
        #expect(Block.markdown(blocks: blocks.withoutEmptyText) == """
        朝から蝉が鳴いていた。

        - [ ] 麦茶

        <img alt="夕焼けの写真">
        """)
    }

    @Test("記法だけを打ち終えた段落は見出し・チェックリストへ変わる")
    func convertsMarkdownPrefix() {
        #expect(Block.markdown(blocks: [Block.converted(paragraphText: "# ")!]) == "# ")
        #expect(Block.markdown(blocks: [Block.converted(paragraphText: "### ")!]) == "### ")
        #expect(Block.markdown(blocks: [Block.converted(paragraphText: "- [ ] ")!]) == "- [ ] ")
        #expect(Block.markdown(blocks: [Block.converted(paragraphText: "- [x] ")!]) == "- [x] ")
    }

    @Test("記法に続く本文まで入力された段落は変換しない")
    func keepsParagraphWhileTyping() {
        // 日本語入力の変換中にブロックを差し替えないための境界(issue #86)。
        #expect(Block.converted(paragraphText: "- [ ] 麦") == nil)
        #expect(Block.converted(paragraphText: "# 買ったもの") == nil)
        #expect(Block.converted(paragraphText: "") == nil)
        #expect(Block.converted(paragraphText: "朝から蝉が鳴いていた。") == nil)
    }

    @Test("記法の変換ではチェックリストの先頭項目へ移る")
    func movesFieldAfterConversion() {
        var blocks: [Block] = [.paragraph(text: "")]
        let blockID = blocks[0].id
        let fieldID = blocks.updateEditableText(blockID: blockID, text: "- [ ] ")
        #expect(Block.markdown(blocks: blocks) == "- [ ] ")
        #expect(fieldID == blocks.firstChecklistItems.first?.id)
    }

    @Test("見出しに入った改行はブロックの区切りになる")
    func splitsBlockByNewline() {
        var blocks: [Block] = [.heading(level: 2, text: "買ったもの")]
        let blockID = blocks[0].id
        let fieldID = blocks.updateEditableText(blockID: blockID, text: "買ったもの\n")
        #expect(Block.markdown(blocks: blocks) == "## 買ったもの\n\n")
        #expect(blocks.count == 2)
        #expect(fieldID == blocks[1].id)
    }

    @Test("改行が無い入力では入力欄が変わらない")
    func keepsFieldWhileTyping() {
        var blocks: [Block] = [.paragraph(text: "朝から")]
        let blockID = blocks[0].id
        #expect(blocks.updateEditableText(blockID: blockID, text: "朝から蝉が") == nil)
        #expect(Block.markdown(blocks: blocks) == "朝から蝉が")
    }

    @Test("見出しの直後に空の段落を足せる")
    func insertsParagraphAfterBlock() {
        var blocks: [Block] = [.heading(level: 2, text: "買ったもの"), .paragraph(text: "麦茶を買った。")]
        let blockID = blocks[0].id
        let fieldID = blocks.insertParagraph(afterBlockID: blockID)
        #expect(blocks.count == 3)
        #expect(fieldID == blocks[1].id)
        #expect(Block.markdown(blocks: blocks.withoutEmptyText) == "## 買ったもの\n\n麦茶を買った。")
    }

    @Test("チェックリスト項目に入った改行は次の項目になる")
    func splitsChecklistItemByNewline() {
        var blocks = Block.blocks(fromMarkdown: "- [ ] 麦茶のパック")
        let itemID = blocks.firstChecklistItems[0].id
        let fieldID = blocks.updateChecklistItem(itemID: itemID, text: "麦茶のパック\n")
        #expect(Block.markdown(blocks: blocks) == "- [ ] 麦茶のパック\n- [ ] ")
        #expect(fieldID == blocks.firstChecklistItems[1].id)
    }

    @Test("本文の無い項目で改行するとリストから抜けて段落になる")
    func exitsChecklistFromEmptyItem() {
        var blocks: [Block] = [
            .checklist(items: [ChecklistItem(text: "麦茶のパック", done: false), ChecklistItem(text: "", done: false)])
        ]
        let itemID = blocks.firstChecklistItems[1].id
        let fieldID = blocks.updateChecklistItem(itemID: itemID, text: "\n")
        #expect(blocks.count == 2)
        #expect(fieldID == blocks[1].id)
        #expect(Block.markdown(blocks: blocks.withoutEmptyText) == "- [ ] 麦茶のパック")
    }

    @Test("途中の空項目で抜けるとチェックリストが前後に分かれる")
    func splitsChecklistAtEmptyMiddleItem() {
        var blocks: [Block] = [
            .checklist(items: [
                ChecklistItem(text: "麦茶のパック", done: false),
                ChecklistItem(text: "", done: false),
                ChecklistItem(text: "蚊取り線香", done: true),
            ])
        ]
        let itemID = blocks.firstChecklistItems[1].id
        let fieldID = blocks.updateChecklistItem(itemID: itemID, text: "\n")
        #expect(blocks.count == 3)
        #expect(fieldID == blocks[1].id)
        #expect(Block.markdown(blocks: blocks) == "- [ ] 麦茶のパック\n\n\n\n- [x] 蚊取り線香")
    }

    @Test("項目が1つだけのチェックリストは抜けると段落に入れ替わる")
    func replacesChecklistWithParagraph() {
        var blocks: [Block] = [.checklist(items: [ChecklistItem(text: "", done: false)])]
        let itemID = blocks.firstChecklistItems[0].id
        let fieldID = blocks.insertChecklistItem(afterItemID: itemID)
        #expect(blocks.count == 1)
        #expect(fieldID == blocks[0].id)
        #expect(blocks[0].editableText == "")
    }

    @Test("本文のある項目の直後には空の項目が入る")
    func insertsChecklistItemAfterItem() {
        var blocks = Block.blocks(fromMarkdown: "- [x] 麦茶のパック")
        let itemID = blocks.firstChecklistItems[0].id
        let fieldID = blocks.insertChecklistItem(afterItemID: itemID)
        #expect(Block.markdown(blocks: blocks) == "- [x] 麦茶のパック\n- [ ] ")
        #expect(fieldID == blocks.firstChecklistItems[1].id)
    }

    @Test("先頭の入力欄はチェックリストなら先頭項目を指す")
    func findsFirstEditableField() {
        let blocks = Block.blocks(fromMarkdown: "<img alt=\"夕焼けの写真\">\n\n- [ ] 麦茶のパック\n\n本文")
        #expect(blocks.firstEditableFieldID == blocks.firstChecklistItems[0].id)

        let imageOnly: [Block] = [.image(label: "夕焼けの写真", rawMarkdown: "<img alt=\"夕焼けの写真\">")]
        #expect(imageOnly.firstEditableFieldID == nil)
    }

    @Test("編集したブロック列は markdown と往復できる")
    func roundTripsAfterEditing() {
        var blocks = Block.blocks(fromMarkdown: "## 買ったもの\n\n- [ ] 麦茶のパック\n\n<details><summary>病院メモ</summary></details>")
        let itemID = blocks.firstChecklistItems[0].id
        let detailsID = blocks[2].id
        blocks.setChecklistItemDone(itemID: itemID, done: true)
        blocks.toggleDetails(blockID: detailsID)

        let markdown = Block.markdown(blocks: blocks.withoutEmptyText)
        #expect(markdown == """
        ## 買ったもの

        - [x] 麦茶のパック

        <details open><summary>病院メモ</summary></details>
        """)
        #expect(Block.markdown(blocks: Block.blocks(fromMarkdown: markdown)) == markdown)
    }
}
