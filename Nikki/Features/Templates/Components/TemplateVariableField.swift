import Foundation

/// 変数入力シート(1m)の 1 変数分の入力状態。
struct TemplateVariableField: Identifiable {
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
    /// includesDemoValues は参照デザイン(1m)の記入済み状態を再現するカタログ表示でのみ true にする。
    static func fields(for template: JournalTemplate, today: Date, includesDemoValues: Bool) -> [TemplateVariableField] {
        template.variableNames.map { name in
            guard name == "date" else {
                return TemplateVariableField(
                    name: name,
                    isAuto: false,
                    value: includesDemoValues ? (demoValues[name] ?? "") : "",
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

    /// 入力済みフィールドで template.markdown の {{変数}} を置換した本文。未入力の変数はトークンのまま残す。
    static func substitutedMarkdown(template: JournalTemplate, fields: [TemplateVariableField]) -> String {
        fields.reduce(template.markdown) { result, field in
            field.substitution.isEmpty
                ? result
                : result.replacingOccurrences(of: "{{\(field.name)}}", with: field.substitution)
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
