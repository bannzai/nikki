import Testing
import Foundation
@testable import Nikki
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

struct EditorMarkdownStylerTests {
    // MARK: - editorLineStyle

    @Test("見出し行はレベルと記法の範囲を返す")
    func headingLineStyle() {
        #expect(editorLineStyle(lineText: "# 今日") == .heading(level: 1, syntaxRange: NSRange(location: 0, length: 2)))
        #expect(editorLineStyle(lineText: "## 買ったもの") == .heading(level: 2, syntaxRange: NSRange(location: 0, length: 3)))
        #expect(editorLineStyle(lineText: "### 夕方") == .heading(level: 3, syntaxRange: NSRange(location: 0, length: 4)))
    }

    @Test("サポート外の見出しレベルは段落になる")
    func unsupportedHeadingLevelIsParagraph() {
        #expect(editorLineStyle(lineText: "#### 見出し4") == .paragraph)
    }

    @Test("チェックリスト行は完了状態と記法の範囲を返す")
    func checklistLineStyle() {
        #expect(editorLineStyle(lineText: "- [ ] 麦茶のパック") == .checklistItem(done: false, syntaxRange: NSRange(location: 0, length: 6)))
        #expect(editorLineStyle(lineText: "- [x] 蚊取り線香") == .checklistItem(done: true, syntaxRange: NSRange(location: 0, length: 6)))
        // 完了の記法は大文字の X も受け付ける (Block.checklistItem(fromLine:) と同じ規則)。
        #expect(editorLineStyle(lineText: "- [X] 蚊取り線香") == .checklistItem(done: true, syntaxRange: NSRange(location: 0, length: 6)))
    }

    @Test("インデントされた記法は段落のまま扱う")
    func indentedSyntaxIsParagraph() {
        // 保存形式 (Block.blocks(fromMarkdown:)) がインデント行を段落として扱う規則と一致させる。
        #expect(editorLineStyle(lineText: "  - [ ] インデント") == .paragraph)
        #expect(editorLineStyle(lineText: " # インデント見出し") == .paragraph)
    }

    @Test("img と details の行は html になる")
    func htmlLineStyle() {
        #expect(editorLineStyle(lineText: "<img alt=\"夕焼けの写真\">") == .html)
        #expect(editorLineStyle(lineText: "<details><summary>病院メモ</summary></details>") == .html)
    }

    @Test("通常の文と空行は段落になる")
    func paragraphLineStyle() {
        #expect(editorLineStyle(lineText: "朝から蝉が鳴いていた。") == .paragraph)
        #expect(editorLineStyle(lineText: "") == .paragraph)
    }

    // MARK: - editorLineAttributes

    @Test("カーソルの無い見出し行は記法を透明かつ極小フォントで隠す")
    func headingSyntaxIsHiddenWithoutCursor() throws {
        let attributes = editorLineAttributes(
            lineText: "## 買ったもの",
            lineRange: NSRange(location: 10, length: ("## 買ったもの" as NSString).length),
            bodyFontSize: 15,
            revealsSyntax: false
        )
        #expect(attributes.syntaxRange == NSRange(location: 10, length: 3))
        let syntaxAttributes = try #require(attributes.syntaxAttributes)
        #expect(syntaxAttributes[.foregroundColor] as? EditorTextColor == EditorTextColor.clear)
        let syntaxFont = try #require(syntaxAttributes[.font] as? EditorTextFont)
        #expect(syntaxFont.pointSize < 1)
        // 行全体は見出しの書体 (level 2 は 18pt)。
        let lineFont = try #require(attributes.lineAttributes[.font] as? EditorTextFont)
        #expect(lineFont.pointSize == 18)
    }

    @Test("カーソルのある見出し行は記法をグレーで生のまま見せる")
    func headingSyntaxIsRevealedWithCursor() throws {
        let attributes = editorLineAttributes(
            lineText: "# 今日",
            lineRange: NSRange(location: 0, length: ("# 今日" as NSString).length),
            bodyFontSize: 15,
            revealsSyntax: true
        )
        let syntaxAttributes = try #require(attributes.syntaxAttributes)
        #expect(syntaxAttributes[.foregroundColor] as? EditorTextColor != EditorTextColor.clear)
        // 生で見せる記法はフォントを差し替えない (見出しの書体のまま)。
        #expect(syntaxAttributes[.font] == nil)
    }

    @Test("完了したチェックリスト行は打ち消し線と灰色になる")
    func doneChecklistItemHasStrikethrough() throws {
        let attributes = editorLineAttributes(
            lineText: "- [x] 麦茶のパック",
            lineRange: NSRange(location: 0, length: ("- [x] 麦茶のパック" as NSString).length),
            bodyFontSize: 15,
            revealsSyntax: false
        )
        #expect(attributes.lineAttributes[.strikethroughStyle] as? Int == NSUnderlineStyle.single.rawValue)
        // 記法の範囲には打ち消し線を引かない (チェックボックスを重ねる場所のため)。
        let syntaxAttributes = try #require(attributes.syntaxAttributes)
        #expect(syntaxAttributes[.strikethroughStyle] as? Int == 0)
        #expect(syntaxAttributes[.foregroundColor] as? EditorTextColor == EditorTextColor.clear)
    }

    @Test("未完了のチェックリスト行は記法の幅を保ったまま透明にする")
    func checklistSyntaxKeepsWidthWithoutCursor() throws {
        let attributes = editorLineAttributes(
            lineText: "- [ ] 蚊取り線香",
            lineRange: NSRange(location: 0, length: ("- [ ] 蚊取り線香" as NSString).length),
            bodyFontSize: 15,
            revealsSyntax: false
        )
        let syntaxAttributes = try #require(attributes.syntaxAttributes)
        #expect(syntaxAttributes[.foregroundColor] as? EditorTextColor == EditorTextColor.clear)
        // チェックボックスを重ねる幅を確保するため、フォントは差し替えない。
        #expect(syntaxAttributes[.font] == nil)
    }

    @Test("html 行は等幅書体で本文と同じ大きさになる")
    func htmlLineUsesMonospacedFont() throws {
        let attributes = editorLineAttributes(
            lineText: "<img alt=\"夕焼けの写真\">",
            lineRange: NSRange(location: 0, length: ("<img alt=\"夕焼けの写真\">" as NSString).length),
            bodyFontSize: 15,
            revealsSyntax: false
        )
        let lineFont = try #require(attributes.lineAttributes[.font] as? EditorTextFont)
        #expect(lineFont.pointSize == 15)
        #expect(attributes.syntaxRange == nil)
    }

    // MARK: - editorLineRevealsSyntax

    @Test("キャレットのある行だけ記法を見せる")
    func revealsSyntaxOnlyOnCaretLine() {
        // 2行のテキスト「# a\nb」: 1行目の範囲は改行を含む (0,4)、2行目は (4,1)。
        let firstLine = NSRange(location: 0, length: 4)
        let secondLine = NSRange(location: 4, length: 1)
        #expect(editorLineRevealsSyntax(lineRange: firstLine, selectedRange: NSRange(location: 2, length: 0), textLength: 5))
        #expect(!editorLineRevealsSyntax(lineRange: secondLine, selectedRange: NSRange(location: 2, length: 0), textLength: 5))
        // 改行の直後のキャレットは次の行のもの。
        #expect(!editorLineRevealsSyntax(lineRange: firstLine, selectedRange: NSRange(location: 4, length: 0), textLength: 5))
        #expect(editorLineRevealsSyntax(lineRange: secondLine, selectedRange: NSRange(location: 4, length: 0), textLength: 5))
        // 末尾に改行の無い最終行では、文末のキャレットもその行のもの。
        #expect(editorLineRevealsSyntax(lineRange: secondLine, selectedRange: NSRange(location: 5, length: 0), textLength: 5))
    }

    @Test("範囲選択は交差する行すべての記法を見せる")
    func revealsSyntaxOnSelectedLines() {
        let firstLine = NSRange(location: 0, length: 4)
        let secondLine = NSRange(location: 4, length: 1)
        let selection = NSRange(location: 1, length: 4)
        #expect(editorLineRevealsSyntax(lineRange: firstLine, selectedRange: selection, textLength: 5))
        #expect(editorLineRevealsSyntax(lineRange: secondLine, selectedRange: selection, textLength: 5))
    }

    // MARK: - editorChecklistBoxes

    @Test("カーソルの無いチェックリスト行だけチェックボックスを列挙する")
    func checklistBoxesSkipCaretLine() {
        let text = "- [ ] a\n- [x] b\n段落" as NSString
        // キャレットは1行目 (先頭行) に置く。
        let boxes = editorChecklistBoxes(text: text, selectedRange: NSRange(location: 0, length: 0))
        #expect(boxes == [
            EditorChecklistBox(syntaxRange: NSRange(location: 8, length: 6), done: true)
        ])
        // キャレットが段落行なら両方のチェックリスト行に出る。
        let boxesWithCaretOnParagraph = editorChecklistBoxes(text: text, selectedRange: NSRange(location: text.length, length: 0))
        #expect(boxesWithCaretOnParagraph == [
            EditorChecklistBox(syntaxRange: NSRange(location: 0, length: 6), done: false),
            EditorChecklistBox(syntaxRange: NSRange(location: 8, length: 6), done: true)
        ])
    }

    // MARK: - editorRestyle

    @Test("editorRestyle は文字を変えずに属性だけを貼る")
    func restyleKeepsCharacters() {
        let markdown = "# 今日\n\n- [x] 麦茶のパック\n本文の段落"
        let textStorage = NSTextStorage(string: markdown)
        editorRestyle(
            textStorage: textStorage,
            range: NSRange(location: 0, length: (markdown as NSString).length),
            bodyFontSize: 15,
            selectedRange: NSRange(location: (markdown as NSString).length, length: 0),
            markedRange: nil
        )
        #expect(textStorage.string == markdown)
        // 見出し行の本文には見出しの書体 (level 1 は 22pt) が付く。
        let headingFont = textStorage.attribute(.font, at: 2, effectiveRange: nil) as? EditorTextFont
        #expect(headingFont?.pointSize == 22)
        // 見出しの記法 (カーソルの無い行) は透明になる。
        let syntaxColor = textStorage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? EditorTextColor
        #expect(syntaxColor == EditorTextColor.clear)
    }

    @Test("editorRestyle は IME 変換中の行に触れない")
    func restyleSkipsMarkedLine() {
        let markdown = "# 今日\nかきくけこ"
        let textStorage = NSTextStorage(string: markdown)
        let markedRange = NSRange(location: 5, length: 5)
        // IME が変換中テキストへ付ける属性の代わりの目印。restyle が触れなければそのまま残る。
        textStorage.addAttribute(.foregroundColor, value: EditorTextColor.red, range: markedRange)
        editorRestyle(
            textStorage: textStorage,
            range: NSRange(location: 0, length: (markdown as NSString).length),
            bodyFontSize: 15,
            selectedRange: NSRange(location: 10, length: 0),
            markedRange: markedRange
        )
        // 変換中の行 (2行目) の属性は書き換えられない。
        let markedColor = textStorage.attribute(.foregroundColor, at: markedRange.location, effectiveRange: nil) as? EditorTextColor
        #expect(markedColor == EditorTextColor.red)
        // 変換中でない行 (見出し) には装飾が付く。
        let headingFont = textStorage.attribute(.font, at: 2, effectiveRange: nil) as? EditorTextFont
        #expect(headingFont?.pointSize == 22)
    }

    @Test("空のドキュメントでも editorRestyle は落ちない")
    func restyleHandlesEmptyDocument() {
        let textStorage = NSTextStorage(string: "")
        editorRestyle(
            textStorage: textStorage,
            range: NSRange(location: 0, length: 0),
            bodyFontSize: 15,
            selectedRange: NSRange(location: 0, length: 0),
            markedRange: nil
        )
        #expect(textStorage.string == "")
    }
}
