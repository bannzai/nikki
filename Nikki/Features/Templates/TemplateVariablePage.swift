import SwiftUI

/// テンプレート選択後の変数入力ボトムシート(1m)。単独画面として、背後のディム +
/// 下端のシートカードという構図を自前で再現する。各変数を埋めると本文プレビューがライブ更新される。
struct TemplateVariablePage: View {
    let today: Date

    /// シートに表示するテンプレート。カタログの単独表示では閉じ操作で nil になっても遷移先はない。
    @State var template: JournalTemplate?
    @State var fields: [TemplateVariableField]
    /// シートが作成した日記。カタログの単独表示では遷移先がないため使われない。
    @State var entry: JournalEntry?

    // @State fields / template の初期値を引数の template / today から組み立てるため custom init を用いる。
    init(template: JournalTemplate, today: Date) {
        self.today = today
        self._template = State(initialValue: template)
        // カタログ(1m)の記入済み状態を再現するため、デモ初期値を含めてフィールドを組み立てる。
        self._fields = State(initialValue: TemplateVariableField.fields(for: template, today: today, includesDemoValues: true))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TemplateVariableBackdrop()
            TemplateVariableSheet(template: $template, fields: $fields, entry: $entry)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    TemplateVariablePage(template: SampleData.reflectionTemplate, today: SampleData.referenceToday)
        .modelContainer(SampleData.inMemoryContainer())
}
