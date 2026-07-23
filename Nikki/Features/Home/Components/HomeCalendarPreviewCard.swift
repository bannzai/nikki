import SwiftUI

/// カレンダー下部の日記プレビューカード。日付 + 時刻 + タイトル + 2行抜粋を白カードで表示する。
struct HomeCalendarPreviewCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(dateLabel)
                    .font(.ink(13, .bold))
                    .foregroundStyle(Color.ink)
                Text(timeLabel)
                    .font(.ink(11, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .padding(.bottom, 6)

            Text(entry.title)
                .font(.ink(14.5, .bold))
                .foregroundStyle(Color.ink)
                .padding(.bottom, 3)

            Text(entry.excerpt)
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
    }

    private var dateLabel: String {
        let comps = Calendar.display.dateComponents([.month, .day, .weekday], from: entry.date)
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        return "\(comps.month ?? 0)月\(comps.day ?? 0)日 \(symbols[(comps.weekday ?? 1) - 1])曜日"
    }

    private var timeLabel: String {
        let comps = Calendar.display.dateComponents([.hour, .minute], from: entry.createdAt)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }
}

struct HomeCalendarPreviewCard_Previews: PreviewProvider {
    static var previews: some View {
        HomeCalendarPreviewCard(entry: SampleData.sampleEntry)
            .padding()
            .background(Color.inkPaper)
    }
}
