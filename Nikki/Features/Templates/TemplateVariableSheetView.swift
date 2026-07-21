import SwiftUI

/// 変数入力シート(1m)の 1 変数分の入力状態。
private struct TemplateVariableField: Identifiable {
    var id: String { name }
    /// 変数名({{date}} の date 部分)。
    let name: String
    /// {{date}} のように today から自動補完し編集不可か。
    let isAuto: Bool
    /// フィールドに表示・入力する値(auto は補完済みで固定)。
    var value: String
    /// 本文へ差し込む値。nil のときは value をそのまま使う。
    /// {{date}} はフィールドには曜日つきで見せつつ、本文見出しには曜日なしの日付を入れる(参照 1m)。
    var bodyValue: String?
    /// 未入力時のプレースホルダ。
    var placeholder: String

    /// 本文置換に使う実値。
    var substitution: String { bodyValue ?? value }

    /// template.variableNames と today から入力フィールド群を組み立てる。
    static func fields(for template: JournalTemplate, today: Date) -> [TemplateVariableField] {
        template.variableNames.map { name in
            guard name == "date" else {
                return TemplateVariableField(
                    name: name,
                    isAuto: false,
                    // 参照デザイン(1m)の記入済み状態を再現するためのデモ初期値。ユーザーは上書きできる。
                    value: demoValues[name] ?? "",
                    bodyValue: nil,
                    placeholder: placeholders[name] ?? "ここに入力"
                )
            }
            return TemplateVariableField(
                name: name,
                isAuto: true,
                value: dateText(today, includesWeekday: true),
                bodyValue: dateText(today, includesWeekday: false),
                placeholder: ""
            )
        }
    }

    private static let demoValues: [String: String] = ["weather": "晴れのち夕立", "place": "鎌倉"]
    private static let placeholders: [String: String] = [
        "weather": "きょうの天気",
        "place": "どこへ行った?",
        "mood": "きょうの気分",
    ]

    private static func dateText(_ date: Date, includesWeekday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = includesWeekday ? "y年M月d日 EEEE" : "y年M月d日"
        return formatter.string(from: date)
    }
}

/// テンプレート選択後の変数入力ボトムシート(1m)。単独画面として、背後のディム +
/// 下端のシートカードという構図を自前で再現する。各変数を埋めると本文プレビューがライブ更新される。
struct TemplateVariableSheetView: View {
    let template: JournalTemplate
    let today: Date
    /// 「この内容ではじめる」をタップしたときに呼ばれる。既定は no-op。
    var onStart: () -> Void

    // TemplateVariableField がファイル内 private 型のため、@State も private のままにする(@State を非 private にする規約から逸脱)。
    @State private var fields: [TemplateVariableField]
    @FocusState private var focusedFieldName: String?

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
            backdrop
            sheet
        }
        .ignoresSafeArea()
    }

    /// 背後の画面をディムした地。#DBDAD5 の上に半透明の紙色を重ね、ぼかした本文の見立てとして
    /// スケルトンバーを 1 本置く。
    private var backdrop: some View {
        ZStack(alignment: .topLeading) {
            InkColors.disabledBackground
            InkColors.paper.opacity(0.5)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0xDDDCD7))
                .frame(width: 170, height: 16)
                .padding(.top, 90)
                .padding(.leading, 24)
        }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0xD5D4CF))
                .frame(width: 38, height: 4.5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 18)

            Text("「\(template.name)」から作成")
                .font(InkTypography.font(17, .bold))
                .foregroundStyle(InkColors.ink)
                .padding(.bottom, 4)

            Text("埋めた言葉が、そのまま本文に入ります。")
                .font(InkTypography.font(12.5, .regular))
                .foregroundStyle(InkColors.textTertiary)
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                ForEach($fields) { $field in
                    variableFieldCard($field)
                }
            }

            markdownPreview
                .padding(.top, 18)

            InkPrimaryButton("この内容ではじめる", action: onStart)
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
            .fill(InkColors.paper)
            .shadow(color: InkColors.ink.opacity(0.18), radius: 20, x: 0, y: -12)
        )
    }

    private func variableFieldCard(_ field: Binding<TemplateVariableField>) -> some View {
        let name = field.wrappedValue.name
        let isFocused = focusedFieldName == name
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("{{\(name)}}")
                    .font(InkTypography.mono(11, weight: .semibold))
                    .foregroundStyle(InkColors.labelGray)
                if field.wrappedValue.isAuto {
                    Spacer(minLength: 8)
                    Text("自動")
                        .font(InkTypography.mono(10.5))
                        .foregroundStyle(InkColors.textTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(InkColors.surfaceInset)
                        )
                }
            }
            if field.wrappedValue.isAuto {
                Text(field.wrappedValue.value)
                    .font(InkTypography.font(14.5, .regular))
                    .foregroundStyle(InkColors.ink)
            } else {
                TextField(
                    "",
                    text: field.value,
                    prompt: Text(field.wrappedValue.placeholder).foregroundStyle(InkColors.textQuaternary)
                )
                .font(InkTypography.font(14.5, .regular))
                .foregroundStyle(InkColors.ink)
                .tint(InkColors.ink)
                .focused($focusedFieldName, equals: name)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(InkColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isFocused ? InkColors.ink : InkColors.border, lineWidth: isFocused ? 1.5 : 1)
        )
    }

    private var markdownPreview: some View {
        Text(generatedMarkdown)
            .font(InkTypography.mono(11.5))
            .foregroundStyle(InkColors.labelGray)
            .lineSpacing(InkTypography.lineSpacing(fontSize: 11.5, multiplier: 1.95))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(InkColors.surfaceInset)
            )
    }

    /// template.markdown の {{var}} を入力値で置換した本文。未入力の変数はトークンのまま残す。
    private var generatedMarkdown: String {
        fields.reduce(template.markdown) { result, field in
            field.substitution.isEmpty
                ? result
                : result.replacingOccurrences(of: "{{\(field.name)}}", with: field.substitution)
        }
    }
}

#Preview {
    TemplateVariableSheetView(template: SampleData.reflectionTemplate, today: SampleData.referenceToday)
}
