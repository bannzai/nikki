import SwiftUI

/// ノート一覧(1l)の 1 枚分のカード。
struct NotebookCard: View {
    let notebook: JournalNotebook
    let onTap: () -> Void

    var body: some View {
        // VoiceOver や AX 自動操作からもカードを押せるよう、onTapGesture ではなく Button にする。
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(notebook.name)
                        .font(.inkListItemTitle)
                        .foregroundStyle(Color.ink)
                    Spacer(minLength: 8)
                    Text(reminderText(frequency: notebook.reminderFrequency))
                        .font(.ink(11, .regular))
                        .foregroundStyle(Color.inkTextQuaternary)
                    Image(systemName: InkIcons.chevronRight)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkTextTertiary)
                }
                Text(notebook.template?.markdown ?? "")
                    .font(.inkMono(11.5))
                    .foregroundStyle(Color.inkTextTertiary)
                    .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .inkCard(cornerRadius: 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// リマインドの頻度の表示名。
    private func reminderText(frequency: JournalReminderFrequency) -> String {
        switch frequency {
        case .none: return ""
        case .daily: return String(localized: "Daily")
        case .weekly: return String(localized: "Weekly")
        }
    }
}

struct NotebookCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ForEach(SampleData.notebooks) { notebook in
                NotebookCard(notebook: notebook, onTap: {})
            }
        }
        .padding()
        .background(Color.inkPaper)
    }
}
