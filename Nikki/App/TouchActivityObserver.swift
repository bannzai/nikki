#if os(iOS)
import SwiftUI
import UIKit

/// 配下へのあらゆるタッチを、消費せずに観測して無操作タイマーのリセットにつなぐ橋渡し View。
/// SwiftUI の simultaneousGesture(DragGesture(minimumDistance: 0)) で拾うと、UIKit 実装のコントロール
/// (システムのナビゲーションバーの戻るボタン・List の NavigationLink) のタップを奪って遷移が効かなくなるため、
/// 認識を主張しない UIGestureRecognizer をウィンドウに付けて観測だけ行う (macOS の NSEvent ローカルモニターの iOS 版)。
struct TouchActivityObserver: UIViewRepresentable {
    /// タッチを観測したときに呼ぶ。無操作タイマーのリセットにつなぐ。
    let onTouch: () -> Void

    func makeUIView(context: Context) -> TouchActivityObserverView {
        TouchActivityObserverView(onTouch: onTouch)
    }

    func updateUIView(_ uiView: TouchActivityObserverView, context: Context) {
        uiView.recognizer.onTouch = onTouch
    }
}

/// ウィンドウに参加したタイミングで観測用 recognizer をウィンドウへ付け、外れたら取り除く実体 View。
/// recognizer を View 自身ではなくウィンドウに付けるのは、この View が背景として大きさを持たなくても
/// 画面全体 (ナビゲーションバーを含む) のタッチを観測できるようにするため。
final class TouchActivityObserverView: UIView {
    let recognizer: TouchObserverGestureRecognizer

    // recognizer の生成と初期 closure の受け渡しが必要なため、カスタム init を定義する。
    init(onTouch: @escaping () -> Void) {
        recognizer = TouchObserverGestureRecognizer()
        recognizer.onTouch = onTouch
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        recognizer.view?.removeGestureRecognizer(recognizer)
        window?.addGestureRecognizer(recognizer)
    }
}

/// タッチを観測するだけで認識を一切主張しない recognizer。
/// 認識状態を .possible のまま保つことで他の recognizer・コントロールへの配送を妨げず、
/// タッチ終了時に .failed へ倒して次のタッチに備える。
final class TouchObserverGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    /// タッチを観測したときに呼ぶ。
    var onTouch: () -> Void = {}

    // delegate を自分にして「常に他と同時認識」を宣言するため、カスタム init を定義する。
    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouch()
    }

    // スクロール中など指を動かし続けている間もロックされないよう、移動もリセットにつなぐ。
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouch()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
#endif
