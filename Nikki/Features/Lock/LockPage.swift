import SwiftUI

/// 自動ロック時に表示するロック画面(1f)。背景の日記本文をぼかして中身を守り、
/// 中央のオーバーレイで再開を促す。解除後は呼び出し側が直前の画面へ復帰させる。
struct LockPage: View {
    /// Face ID ボタンのタップで呼ばれる。実際の生体認証・解除処理は呼び出し側が担う。
    var body: some View {
        ZStack {
            Color.inkPaper
            LockSkeletonBackground()
            LockOverlay()
        }
        .ignoresSafeArea()
    }
}

struct LockPage_Previews: PreviewProvider {
    static var previews: some View {
        LockPage()
    }
}
