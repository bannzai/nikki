import SwiftUI

#if DEBUG
/// ホームヘッダのモック。HomeHeader と同じ見た目(Nikki ロゴ + 人物アイコン)を、
/// 設定画面への navigationDestination を持たない静的表現で再現する。
struct AppStoreScreenshotHomeHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Nikki")
                .font(.inkScreenTitle)
                .tracking(20 * 0.03)
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
            Image(systemName: "person")
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Color(hex: 0x52514E))
                .frame(width: 38, height: 38)
        }
    }
}

/// 検索バーのモック。InkSearchBar と同じ見た目を、フォーカス管理を持たない静的表現で再現する。
/// InkSearchBar は FocusState binding を要求するためスクショ用にはこちらを使う。
struct AppStoreScreenshotSearchBar: View {
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: InkIcons.search)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.inkTextTertiary)
            Text(placeholder)
                .font(.ink(14, .regular))
                .foregroundStyle(Color.inkTextTertiary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkSurfaceInset)
        )
    }
}

/// 時系列リスト1行のモック。HomeEntryRow と同じレイアウトで、曜日ラベルを言語別に渡せるようにする
/// (HomeEntryRow は曜日を日本語固定で導出するため、英語スクショにはそのまま使えない)。
struct AppStoreScreenshotEntryRow: View {
    let day: Int
    let weekday: String
    let title: String
    let excerpt: String
    let showsSeparator: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 0) {
                    Text("\(day)")
                        .font(.ink(21, .bold))
                        .foregroundStyle(Color.ink)
                    Text(weekday)
                        .font(.ink(11, .regular))
                        .foregroundStyle(Color.inkTextTertiary)
                }
                .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.inkListItemTitle)
                        .foregroundStyle(Color.ink)
                    Text(excerpt)
                        .font(.ink(13))
                        .lineSpacing(inkLineSpacing(fontSize: 13, multiplier: 1.8))
                        .foregroundStyle(Color.inkTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        // 英語の抜粋が1行に切り詰められることがあるため、lineLimit までの理想の高さを確保する。
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)

            if showsSeparator {
                Rectangle()
                    .fill(Color.inkSeparator)
                    .frame(height: 0.5)
            }
        }
    }
}

/// 時系列リストの月見出しのモック。HomeListBody の月見出しと同じスタイルで、文言を言語別に渡す。
struct AppStoreScreenshotMonthLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.ink(12, .bold).weight(.semibold))
            .foregroundStyle(Color.inkTextTertiary)
    }
}

/// 墨 pill ボタンのモック。LockFaceIDButton の見た目(高さ50・横パディング26・角丸25)を
/// 生体認証の評価を持たない静的表現で再現する。
struct AppStoreScreenshotPillButton: View {
    let systemName: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .regular))
            Text(title)
                .font(.ink(15, .medium).weight(.semibold))
        }
        .foregroundStyle(Color.inkPrimaryButtonText)
        .frame(height: 50)
        .padding(.horizontal, 26)
        .background(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.ink)
        )
    }
}
#endif
