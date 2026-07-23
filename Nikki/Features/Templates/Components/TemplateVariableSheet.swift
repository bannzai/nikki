import SwiftUI
import SwiftData

/// 変数入力のシートカード本体。ドラッグハンドル・見出し・変数フィールド群・
/// markdown プレビュー・開始ボタンを上端角丸24のカードに載せる。
/// 「この内容ではじめる」で日記の作成・保存まで画面内で行い、template を nil に戻して自分でシートを閉じる。
struct TemplateVariableSheet: View {
    /// 表示中のテンプレート。作成完了時に nil へ戻してシートを閉じるため Binding で受け取る。
    @Binding var template: JournalTemplate?
    @Binding var fields: [TemplateVariableField]
    /// 「この内容ではじめる」で作成した日記。親はこれを navigationDestination(item:) でのエディタ遷移に使う。
    @Binding var entry: JournalEntry?
    /// シートを開いた時点の「今日」。{{date}} の補完値と作成する日記の date を一致させるために受け取る。
    let today: Date

    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedFieldName: String?

    var body: some View {
        if let template {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(hex: 0xD5D4CF))
                    .frame(width: 38, height: 4.5)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 18)

                Text("「\(template.name)」から作成")
                    .font(.ink(17, .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.bottom, 4)

                Text("埋めた言葉が、そのまま本文に入ります。")
                    .font(.ink(12.5, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ForEach($fields) { $field in
                        TemplateVariableFieldCard(field: $field, focusedFieldName: $focusedFieldName)
                    }
                }

                TemplateMarkdownPreview(markdown: TemplateVariableField.substitutedMarkdown(template: template, fields: fields))
                    .padding(.top, 18)

                Button("この内容ではじめる") {
                    start(template: template)
                }
                .buttonStyle(InkPrimaryButtonStyle())
                .padding(.top, 18)
            }
            .padding(.top, 14)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24,
                    style: .continuous
                )
                .fill(Color.inkPaper)
                .shadow(color: Color.ink.opacity(0.18), radius: 20, x: 0, y: -12)
            )
        }
    }

    /// 変数を差し込んだ markdown から日記を作成・保存し、シートを閉じて親のエディタ遷移を起こす。
    private func start(template: JournalTemplate) {
        let entry = JournalEntry(
            templateMarkdown: TemplateVariableField.substitutedMarkdown(template: template, fields: fields),
            date: today
        )
        modelContext.insert(entry)
        try? modelContext.save()
        self.template = nil
        self.entry = entry
    }
}

struct TemplateVariableSheet_Previews: PreviewProvider {
    static var previews: some View {
        TemplateVariableSheet(
            template: .constant(SampleData.reflectionTemplate),
            fields: .constant(TemplateVariableField.fields(
                template: SampleData.reflectionTemplate,
                today: SampleData.referenceToday,
                includesDemoValues: true
            )),
            entry: .constant(nil),
            today: SampleData.referenceToday
        )
        .modelContainer(SampleData.inMemoryContainer())
    }
}
