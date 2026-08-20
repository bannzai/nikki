import SwiftUI

#if DEBUG
/// スクショ5枚目: ホーム(カレンダー)。書いた日々の振り返りと iPhone / iPad / Mac 同期を訴求する。
struct AppStoreScreenshot5Page: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (title, subtitle) = switch language {
        case .ja: (
            "書いた日々を\nカレンダーで振り返る",
            "iPhone・iPad・Mac でいつでも同期"
        )
        case .en: (
            "Look back over\nyour written days",
            "Syncs across iPhone, iPad, and Mac"
        )
        }
        AppStoreScreenshotFrame(canvas: canvas, title: title, subtitle: subtitle) {
            AppStoreScreenshotCalendarScreen(language: language, canvas: canvas)
        }
    }
}

/// ホーム(カレンダー)のモック画面。日グリッドは本番の HomeCalendarDaysGrid を再利用し、
/// 月送りナビ・曜日ヘッダ・プレビューカードは文言が日本語固定のため言語別の静的表現にする。
struct AppStoreScreenshotCalendarScreen: View {
    let language: AppStoreScreenshotLanguage
    let canvas: AppStoreScreenshotCanvas

    var body: some View {
        let (segments, monthLabel, weekdaySymbols, cardDate, cardTime, cardTitle, cardExcerpt) = switch language {
        case .ja: (
            ["リスト", "カレンダー"],
            "2026年7月",
            ["日", "月", "火", "水", "木", "金", "土"],
            "7月18日 土曜日",
            "21:04",
            "梅雨明け",
            "朝から蝉が鳴いていた。ベランダの鉢に水をやりながら、今年も夏が来たんだなと思う。"
        )
        case .en: (
            ["List", "Calendar"],
            "July 2026",
            ["S", "M", "T", "W", "T", "F", "S"],
            "Saturday, July 18",
            "21:04",
            "Summer begins",
            "Cicadas were singing from early morning. Watering the pots on the balcony, I realized summer is here again."
        )
        }
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                AppStoreScreenshotHomeHeader()
                InkSegmentedControl(options: segments, selectedIndex: .constant(1))
            }
            .padding(.horizontal, 24)
            .padding(.top, appStoreScreenshotScreenTopPadding(canvas: canvas))

            VStack(alignment: .leading, spacing: 0) {
                // HomeCalendarMonthNav と同じ月送りナビの見た目。月表記が日本語固定のため文言を渡せる形にする。
                HStack(spacing: 0) {
                    Image(systemName: InkIcons.chevronLeft)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkTextSecondary)
                    Spacer(minLength: 0)
                    Text(monthLabel)
                        .font(.ink(15, .bold))
                        .foregroundStyle(Color.ink)
                    Spacer(minLength: 0)
                    Image(systemName: InkIcons.chevronRight)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkTextSecondary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 14)

                // HomeCalendarWeekdayHeader と同じ曜日ヘッダの見た目。曜日記号を言語別に渡す。
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.ink(11, .regular))
                            .foregroundStyle(Color.inkTextTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 6)

                AppStoreScreenshotCalendarGrid()

                // HomeCalendarPreviewCard と同じ today の日記プレビューの見た目。日付表記を言語別に渡す。
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(cardDate)
                            .font(.ink(13, .bold))
                            .foregroundStyle(Color.ink)
                        Text(cardTime)
                            .font(.ink(11, .regular))
                            .foregroundStyle(Color.inkTextTertiary)
                    }
                    .padding(.bottom, 6)

                    Text(cardTitle)
                        .font(.ink(14.5, .bold))
                        .foregroundStyle(Color.ink)
                        .padding(.bottom, 3)

                    Text(cardExcerpt)
                        .font(.ink(12.5))
                        .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.8))
                        .foregroundStyle(Color.inkTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .inkCard(cornerRadius: 14)
                .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
        }
    }
}

/// カレンダーの日グリッドのモック。HomeCalendarDaysGrid / HomeCalendarDayCell と同じ見た目
/// (today は36pxの墨円で反転・日記のある日は4pxの墨ドット・未来日は微色)を、
/// NavigationLink を持たない静的表現で再現する(NavigationStack 外では link の無効化でセルが灰色になるため)。
struct AppStoreScreenshotCalendarGrid: View {
    /// 表示する月(2026年7月)の日数。参照日 7/18 を today とする。
    private let dayCount = 31
    /// 月初(2026-07-01 は水曜)までの空白セル数(日曜はじまりの並びでの水曜の位置)。
    private let leadingBlanks = 3
    /// today の日付。
    private let today = 18
    /// 日記がある日(墨ドットを出す日)。
    private let dottedDays: Set<Int> = [3, 6, 9, 12, 14, 16]

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 6
        ) {
            // 空白セルの id は日付(1...31)と衝突しないよう負数にする(衝突すると日付側のセルが描画されない)。
            ForEach(-leadingBlanks..<0, id: \.self) { _ in
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            ForEach(1...dayCount, id: \.self) { day in
                VStack(spacing: 0) {
                    if day == today {
                        Text("\(day)")
                            .font(.ink(14, .bold))
                            .foregroundStyle(Color.inkPrimaryButtonText)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.ink))
                            .padding(.top, 2)
                        Spacer(minLength: 0)
                    } else {
                        Text("\(day)")
                            .font(.ink(14, .regular))
                            .foregroundStyle(day > today ? Color.inkTextQuaternary : Color.ink)
                            .padding(.top, 8)
                        Spacer(minLength: 0)
                        Circle()
                            .fill(dottedDays.contains(day) ? Color.ink : Color.clear)
                            .frame(width: 4, height: 4)
                            .padding(.bottom, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38, alignment: .top)
            }
        }
    }
}

struct AppStoreScreenshot5Page_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshot5Page(language: .ja, canvas: .iphone)
    }
}
#endif
