import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)
/// エディタの装飾に使うプラットフォームのフォント型。
typealias EditorTextFont = UIFont
/// エディタの装飾に使うプラットフォームの色型。
typealias EditorTextColor = UIColor
#else
/// エディタの装飾に使うプラットフォームのフォント型。
typealias EditorTextFont = NSFont
/// エディタの装飾に使うプラットフォームの色型。
typealias EditorTextColor = NSColor
#endif

/// markdown の1行に適用する装飾。EditorTextView が NSAttributedString の属性に変換する。
enum EditorLineStyle: Equatable {
    /// 見出し行。level は 1〜3。syntaxRange は行内の「# 」の範囲で、カーソルの無い行では表示上隠す。
    case heading(level: Int, syntaxRange: NSRange)
    /// チェックリスト行。syntaxRange は行内の「- [ ] 」の範囲で、カーソルの無い行では
    /// 文字を隠してチェックボックスを重ねて描画する。
    case checklistItem(done: Bool, syntaxRange: NSRange)
    /// img・details の行。attachment 表示を復元するまでの一時後退として、生の行を等幅書体で見せる。
    case html
    /// 通常の段落行。
    case paragraph
}

/// 行のテキストから装飾を決める。行頭の記法のみ解釈し、どの記法を装飾するかの規則は
/// Block のパーサ (blocks(fromMarkdown:)) を通して判定する (インデント行を段落扱いにする等の
/// 規則を保存形式と一致させるため)。
func editorLineStyle(lineText: String) -> EditorLineStyle {
    switch Block.blocks(fromMarkdown: lineText).first {
    case .heading(_, let level, _):
        return .heading(
            level: level,
            syntaxRange: NSRange(location: 0, length: Block.headingPrefixes[level - 1].utf16.count)
        )
    case .checklist(_, let items):
        return .checklistItem(
            done: items.first?.done ?? false,
            syntaxRange: NSRange(location: 0, length: Block.uncheckedPrefix.utf16.count)
        )
    case .image, .details:
        return .html
    case .paragraph, nil:
        return .paragraph
    }
}

/// Zen Kaku Gothic New をプラットフォームのフォント型で引く。フォントが読み込めない環境
/// (単体テストのホストなど) ではシステムフォントに落とす。
func editorFont(weight: InkFontWeight, size: CGFloat) -> EditorTextFont {
    let fallbackWeight: EditorTextFont.Weight = switch weight {
    case .regular: .regular
    case .medium: .medium
    case .bold: .bold
    }
    return EditorTextFont(name: weight.postScriptName, size: size)
        ?? .systemFont(ofSize: size, weight: fallbackWeight)
}

/// 見出しレベルの書体。大きさ・太さは EditorHeadingFont (SwiftUI 側) と対応させる。
func editorHeadingTextFont(level: Int) -> EditorTextFont {
    switch level {
    case ...1: return editorFont(weight: .bold, size: 22)
    case 2: return editorFont(weight: .bold, size: 18)
    default: return editorFont(weight: .medium, size: 16)
    }
}

/// 1行に適用する属性のまとまり。範囲は行内ではなくドキュメント全体の位置で持ち、
/// EditorTextView がそのまま NSTextStorage へ適用できるようにする。
struct EditorLineAttributes {
    /// 行全体 (改行を除く) に適用する基本属性。
    var lineRange: NSRange
    var lineAttributes: [NSAttributedString.Key: Any]
    /// 記法の範囲にだけ重ねる属性。記法の無い行は nil。
    var syntaxRange: NSRange?
    var syntaxAttributes: [NSAttributedString.Key: Any]?
}

/// 1行分の装飾属性を組み立てる。文字は一切変えず、属性だけで表現する。
/// - Parameters:
///   - lineText: 行の文字 (改行は含まない)。
///   - lineRange: ドキュメント内での行の範囲 (改行は含まない)。
///   - bodyFontSize: 段落・チェックリストの文字の大きさ。設定「文字の大きさ」を反映する。
///   - revealsSyntax: カーソルのある行かどうか。Obsidian の Live Preview と同じく、
///     カーソルのある行では記法を生のまま (グレーで) 見せ、離れた行では隠す。
func editorLineAttributes(
    lineText: String,
    lineRange: NSRange,
    bodyFontSize: CGFloat,
    revealsSyntax: Bool
) -> EditorLineAttributes {
    let style = editorLineStyle(lineText: lineText)
    let inkColor = EditorTextColor(Color.ink)
    let tertiaryColor = EditorTextColor(Color.inkTextTertiary)

    let paragraphStyle = NSMutableParagraphStyle()

    switch style {
    case .heading(let level, let syntaxRange):
        return EditorLineAttributes(
            lineRange: lineRange,
            lineAttributes: [
                .font: editorHeadingTextFont(level: level),
                .foregroundColor: inkColor,
                .paragraphStyle: paragraphStyle,
            ],
            syntaxRange: NSRange(location: lineRange.location + syntaxRange.location, length: syntaxRange.length),
            syntaxAttributes: revealsSyntax
                // カーソル行では記法を生で見せる。本文と紛れないようグレーにする。
                ? [.foregroundColor: tertiaryColor]
                // カーソルの無い行では記法を隠す。文字は残したまま、透明にしつつ極小フォントで
                // 幅も畳み、見出しの本文が行頭から始まるようにする。
                : [.foregroundColor: EditorTextColor.clear, .font: editorFont(weight: .regular, size: 0.1)]
        )
    case .checklistItem(let done, let syntaxRange):
        var lineAttributes: [NSAttributedString.Key: Any] = [
            .font: editorFont(weight: .regular, size: bodyFontSize),
            .foregroundColor: done ? tertiaryColor : inkColor,
            .paragraphStyle: paragraphStyle,
        ]
        if done {
            // 完了項目は打ち消し線 + 灰色 (カタログの EditorChecklistBlock と同じ見た目)。
            lineAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            lineAttributes[.strikethroughColor] = tertiaryColor
        }
        return EditorLineAttributes(
            lineRange: lineRange,
            lineAttributes: lineAttributes,
            syntaxRange: NSRange(location: lineRange.location + syntaxRange.location, length: syntaxRange.length),
            syntaxAttributes: revealsSyntax
                ? [.foregroundColor: tertiaryColor, .strikethroughStyle: 0]
                // カーソルの無い行では記法の文字を透明にする。フォントはそのまま保って記法ぶんの幅を
                // 確保し、その位置にチェックボックスを重ねて描画する (EditorTextView 側)。
                : [.foregroundColor: EditorTextColor.clear, .strikethroughStyle: 0]
        )
    case .html:
        return EditorLineAttributes(
            lineRange: lineRange,
            lineAttributes: [
                // attachment 表示を復元するまでの一時後退。生の HTML だとわかるよう等幅書体にする
                // (大きさは読み合わせやすいよう本文に合わせる)。
                .font: EditorTextFont.monospacedSystemFont(ofSize: bodyFontSize, weight: .regular),
                .foregroundColor: inkColor,
                .paragraphStyle: paragraphStyle,
            ],
            syntaxRange: nil,
            syntaxAttributes: nil
        )
    case .paragraph:
        // 段落の折り返し行の行間は見本(1i)の本文に合わせる。空行はブロックの区切りのため行間を足さない。
        if !lineText.isEmpty {
            paragraphStyle.lineSpacing = inkLineSpacing(fontSize: bodyFontSize, multiplier: 2.05)
        }
        return EditorLineAttributes(
            lineRange: lineRange,
            lineAttributes: [
                .font: editorFont(weight: .regular, size: bodyFontSize),
                .foregroundColor: inkColor,
                .paragraphStyle: paragraphStyle,
            ],
            syntaxRange: nil,
            syntaxAttributes: nil
        )
    }
}

/// 選択 (キャレット) がこの行の記法を生で見せる位置にあるか。キャレットはその行の中にあるとき、
/// 範囲選択はその行と交差するときに記法を見せる (Obsidian の Live Preview と同じ)。
/// - Parameter lineRange: 行末の改行を含む行の範囲。
func editorLineRevealsSyntax(lineRange: NSRange, selectedRange: NSRange, textLength: Int) -> Bool {
    if selectedRange.length == 0 {
        // 末尾に改行の無い最終行では、文末のキャレット位置が行の範囲の1つ外になるため個別に見る。
        return NSLocationInRange(selectedRange.location, lineRange)
            || (selectedRange.location == NSMaxRange(lineRange) && NSMaxRange(lineRange) == textLength)
    }
    return NSIntersectionRange(lineRange, selectedRange).length > 0
}

/// range を含む行範囲の装飾を引き直す。文字は一切変更せず、属性だけを貼り直す。
/// IME 変換中の行 (markedRange と交差する行) は、変換中テキストの下線などの属性を壊さないよう触らない。
func editorRestyle(
    textStorage: NSTextStorage,
    range: NSRange,
    bodyFontSize: CGFloat,
    selectedRange: NSRange,
    markedRange: NSRange?
) {
    let nsText = textStorage.string as NSString
    let clampedLocation = min(max(0, range.location), nsText.length)
    let clampedRange = NSRange(
        location: clampedLocation,
        length: min(max(0, range.length), nsText.length - clampedLocation)
    )
    let styleRange = nsText.lineRange(for: clampedRange)

    textStorage.beginEditing()
    var location = styleRange.location
    // 空のドキュメントでも1周して抜ける (lineRange が空範囲を返すため while では回らない)。
    repeat {
        let lineRange = nsText.lineRange(for: NSRange(location: location, length: 0))
        location = NSMaxRange(lineRange) + (lineRange.length == 0 ? 1 : 0)
        if let markedRange, NSIntersectionRange(lineRange, markedRange).length > 0 {
            continue
        }
        // 行末の改行を除いた、行の文字の範囲。
        var contentRange = lineRange
        if contentRange.length > 0, nsText.character(at: NSMaxRange(contentRange) - 1) == 0x0A {
            contentRange.length -= 1
        }
        let attributes = editorLineAttributes(
            lineText: nsText.substring(with: contentRange),
            lineRange: contentRange,
            bodyFontSize: bodyFontSize,
            revealsSyntax: editorLineRevealsSyntax(
                lineRange: lineRange,
                selectedRange: selectedRange,
                textLength: nsText.length
            )
        )
        // 行末の改行にも行の属性を与え、行の高さと段落スタイルを行全体で一貫させる。
        textStorage.setAttributes(attributes.lineAttributes, range: lineRange)
        if let syntaxRange = attributes.syntaxRange, let syntaxAttributes = attributes.syntaxAttributes {
            textStorage.addAttributes(syntaxAttributes, range: syntaxRange)
        }
    } while location < NSMaxRange(styleRange)
    textStorage.endEditing()
}

/// チェックボックスを重ねて描画するチェックリスト行の情報。
struct EditorChecklistBox: Equatable {
    /// 記法「- [ ] 」のドキュメント内の範囲。この矩形に重ねてチェックボックスを描く。
    var syntaxRange: NSRange
    var done: Bool
}

/// チェックボックスを重ねる行 (カーソルの無いチェックリスト行) を本文全体から列挙する。
/// カーソルのある行は記法を生で見せるため重ねない。
func editorChecklistBoxes(text: NSString, selectedRange: NSRange) -> [EditorChecklistBox] {
    var boxes: [EditorChecklistBox] = []
    var location = 0
    while location < text.length {
        let lineRange = text.lineRange(for: NSRange(location: location, length: 0))
        location = NSMaxRange(lineRange)
        if editorLineRevealsSyntax(lineRange: lineRange, selectedRange: selectedRange, textLength: text.length) {
            continue
        }
        var contentRange = lineRange
        if contentRange.length > 0, text.character(at: NSMaxRange(contentRange) - 1) == 0x0A {
            contentRange.length -= 1
        }
        if case .checklistItem(let done, let syntaxRange) = editorLineStyle(lineText: text.substring(with: contentRange)) {
            boxes.append(
                EditorChecklistBox(
                    syntaxRange: NSRange(location: contentRange.location + syntaxRange.location, length: syntaxRange.length),
                    done: done
                )
            )
        }
    }
    return boxes
}
