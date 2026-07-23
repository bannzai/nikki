import SwiftUI
import SwiftData

/// テンプレート一覧(1l)。「今日はどの紙に書きますか。」の見出しの下に、
/// 各テンプレをカード(タイトル + シェブロン + markdown プレビュー)で並べる。
/// カードを選ぶと変数入力シート(1m)を重ね、シートが日記を作成すると entry 経由でエディタへ進む。
struct TemplateListPage: View {
    @Query(sort: \JournalTemplate.sortOrder) var templates: [JournalTemplate]

    /// 変数入力シートを開いているテンプレート。nil のときはシートを閉じている。
    @State var template: JournalTemplate?
    /// 変数入力シートの入力状態。
    @State var fields: [TemplateVariableField] = []
    /// 変数入力シートが作成した日記。エディタへの遷移に使う。
    @State var entry: JournalEntry?
    /// シートを開いた時刻。{{date}} の補完値と作成する日記の date を一致させるために保持する。
    @State var sheetOpenedAt: Date = .now

    @Environment(\.dismiss) private var dismiss

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
                            TemplateCard(template: template) { open(template: template) }
                        }
                    }

                    TemplateNewFooter()
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.inkPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if template != nil {
                ZStack(alignment: .bottom) {
                    TemplateVariableBackdrop()
                        .onTapGesture { template = nil }
                    TemplateVariableSheet(template: $template, fields: $fields, entry: $entry, today: sheetOpenedAt)
                }
                .ignoresSafeArea()
            }
        }
        .navigationDestination(item: $entry) { entry in
            EditorPage(entry: entry)
        }
    }

    /// カードで選んだテンプレートの変数入力シートを開く。
    private func open(template: JournalTemplate) {
        sheetOpenedAt = .now
        fields = TemplateVariableField.fields(template: template, today: sheetOpenedAt, includesDemoValues: false)
        self.template = template
    }
}

struct TemplateListPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TemplateListPage()
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
