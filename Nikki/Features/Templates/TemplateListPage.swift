import SwiftUI
import SwiftData

/// テンプレート一覧(1l)。「今日はどの紙に書きますか。」の見出しの下に、
/// 各テンプレをカード(タイトル + シェブロン + markdown プレビュー)で並べる。
/// カードを選ぶとその内容({{date}} は日記の日付で補完)で entry を置き換えて保存し、
/// 次回の新規作成で自動挿入する既定のテンプレートとして記憶してエディタへ戻る。
/// entry に入力があるときは、置き換えで入力内容が消えることをアラートで確認してから置き換える。
struct TemplateListPage: View {
    /// テンプレートを挿入する対象の日記。遷移元のエディタが表示中の日記を渡す。
    let entry: JournalEntry

    @Query(sort: \JournalTemplate.sortOrder) var templates: [JournalTemplate]

    /// 置き換え確認アラートの対象テンプレート。nil のときはアラートを閉じている。
    @State var template: JournalTemplate?
    @State var replaceAlertIsPresented = false

    /// 既定のテンプレートの id(UUID 文字列)。空のときは未設定。選んだテンプレートを次回の自動挿入用に記憶する。
    @AppStorage(.defaultTemplateID) var defaultTemplateID: String = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            InkNavBar(leading: .back, center: .title("テンプレート"), onLeading: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("今日はどの紙に書きますか。")
                        .font(.ink(12.5, .regular))
                        .foregroundStyle(Color.inkTextSecondary)
                        .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
                        .padding(.bottom, 16)

                    VStack(spacing: 12) {
                        ForEach(templates) { template in
                            TemplateCard(template: template) { select(template: template) }
                        }
                    }

                    TemplateNewFooter()
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.inkPaper.ignoresSafeArea())
        .inkNavigationBarHidden()
        .alert("入力内容の置き換え", isPresented: $replaceAlertIsPresented, presenting: template) { template in
            Button("置き換える", role: .destructive) { apply(template: template) }
            Button("キャンセル", role: .cancel) {}
        } message: { template in
            Text("「\(template.name)」を挿入すると、いま入力されている内容は消えます。")
        }
    }

    /// カードで選んだテンプレートを適用する。entry に入力があるときは、消えることを確認してから適用する。
    private func select(template: JournalTemplate) {
        if entry.title.isEmpty && entry.bodyMarkdown.isEmpty {
            apply(template: template)
        } else {
            self.template = template
            replaceAlertIsPresented = true
        }
    }

    /// テンプレートの内容で entry を置き換えて保存し、既定のテンプレートとして記憶してエディタへ戻る。
    private func apply(template: JournalTemplate) {
        entry.replace(templateMarkdown: TemplateVariableField.substitutedMarkdown(
            template: template,
            fields: TemplateVariableField.fields(template: template, today: entry.date, includesDemoValues: false)
        ))
        // エディタへ戻った直後にアプリが kill されても置き換えが残るよう明示保存する。
        try? modelContext.save()
        defaultTemplateID = template.id.uuidString
        dismiss()
    }
}

struct TemplateListPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TemplateListPage(entry: SampleData.sampleEntry)
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
