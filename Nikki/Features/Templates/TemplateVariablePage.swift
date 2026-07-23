import SwiftUI

/// テンプレート選択後の変数入力ボトムシート(1m)。単独画面として、背後のディム +
/// 下端のシートカードという構図を自前で再現する。各変数を埋めると本文プレビューがライブ更新される。
struct TemplateVariablePage: View {
    /// シートに表示するテンプレート。カタログの単独表示では閉じ操作で nil になっても遷移先はない。
    @State var template: JournalTemplate?
    /// 変数入力シートの入力状態。初期値は呼び出し側が TemplateVariableField.fields(for:today:includesDemoValues:) で組み立てる。
    @State var fields: [TemplateVariableField]
    /// シートが作成した日記。カタログの単独表示では遷移先がないため使われない。
    @State var entry: JournalEntry? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            TemplateVariableBackdrop()
            TemplateVariableSheet(template: $template, fields: $fields, entry: $entry)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    let template = SampleData.reflectionTemplate
    TemplateVariablePage(
        template: template,
        fields: TemplateVariableField.fields(for: template, today: SampleData.referenceToday, includesDemoValues: true)
    )
    .modelContainer(SampleData.inMemoryContainer())
}
