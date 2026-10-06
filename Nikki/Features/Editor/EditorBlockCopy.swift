import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)
/// コピーのリッチテキスト表現に使うプラットフォームのフォント型。
private typealias EditorCopyFont = UIFont
#else
/// コピーのリッチテキスト表現に使うプラットフォームのフォント型。
private typealias EditorCopyFont = NSFont
#endif

/// ブロック列を markdown のプレーンテキストとリッチテキストの2表現でペーストボードへ書き込む。
/// markdown を扱えるペースト先には「## 」「- [ ] 」の記法付きテキストとして、リッチテキストを
/// 扱えるペースト先には見出しサイズ・チェックボックスが反映された形で貼れるようにする(issue #100)。
func editorCopyBlocksToPasteboard(blocks: [Block]) {
    let markdown = Block.markdown(blocks: blocks)
    let attributed = editorCopyAttributedString(blocks: blocks)
    let rtfData = try? attributed.data(
        from: NSRange(location: 0, length: attributed.length),
        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
    #if canImport(UIKit)
    // 1つの item に複数表現を入れ、ペースト先が扱える方の表現を選ばせる。
    var item: [String: Any] = [UTType.utf8PlainText.identifier: markdown]
    if let rtfData {
        item[UTType.rtf.identifier] = rtfData
    }
    UIPasteboard.general.items = [item]
    #else
    NSPasteboard.general.clearContents()
    if let rtfData {
        NSPasteboard.general.setData(rtfData, forType: .rtf)
    }
    NSPasteboard.general.setString(markdown, forType: .string)
    #endif
}

/// コピーしたブロックのリッチテキスト表現。markdown の記法は出さず、見出しはエディタと同じ
/// 大きさ・太さ(EditorHeadingFont と対応)、チェックリストはチェックボックスの記号と
/// 完了の打ち消し線で構造を表す。ブロックの区切りは改行1つ(空行はペースト先で冗長なため)。
/// 書体は同梱の Zen Kaku Gothic ではなくシステムフォントにする。同梱フォントはペースト先の
/// アプリ・端末に存在せず、フォント指定が代替表示に落ちて見た目を運べないため。
func editorCopyAttributedString(blocks: [Block]) -> NSAttributedString {
    // 段落の文字の大きさは見本の標準 15pt。設定「文字の大きさ」は画面上の読みやすさの調整であり、
    // コピーした先の文書の文字サイズには反映しない。
    let bodyFont = EditorCopyFont.systemFont(ofSize: 15, weight: .regular)
    let result = NSMutableAttributedString()
    for block in blocks {
        if result.length > 0 {
            result.append(NSAttributedString(string: "\n", attributes: [.font: bodyFont]))
        }
        switch block {
        case .heading(_, let level, let text):
            let headingFont: EditorCopyFont = switch level {
            case ...1: .systemFont(ofSize: 22, weight: .bold)
            case 2: .systemFont(ofSize: 18, weight: .bold)
            default: .systemFont(ofSize: 16, weight: .medium)
            }
            result.append(NSAttributedString(string: text, attributes: [.font: headingFont]))
        case .paragraph(_, let text):
            result.append(NSAttributedString(string: text, attributes: [.font: bodyFont]))
        case .checklist(_, let items):
            for (index, item) in items.enumerated() {
                if index > 0 {
                    result.append(NSAttributedString(string: "\n", attributes: [.font: bodyFont]))
                }
                var attributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
                if item.done {
                    attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
                result.append(NSAttributedString(string: (item.done ? "☑ " : "☐ ") + item.text, attributes: attributes))
            }
        case .image(_, _, let rawMarkdown), .details(_, _, _, let rawMarkdown):
            // img・details はリッチテキストへ変換できる見た目を持たないため、元の行をそのまま運ぶ。
            result.append(NSAttributedString(string: rawMarkdown, attributes: [.font: bodyFont]))
        }
    }
    return result
}

// ブロック単位のコンテキストメニュー (editorBlockCopyContextMenu / editorCopyAllContextMenu) は
// 単一テキストビュー化 (issue #111) で廃止した。「すべてコピー」はテキストビューの
// 編集メニュー (iOS)・右クリックメニュー (macOS) から EditorTextView が提供する。
