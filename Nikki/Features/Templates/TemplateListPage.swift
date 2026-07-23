import SwiftUI
import SwiftData

/// テンプレート一覧(1l)。「今日はどの紙に書きますか。」の見出しの下に、
/// 各テンプレをカード(タイトル + シェブロン + markdown プレビュー)で並べる。
/// カードを選ぶと変数入力シート(1m)を重ね、「この内容ではじめる」で日記を作成してエディタへ進む。
struct TemplateListPage: View {
    @Query(sort: \JournalTemplate.sortOrder) var templates: [JournalTemplate]

    /// 変数入力シートを開いているテンプレート。nil のときはシートを閉じている。
    @State var template: JournalTemplate?
    /// 変数入力シートの入力状態。
    @State var fields: [TemplateVariableField] = []
    /// 「この内容ではじめる」で作成した日記。エディタへの遷移に使う。
    @State var entry: JournalEntry?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title("テンプレート"), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("今日はどの紙に書きますか。")
                        .font(InkTypography.font(12.5, .regular))
                        .foregroundStyle(InkColors.textSecondary)
                        .lineSpacing(InkTypography.lineSpacing(fontSize: 12.5, multiplier: 1.9))
                        .padding(.bottom, 16)

                    VStack(spacing: 12) {
                        ForEach(templates) { template in
                            TemplateCard(template: template) { open(template) }
                        }
                    }

                    TemplateNewFooter()
                }
                .padding(.horizontal, 24)
            }
        }
        .background(InkColors.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if let template {
                ZStack(alignment: .bottom) {
                    TemplateVariableBackdrop()
                        .onTapGesture { self.template = nil }
                    TemplateVariableSheet(template: template, fields: $fields, onStart: { start(template) })
                }
                .ignoresSafeArea()
            }
        }
        .navigationDestination(item: $entry) { entry in
            EditorPage(entry: entry)
        }
    }

    /// カードで選んだテンプレートの変数入力シートを開く。
    private func open(_ template: JournalTemplate) {
        fields = TemplateVariableField.fields(for: template, today: .now, includesDemoValues: false)
        self.template = template
    }

    /// 変数を差し込んだ markdown から日記を作成・保存し、エディタへ進む。
    private func start(_ template: JournalTemplate) {
        let entry = JournalEntry(
            templateMarkdown: TemplateVariableField.substitutedMarkdown(template: template, fields: fields),
            date: .now
        )
        modelContext.insert(entry)
        try? modelContext.save()
        self.template = nil
        self.entry = entry
    }
}

#Preview {
    NavigationStack {
        TemplateListPage()
    }
    .modelContainer(SampleData.inMemoryContainer())
}
