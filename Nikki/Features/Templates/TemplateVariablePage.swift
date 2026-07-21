import SwiftUI

/// テンプレート選択後の変数入力ボトムシート(1m)。単独画面として、背後のディム +
/// 下端のシートカードという構図を自前で再現する。各変数を埋めると本文プレビューがライブ更新される。
struct TemplateVariablePage: View {
    let template: JournalTemplate
    let today: Date
    /// 「この内容ではじめる」をタップしたときに呼ばれる。既定は no-op。
    var onStart: () -> Void

    @State var fields: [TemplateVariableField]

    // @State fields の初期値を template / today から組み立てるため custom init を用いる。
    init(
        template: JournalTemplate = SampleData.reflectionTemplate,
        today: Date = SampleData.referenceToday,
        onStart: @escaping () -> Void = {}
    ) {
        self.template = template
        self.today = today
        self.onStart = onStart
        _fields = State(initialValue: TemplateVariableField.fields(for: template, today: today))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TemplateVariableBackdrop()
            TemplateVariableSheet(template: template, fields: $fields, onStart: onStart)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    TemplateVariablePage(template: SampleData.reflectionTemplate, today: SampleData.referenceToday)
}
