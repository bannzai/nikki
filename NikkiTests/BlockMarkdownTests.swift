import Testing
@testable import Nikki

struct BlockMarkdownTests {
    /// 全ブロック種(段落・見出し・チェックリスト・img・details)を含む markdown。
    private let fullMarkdown = """
    朝から蝉が鳴いていた。

    ## 買ったもの

    - [x] 麦茶のパック
    - [ ] 蚊取り線香

    <img alt="夕焼けの写真">

    <details><summary>病院メモ</summary></details>

    ### 夕方から

    風が涼しくなってきた。
    """

    // 各ブロックを単独で markdown 化した文字列は「種別 + 内容」を一意に表すため、
    // id(UUID)を無視したブロックの内容比較として使う。
    private func contents(of blocks: [Block]) -> [String] {
        blocks.map { Block.markdown(from: [$0]) }
    }

    @Test("全ブロック種をパースできる")
    func parsesAllBlockKinds() {
        let blocks = Block.blocks(fromMarkdown: fullMarkdown)
        #expect(contents(of: blocks) == [
            "朝から蝉が鳴いていた。",
            "## 買ったもの",
            "- [x] 麦茶のパック\n- [ ] 蚊取り線香",
            "<img alt=\"夕焼けの写真\">",
            "<details><summary>病院メモ</summary></details>",
            "### 夕方から",
            "風が涼しくなってきた。",
        ])
    }

    @Test("ブロック列を markdown にできる")
    func serializesBlocks() {
        let blocks: [Block] = [
            .heading(level: 1, text: "見出し"),
            .paragraph(text: "段落"),
            .checklist(items: [
                ChecklistItem(text: "済み", done: true),
                ChecklistItem(text: "未了", done: false),
            ]),
            .image(label: "写真"),
            .details(summary: "折りたたみ", isCollapsed: true),
            .details(summary: "ひらいたまま", isCollapsed: false),
        ]
        #expect(Block.markdown(from: blocks) == """
        # 見出し

        段落

        - [x] 済み
        - [ ] 未了

        <img alt="写真">

        <details><summary>折りたたみ</summary></details>

        <details open><summary>ひらいたまま</summary></details>
        """)
    }

    @Test("markdown とブロック列を往復できる")
    func roundTrips() {
        let blocks = Block.blocks(fromMarkdown: fullMarkdown)
        let roundTripped = Block.blocks(fromMarkdown: Block.markdown(from: blocks))
        #expect(contents(of: roundTripped) == contents(of: blocks))
        #expect(Block.markdown(from: roundTripped) == Block.markdown(from: blocks))
    }

    @Test("サポート外の行は段落として扱う")
    func fallsBackToParagraph() {
        let blocks = Block.blocks(fromMarkdown: """
        #### 深すぎる見出し
        - ただの箇条書き
        天気: 晴れ
        """)
        #expect(contents(of: blocks) == ["#### 深すぎる見出し", "- ただの箇条書き", "天気: 晴れ"])
    }

    @Test("空行はチェックリストの区切りになる")
    func blankLineSplitsChecklists() {
        let blocks = Block.blocks(fromMarkdown: "- [ ] 前半\n\n- [ ] 後半")
        #expect(contents(of: blocks) == ["- [ ] 前半", "- [ ] 後半"])
    }

    @Test("details の open 属性を開閉状態として読む")
    func readsDetailsOpenAttribute() {
        let blocks = Block.blocks(fromMarkdown: "<details open><summary>メモ</summary></details>")
        #expect(blocks.count == 1)
        if case .details(_, let summary, let isCollapsed) = blocks[0] {
            #expect(summary == "メモ")
            #expect(isCollapsed == false)
        } else {
            Issue.record("details としてパースされていない: \(blocks)")
        }
    }

    @Test("img の alt が無ければ src をラベルにする")
    func imageLabelFallsBackToSrc() {
        let blocks = Block.blocks(fromMarkdown: "<img src=\"https://example.com/photo.png\">")
        #expect(contents(of: blocks) == ["<img alt=\"https://example.com/photo.png\">"])
    }
}
