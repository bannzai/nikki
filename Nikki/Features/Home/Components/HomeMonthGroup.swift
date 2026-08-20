import Foundation

/// 時系列リストで同じ年月の日記をまとめた表示単位。
struct HomeMonthGroup: Identifiable {
    let year: Int
    let month: Int
    var entries: [JournalEntry]

    /// 年月の一意キー。ForEach の identity に使う。
    var id: Int { year * 100 + month }

    /// 「2026年7月」形式の月見出し。
    var title: String {
        // year と month は日記の日付から取り出した実在の年月のため date(from:) は失敗しない。フォールバックは型を満たすためだけに置く。
        let date = Calendar.display.date(from: DateComponents(year: year, month: month)) ?? .now
        return date.formatted(localizedPattern: "MMMM y")
    }

    /// 日記を新しい月・日が先頭に来るよう降順に並べ、年月ごとにまとめる。
    static func grouped(from entries: [JournalEntry]) -> [HomeMonthGroup] {
        var groups: [HomeMonthGroup] = []
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let comps = Calendar.display.dateComponents([.year, .month], from: entry.date)
            let year = comps.year ?? 0
            let month = comps.month ?? 0
            if var last = groups.last, last.year == year, last.month == month {
                last.entries.append(entry)
                groups[groups.count - 1] = last
            } else {
                groups.append(HomeMonthGroup(year: year, month: month, entries: [entry]))
            }
        }
        return groups
    }
}
