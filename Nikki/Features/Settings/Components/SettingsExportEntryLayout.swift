import SwiftUI

/// PDF 書き出し(#95)の1ページ分のレイアウト。1日記を1ページとして描画する。
/// 幅はページ幅に固定し、高さは内容に合わせて可変にする(.fixedSize で ImageRenderer が実寸を計測できるようにする)。
struct SettingsExportEntryLayout: View {
    let entry: JournalEntry
    let paperColor: Color
    let pageWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headingText)
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 8)
            ForEach(entry.blocks) { block in
                SettingsExportBlockLayout(block: block)
            }
        }
        .padding(32)
        .frame(width: pageWidth, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(paperColor)
        .foregroundStyle(Color.ink)
    }

    private var headingText: String {
        let formatter = DateFormatter()
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return entry.title.isEmpty
            ? formatter.string(from: entry.date)
            : "\(formatter.string(from: entry.date)) \(entry.title)"
    }
}

struct SettingsExportEntryLayout_Previews: PreviewProvider {
    static var previews: some View {
        SettingsExportEntryLayout(entry: SampleData.sampleEntry, paperColor: .inkPaper, pageWidth: 560)
    }
}
