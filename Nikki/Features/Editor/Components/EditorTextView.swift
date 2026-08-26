import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// 本文全体を1つのテキストビューで編集する。表示は markdown の記法を行単位で装飾し、
/// ソースは常に markdown 文字列 (text Binding) のまま持つ (issue #111)。
/// 行頭の Backspace での行結合・行途中の Return での分割・↑↓ 移動・行またぎの選択・undo は
/// テキストビュー標準の挙動として成立させる。記法の解釈と属性の組み立ては EditorMarkdownStyler が行う。
struct EditorTextView {
    @Binding var text: String
    /// 段落・チェックリストの文字の大きさ。設定「文字の大きさ」を反映する (見出しは見出しの書体で固定)。
    let bodyFontSize: CGFloat
}

/// 本文全体をコピーするメニュー項目の動作。テキストビューの編集メニュー (iOS) と
/// 右クリックメニュー (macOS) から使う。ブロックのメニューだった「すべてコピー」(issue #100) の置き換え。
private func editorCopyAll(markdown: String) {
    // 書き終えていない空のブロックは、日記への書き戻し (withoutEmptyText) と同様にコピーへ含めない。
    editorCopyBlocksToPasteboard(blocks: Block.blocks(fromMarkdown: markdown).withoutEmptyText)
}

/// チェックボックスの見た目の寸法。EditorCheckboxToggleStyle (SwiftUI 側) の見本(1j)の寸法と対応させる。
private let editorCheckboxBoxSize: CGFloat = 19

/// チェックボックスを描く。見た目は EditorCheckboxToggleStyle (完了は墨地+白チェック、
/// 未完了は角丸枠) と対応させる。bounds は記法「- [ ] 」の矩形で、ボックスは左寄せ・上下中央に置く。
/// 座標系は上下逆でも左右と大きさが変わらないため、flipped の有無に依存しない。
private func editorDrawCheckbox(context: CGContext?, bounds: CGRect, done: Bool) {
    guard let context else {
        return
    }
    let boxRect = CGRect(
        x: bounds.minX,
        y: bounds.midY - editorCheckboxBoxSize / 2,
        width: editorCheckboxBoxSize,
        height: editorCheckboxBoxSize
    )
    if done {
        context.addPath(CGPath(roundedRect: boxRect, cornerWidth: 5, cornerHeight: 5, transform: nil))
        context.setFillColor(EditorTextColor(Color.ink).cgColor)
        context.fillPath()
        // チェックマーク (SF Symbols を使わず線で描き、iOS / macOS で同じ形にする)。
        // 座標は y 下向き (iOS の draw と flipped な NSView) 前提で、折れ点が下に来る形。
        context.setStrokeColor(EditorTextColor(Color.inkPrimaryButtonText).cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: boxRect.minX + 4.5, y: boxRect.minY + 10))
        context.addLine(to: CGPoint(x: boxRect.minX + 8, y: boxRect.minY + 13.5))
        context.addLine(to: CGPoint(x: boxRect.minX + 14.5, y: boxRect.minY + 5.5))
        context.strokePath()
    } else {
        context.addPath(
            CGPath(
                roundedRect: boxRect.insetBy(dx: 0.75, dy: 0.75),
                cornerWidth: 4.25,
                cornerHeight: 4.25,
                transform: nil
            )
        )
        context.setStrokeColor(EditorTextColor(Color.ink).withAlphaComponent(0.35).cgColor)
        context.setLineWidth(1.5)
        context.strokePath()
    }
}

#if canImport(UIKit)

extension EditorTextView: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        // TextKit 2 スタックで生成する。layoutManager (TextKit 1) には触れず、
        // 位置計算は UITextInput の firstRect(for:) で行う (TextKit 1 への内部フォールバックを防ぐ)。
        let textView = EditorUITextView(usingTextLayoutManager: true)
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        // 余白は置き換え前の EditorPage (ScrollView 内の padding 水平28・上10) に合わせる。
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 28, bottom: 10, right: 28)
        textView.textContainer.lineFragmentPadding = 0
        textView.keyboardDismissMode = .interactive
        textView.text = text
        textView.onLayoutSizeChange = { [weak coordinator = context.coordinator] in
            coordinator?.updateCheckboxes()
        }
        context.coordinator.textView = textView
        context.coordinator.restyleAll()
        // 開いたらすぐ書けるよう、表示後に本文末尾へキャレットを置いてフォーカスする
        // (日記の続きを書く位置。表示前の becomeFirstResponder はキーボードが上がらないため次の runloop で行う)。
        DispatchQueue.main.async {
            textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
            textView.becomeFirstResponder()
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        // IME 変換中 (markedTextRange != nil) は外部からの text 差し替えをしない (issue #86 と同じ理由)。
        if textView.markedTextRange == nil, textView.text != text {
            textView.text = text
            context.coordinator.restyleAll()
        }
        if context.coordinator.styledBodyFontSize != bodyFontSize {
            context.coordinator.restyleAll()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// テキストビューと markdown Binding・装飾・チェックボックスのオーバーレイをつなぐ。
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: EditorTextView
        weak var textView: UITextView?
        /// 現在の装飾が使っている文字の大きさ。設定「文字の大きさ」の変更を検知して引き直すための目印。
        var styledBodyFontSize: CGFloat = 0
        /// 直前の編集で文字が入った範囲。textViewDidChange で装飾を引き直す行の特定に使う。
        var editedRange: NSRange?
        /// 記法を生で見せている行の範囲。カーソル移動で隠し直す行の特定に使う。
        var revealedLineRange = NSRange(location: 0, length: 0)
        /// チェックボックスのオーバーレイ。行数の増減に合わせて使い回す。
        var checkboxViews: [EditorCheckboxOverlayView] = []

        // parent (representable の値) を後から差し替えるため memberwise ではなくカスタム init にする。
        init(parent: EditorTextView) {
            self.parent = parent
        }

        /// IME 変換中 (未確定) のテキストの範囲。変換中の行は装飾を引き直さない。
        private var markedRange: NSRange? {
            guard let textView, let markedTextRange = textView.markedTextRange else {
                return nil
            }
            return NSRange(
                location: textView.offset(from: textView.beginningOfDocument, to: markedTextRange.start),
                length: textView.offset(from: markedTextRange.start, to: markedTextRange.end)
            )
        }

        /// 本文全体の装飾を引き直す。開いた直後・本文の差し替え・文字の大きさの変更で使う。
        func restyleAll() {
            guard let textView else {
                return
            }
            restyle(range: NSRange(location: 0, length: (textView.text as NSString).length))
        }

        /// range を含む行の装飾を引き直し、カーソル行の記録・チェックボックス・入力属性も追随させる。
        private func restyle(range: NSRange) {
            guard let textView else {
                return
            }
            styledBodyFontSize = parent.bodyFontSize
            editorRestyle(
                textStorage: textView.textStorage,
                range: range,
                bodyFontSize: parent.bodyFontSize,
                selectedRange: textView.selectedRange,
                markedRange: markedRange
            )
            invalidateLayout(range: range)
            revealedLineRange = (textView.text as NSString).lineRange(for: clampedSelectedRange())
            updateTypingAttributes()
            updateCheckboxes()
        }

        /// 引き直した行の描画を無効化して再描画させる。チェックリスト記法の隠し直しは色だけの
        /// 属性変更のため、iOS の TextKit 2 では無効化しないと前の描画 (生の記法) が残る
        /// (見出しはフォントも変わるためレイアウト無効化が自動で走り、この問題が出ない)。
        private func invalidateLayout(range: NSRange) {
            guard let textView, let textLayoutManager = textView.textLayoutManager,
                  let textContentManager = textLayoutManager.textContentManager else {
                return
            }
            let nsText = textView.text as NSString
            let clampedLocation = min(max(0, range.location), nsText.length)
            let lineRange = nsText.lineRange(
                for: NSRange(
                    location: clampedLocation,
                    length: min(max(0, range.length), nsText.length - clampedLocation)
                )
            )
            let documentLocation = textContentManager.documentRange.location
            guard let start = textContentManager.location(documentLocation, offsetBy: lineRange.location),
                  let end = textContentManager.location(documentLocation, offsetBy: NSMaxRange(lineRange)),
                  let textRange = NSTextRange(location: start, end: end) else {
                return
            }
            textLayoutManager.invalidateLayout(for: textRange)
        }

        /// 本文の長さに収めた選択範囲。装飾の引き直しの途中で選択が本文の外を指す瞬間があっても落ちないようにする。
        private func clampedSelectedRange() -> NSRange {
            guard let textView else {
                return NSRange(location: 0, length: 0)
            }
            let length = (textView.text as NSString).length
            let location = min(textView.selectedRange.location, length)
            return NSRange(location: location, length: min(textView.selectedRange.length, length - location))
        }

        /// キャレットのある行の装飾を次の入力へも引き継ぐ。IME の変換中テキストが
        /// (変換中は装飾を引き直さないため) 行の書体と違う書体で出るのを防ぐ。
        private func updateTypingAttributes() {
            guard let textView else {
                return
            }
            let nsText = textView.text as NSString
            let lineRange = nsText.lineRange(for: clampedSelectedRange())
            var contentRange = lineRange
            if contentRange.length > 0, nsText.character(at: NSMaxRange(contentRange) - 1) == 0x0A {
                contentRange.length -= 1
            }
            textView.typingAttributes = editorLineAttributes(
                lineText: nsText.substring(with: contentRange),
                lineRange: contentRange,
                bodyFontSize: parent.bodyFontSize,
                revealsSyntax: true
            ).lineAttributes
        }

        /// チェックボックスのオーバーレイを、カーソルの無いチェックリスト行の記法の位置へ並べ直す。
        func updateCheckboxes() {
            guard let textView else {
                return
            }
            textView.layoutIfNeeded()
            let boxes = editorChecklistBoxes(text: textView.text as NSString, selectedRange: textView.selectedRange)
            for (index, box) in boxes.enumerated() {
                let view: EditorCheckboxOverlayView
                if index < checkboxViews.count {
                    view = checkboxViews[index]
                } else {
                    view = EditorCheckboxOverlayView()
                    checkboxViews.append(view)
                    textView.addSubview(view)
                }
                guard let start = textView.position(from: textView.beginningOfDocument, offset: box.syntaxRange.location),
                      let end = textView.position(from: textView.beginningOfDocument, offset: NSMaxRange(box.syntaxRange)),
                      let textRange = textView.textRange(from: start, to: end) else {
                    view.isHidden = true
                    continue
                }
                let rect = textView.firstRect(for: textRange)
                if rect.isNull || rect.isInfinite || rect.width <= 0 {
                    view.isHidden = true
                    continue
                }
                view.isHidden = false
                view.frame = rect
                view.done = box.done
                view.onToggle = { [weak self] in
                    self?.toggleChecklistItem(syntaxRange: box.syntaxRange)
                }
                view.setNeedsDisplay()
            }
            for extraView in checkboxViews.dropFirst(boxes.count) {
                extraView.isHidden = true
            }
        }

        /// チェックリスト行の「[ ]」⇔「[x]」を裏返す。文字数が変わらない置換のため、キャレットは動かさない。
        private func toggleChecklistItem(syntaxRange: NSRange) {
            guard let textView else {
                return
            }
            let nsText = textView.text as NSString
            // 完了状態の文字は記法「- [x] 」の「[」の次 = 記法の先頭から3文字目。
            let stateRange = NSRange(location: syntaxRange.location + 3, length: 1)
            if NSMaxRange(stateRange) > nsText.length {
                return
            }
            guard let start = textView.position(from: textView.beginningOfDocument, offset: stateRange.location),
                  let end = textView.position(from: textView.beginningOfDocument, offset: NSMaxRange(stateRange)),
                  let textRange = textView.textRange(from: start, to: end) else {
                return
            }
            let done = nsText.substring(with: stateRange).lowercased() == "x"
            // undo に乗る置換経路 (UITextInput.replace) を通し、置換後もキャレット位置を保つ。
            let selectedTextRange = textView.selectedTextRange
            textView.replace(textRange, withText: done ? " " : "x")
            textView.selectedTextRange = selectedTextRange
            parent.text = textView.text
            restyle(range: stateRange)
        }

        // MARK: UITextViewDelegate

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText replacement: String) -> Bool {
            // Windows 由来のクリップボード等の CRLF・CR は、markdown のソースを LF で保つため貼り付け時に揃える。
            if replacement.contains("\r") {
                if let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
                   let end = textView.position(from: textView.beginningOfDocument, offset: NSMaxRange(range)),
                   let textRange = textView.textRange(from: start, to: end) {
                    textView.replace(textRange, withText: Block.normalizingNewlines(text: replacement))
                }
                return false
            }
            editedRange = NSRange(location: range.location, length: (replacement as NSString).length)
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            // IME の変換中の更新・確定は shouldChangeTextIn を通らないため、その場合はカーソル行を引き直す。
            restyle(range: editedRange ?? clampedSelectedRange())
            editedRange = nil
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let lineRange = (textView.text as NSString).lineRange(for: clampedSelectedRange())
            if lineRange != revealedLineRange {
                // 記法を隠し直す行 (元のカーソル行) と生で見せる行 (今のカーソル行) をまとめて引き直す。
                restyle(range: NSUnionRange(revealedLineRange, lineRange))
            }
        }

        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            // ブロックのコンテキストメニューだった「すべてコピー」(issue #100) を編集メニューの末尾に置く。
            UIMenu(
                children: suggestedActions + [
                    UIAction(title: String(localized: "Copy All"), image: UIImage(systemName: InkIcons.copyAll)) { _ in
                        editorCopyAll(markdown: textView.text)
                    }
                ]
            )
        }
    }
}

/// レイアウトの変化 (画面回転・キーボードによる縮み等) をコーディネータへ伝えるテキストビュー。
/// スクロールでは通知しない (チェックボックスは本文と同じ座標系に置かれ、スクロールに追随するため)。
final class EditorUITextView: UITextView {
    /// 自身の大きさが変わった直後に呼ばれる。チェックボックスの並べ直しに使う。
    var onLayoutSizeChange: (() -> Void)?
    /// 前回レイアウト時の大きさ。スクロール (bounds の origin だけの変化) と区別する。
    private var layoutedSize: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != layoutedSize {
            layoutedSize = bounds.size
            onLayoutSizeChange?()
        }
    }
}

/// チェックリスト行の記法「- [ ] 」に重ねて描画するチェックボックス。タップで完了を裏返す。
/// このビューがタッチを受け取るため、記法の上のタップでキャレットは動かない。
final class EditorCheckboxOverlayView: UIView {
    var done: Bool = false
    var onToggle: (() -> Void)?

    // タップの受け付けと透明背景の設定が必要なためカスタム init にする。
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    // UIView のサブクラスに要求される。Storyboard からは使わない。
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onToggle?()
    }

    override func draw(_ rect: CGRect) {
        editorDrawCheckbox(context: UIGraphicsGetCurrentContext(), bounds: bounds, done: done)
    }
}

#else

extension EditorTextView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView {
        // TextKit 2 スタックで生成する。位置計算は firstRect(forCharacterRange:) で行い、
        // layoutManager (TextKit 1) には触れない (TextKit 1 への内部フォールバックを防ぐ)。
        let textView = EditorNSTextView(usingTextLayoutManager: true)
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.allowsUndo = true
        // 装飾は NSAttributedString の属性で行うためリッチテキストにする。貼り付けで入った
        // 外部の装飾は、編集のたびの行単位の引き直し (setAttributes) が上書きして正規化する。
        textView.isRichText = true
        textView.importsGraphics = false
        // 「- [ ]」等の記法が自動置換 (スマート引用符・スマートダッシュ) で壊れないようにする。
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        // 余白は置き換え前の EditorPage (ScrollView 内の padding 水平28・上10) に合わせる。
        textView.textContainerInset = NSSize(width: 28, height: 10)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.string = text
        textView.onLayoutSizeChange = { [weak coordinator = context.coordinator] in
            coordinator?.updateCheckboxes()
        }
        context.coordinator.textView = textView
        context.coordinator.restyleAll()

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        // 開いたらすぐ書けるよう、表示後に本文末尾へキャレットを置いてフォーカスする
        // (日記の続きを書く位置。window が付く前は first responder にできないため次の runloop で行う)。
        DispatchQueue.main.async {
            textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))
            textView.window?.makeFirstResponder(textView)
            // チェックボックスの矩形は window が付いてからでないと計算できないため、ここで並べ直す。
            context.coordinator.updateCheckboxes()
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }
        // IME 変換中 (未確定テキストあり) は外部からの text 差し替えをしない (issue #86 と同じ理由)。
        if !textView.hasMarkedText(), textView.string != text {
            textView.string = text
            context.coordinator.restyleAll()
        }
        if context.coordinator.styledBodyFontSize != bodyFontSize {
            context.coordinator.restyleAll()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// テキストビューと markdown Binding・装飾・チェックボックスのオーバーレイをつなぐ。
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorTextView
        weak var textView: NSTextView?
        /// 現在の装飾が使っている文字の大きさ。設定「文字の大きさ」の変更を検知して引き直すための目印。
        var styledBodyFontSize: CGFloat = 0
        /// 直前の編集で文字が入った範囲。textDidChange で装飾を引き直す行の特定に使う。
        var editedRange: NSRange?
        /// 記法を生で見せている行の範囲。カーソル移動で隠し直す行の特定に使う。
        var revealedLineRange = NSRange(location: 0, length: 0)
        /// チェックボックスのオーバーレイ。行数の増減に合わせて使い回す。
        var checkboxViews: [EditorCheckboxOverlayView] = []

        // parent (representable の値) を後から差し替えるため memberwise ではなくカスタム init にする。
        init(parent: EditorTextView) {
            self.parent = parent
        }

        /// IME 変換中 (未確定) のテキストの範囲。変換中の行は装飾を引き直さない。
        private var markedRange: NSRange? {
            guard let textView, textView.hasMarkedText() else {
                return nil
            }
            return textView.markedRange()
        }

        /// 本文全体の装飾を引き直す。開いた直後・本文の差し替え・文字の大きさの変更で使う。
        func restyleAll() {
            guard let textView else {
                return
            }
            restyle(range: NSRange(location: 0, length: (textView.string as NSString).length))
        }

        /// range を含む行の装飾を引き直し、カーソル行の記録・チェックボックス・入力属性も追随させる。
        private func restyle(range: NSRange) {
            guard let textView, let textStorage = textView.textStorage else {
                return
            }
            styledBodyFontSize = parent.bodyFontSize
            editorRestyle(
                textStorage: textStorage,
                range: range,
                bodyFontSize: parent.bodyFontSize,
                selectedRange: textView.selectedRange(),
                markedRange: markedRange
            )
            revealedLineRange = (textView.string as NSString).lineRange(for: clampedSelectedRange())
            updateTypingAttributes()
            updateCheckboxes()
        }

        /// 本文の長さに収めた選択範囲。装飾の引き直しの途中で選択が本文の外を指す瞬間があっても落ちないようにする。
        private func clampedSelectedRange() -> NSRange {
            guard let textView else {
                return NSRange(location: 0, length: 0)
            }
            let length = (textView.string as NSString).length
            let location = min(textView.selectedRange().location, length)
            return NSRange(location: location, length: min(textView.selectedRange().length, length - location))
        }

        /// キャレットのある行の装飾を次の入力へも引き継ぐ。IME の変換中テキストが
        /// (変換中は装飾を引き直さないため) 行の書体と違う書体で出るのを防ぐ。
        private func updateTypingAttributes() {
            guard let textView else {
                return
            }
            let nsText = textView.string as NSString
            let lineRange = nsText.lineRange(for: clampedSelectedRange())
            var contentRange = lineRange
            if contentRange.length > 0, nsText.character(at: NSMaxRange(contentRange) - 1) == 0x0A {
                contentRange.length -= 1
            }
            textView.typingAttributes = editorLineAttributes(
                lineText: nsText.substring(with: contentRange),
                lineRange: contentRange,
                bodyFontSize: parent.bodyFontSize,
                revealsSyntax: true
            ).lineAttributes
        }

        /// チェックボックスのオーバーレイを、カーソルの無いチェックリスト行の記法の位置へ並べ直す。
        func updateCheckboxes() {
            guard let textView, let window = textView.window else {
                return
            }
            textView.layoutSubtreeIfNeeded()
            let boxes = editorChecklistBoxes(text: textView.string as NSString, selectedRange: textView.selectedRange())
            for (index, box) in boxes.enumerated() {
                let view: EditorCheckboxOverlayView
                if index < checkboxViews.count {
                    view = checkboxViews[index]
                } else {
                    view = EditorCheckboxOverlayView()
                    checkboxViews.append(view)
                    textView.addSubview(view)
                }
                // firstRect はスクリーン座標で返るため、window 経由でテキストビューの座標へ戻す。
                let screenRect = textView.firstRect(forCharacterRange: box.syntaxRange, actualRange: nil)
                if screenRect.isEmpty {
                    view.isHidden = true
                    continue
                }
                let rect = textView.convert(window.convertFromScreen(screenRect), from: nil)
                view.isHidden = false
                view.frame = rect
                view.done = box.done
                view.onToggle = { [weak self] in
                    self?.toggleChecklistItem(syntaxRange: box.syntaxRange)
                }
                view.needsDisplay = true
            }
            for extraView in checkboxViews.dropFirst(boxes.count) {
                extraView.isHidden = true
            }
        }

        /// チェックリスト行の「[ ]」⇔「[x]」を裏返す。文字数が変わらない置換のため、キャレットは動かさない。
        private func toggleChecklistItem(syntaxRange: NSRange) {
            guard let textView else {
                return
            }
            let nsText = textView.string as NSString
            // 完了状態の文字は記法「- [x] 」の「[」の次 = 記法の先頭から3文字目。
            let stateRange = NSRange(location: syntaxRange.location + 3, length: 1)
            if NSMaxRange(stateRange) > nsText.length {
                return
            }
            let replacement = nsText.substring(with: stateRange).lowercased() == "x" ? " " : "x"
            // undo に乗る標準の置換経路 (shouldChangeText → 置換 → didChangeText) を通す。
            if textView.shouldChangeText(in: stateRange, replacementString: replacement) {
                textView.textStorage?.replaceCharacters(in: stateRange, with: replacement)
                textView.didChangeText()
            }
        }

        // MARK: NSTextViewDelegate

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // Windows 由来のクリップボード等の CRLF・CR は、markdown のソースを LF で保つため貼り付け時に揃える。
            if let replacementString, replacementString.contains("\r") {
                let normalized = Block.normalizingNewlines(text: replacementString)
                if textView.shouldChangeText(in: affectedCharRange, replacementString: normalized) {
                    textView.textStorage?.replaceCharacters(in: affectedCharRange, with: normalized)
                    textView.didChangeText()
                }
                return false
            }
            editedRange = NSRange(location: affectedCharRange.location, length: ((replacementString ?? "") as NSString).length)
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else {
                return
            }
            parent.text = textView.string
            // IME の変換中の更新・確定は shouldChangeTextIn を通らない場合があるため、その場合はカーソル行を引き直す。
            restyle(range: editedRange ?? clampedSelectedRange())
            editedRange = nil
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView else {
                return
            }
            let lineRange = (textView.string as NSString).lineRange(for: clampedSelectedRange())
            if lineRange != revealedLineRange {
                // 記法を隠し直す行 (元のカーソル行) と生で見せる行 (今のカーソル行) をまとめて引き直す。
                restyle(range: NSUnionRange(revealedLineRange, lineRange))
            }
        }
    }
}

/// 右クリックメニューへ「すべてコピー」を足し、レイアウトの変化をコーディネータへ伝えるテキストビュー。
final class EditorNSTextView: NSTextView {
    /// 自身の大きさが変わった直後に呼ばれる。チェックボックスの並べ直しに使う。
    var onLayoutSizeChange: (() -> Void)?
    /// 前回レイアウト時の大きさ。折り返し位置が変わる幅の変化だけを通知する。
    private var layoutedSize: CGSize = .zero

    override func layout() {
        super.layout()
        if frame.size != layoutedSize {
            layoutedSize = frame.size
            onLayoutSizeChange?()
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        // ブロックのコンテキストメニューだった「すべてコピー」(issue #100) を、
        // OS のテキスト編集メニューの末尾に足して提供する。
        let menu = super.menu(for: event)
        menu?.addItem(.separator())
        let copyAllItem = NSMenuItem(title: String(localized: "Copy All"), action: #selector(copyAllFromMenu(_:)), keyEquivalent: "")
        copyAllItem.target = self
        menu?.addItem(copyAllItem)
        return menu
    }

    /// 右クリックメニューの「すべてコピー」。本文全体を markdown とリッチテキストの2表現でコピーする。
    @objc private func copyAllFromMenu(_ sender: NSMenuItem) {
        editorCopyAll(markdown: string)
    }
}

/// チェックリスト行の記法「- [ ] 」に重ねて描画するチェックボックス。クリックで完了を裏返す。
/// このビューがクリックを受け取るため、記法の上のクリックでキャレットは動かない。
final class EditorCheckboxOverlayView: NSView {
    var done: Bool = false
    var onToggle: (() -> Void)?

    // テキストビュー (flipped) と同じ座標系で frame を扱うため上下反転にする。
    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        editorDrawCheckbox(context: NSGraphicsContext.current?.cgContext, bounds: bounds, done: done)
    }

    override func mouseDown(with event: NSEvent) {
        onToggle?()
    }
}

#endif
