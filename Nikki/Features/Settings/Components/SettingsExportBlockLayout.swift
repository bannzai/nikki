import SwiftUI

/// PDF 書き出し(#95)の本文1ブロック分のレイアウト。エディタの表示ロジックとは独立させ、
/// 印刷物として読みやすい最小限の装飾(見出しの太さ・チェックリストの記号)だけを持たせる。
struct SettingsExportBlockLayout: View {
    let block: Block

    var body: some View {
        switch block {
        case .heading(_, let level, let text):
            Text(text)
                .font(.system(size: level == 1 ? 18 : 15, weight: .bold))
        case .paragraph(_, let text):
            Text(text)
                .font(.system(size: 13))
        case .checklist(_, let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text(item.done ? "☑" : "☐")
                        Text(item.text)
                            .strikethrough(item.done)
                    }
                    .font(.system(size: 13))
                }
            }
        // img / details は編集時の元 markdown をそのまま書き出し、内容を失わないことを優先する(装飾は最小限)。
        case .image(_, let label, _):
            Text("🖼 \(label)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
        case .details(_, let summary, _, _):
            Text("▸ \(summary)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }
}
