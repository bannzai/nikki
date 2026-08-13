import SwiftUI

/// 自動ロック時に表示するロック画面(1f)。背景の日記本文をぼかして中身を守り、
/// 中央のオーバーレイで再開を促す。解除に成功すると locked を false に戻し、直前の画面がそのまま現れる。
/// 解除認証はボタンを押した時にだけ提示する。macOS でウィンドウのアクティブ化を起点に自動提示すると、
/// 他アプリと行き来するたびにダイアログが出て邪魔なため行わない( https://github.com/bannzai/nikki/issues/47 )。
struct LockPage: View {
    /// 自動ロック状態。Face ID 解除の成功で false に戻す。
    @Binding var locked: Bool

    var body: some View {
        ZStack {
            Color.inkPaper
            LockSkeletonBackground()
            LockOverlay(locked: $locked)
        }
        .ignoresSafeArea()
    }
}

struct LockPage_Previews: PreviewProvider {
    static var previews: some View {
        LockPage(locked: .constant(true))
    }
}
