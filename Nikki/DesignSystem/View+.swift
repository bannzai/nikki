import SwiftUI

extension View {
    /// 画面タイトルをシステムのナビゲーションバー中央に置く。戻るボタンは NavigationStack の標準に任せる。
    func inkNavigationBar(title: String) -> some View {
        modifier(InkNavigationBarTitle(title: title))
    }

    /// エディタの日付キャプションをシステムのナビゲーションバー中央に置く。
    /// 画面の名前ではなく書いている日を示すため、タイトルより控えめな書体にする。
    func inkNavigationBarCaption(caption: String) -> some View {
        modifier(InkNavigationBarCaption(caption: caption))
    }

    /// ナビゲーションバーの地を紙色に寄せ、タイトル領域を1行の高さに固定する。
    /// 中央に何も置かないホームのように、タイトル・キャプションを持たない画面で使う。
    func inkNavigationBarStyle() -> some View {
        modifier(InkNavigationBarStyle())
    }
}

/// ナビゲーションバー右端のテキストボタン。エディタのテンプレート選択・テンプレート作成の確定など、
/// 画面ごとの主操作を置く。
struct InkNavigationBarTrailingButton: ToolbarContent {
    let text: String
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .inkNavigationBarTrailing) {
            Button(action: action) {
                Text(text)
                    .font(.ink(13.5, .regular))
                    .foregroundStyle(Color.inkTextSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

/// タイトルを principal に置くナビゲーションバー。紙色の地は InkNavigationBarStyle と共有する。
private struct InkNavigationBarTitle: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.inkNavTitle)
                        .foregroundStyle(Color.ink)
                }
            }
            .inkNavigationBarStyle()
    }
}

/// キャプションを principal に置くナビゲーションバー。紙色の地は InkNavigationBarStyle と共有する。
private struct InkNavigationBarCaption: ViewModifier {
    let caption: String

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(caption)
                        .font(.ink(12.5, .regular))
                        .foregroundStyle(Color.inkTextTertiary)
                }
            }
            .inkNavigationBarStyle()
    }
}

/// ナビゲーションバーの地をテーマの紙色に合わせる。紙色は environment 経由でしか読めず
/// View extension からは参照できないため、ViewModifier として持つ。
private struct InkNavigationBarStyle: ViewModifier {
    @Environment(\.paperColor) private var paperColor

    func body(content: Content) -> some View {
        content
            // 中央に置くものがない画面でも、空のラージタイトル領域が開かないよう1行の高さに固定する。
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(paperColor, for: .inkNavigationBar)
            .toolbarBackground(.visible, for: .inkNavigationBar)
    }
}
