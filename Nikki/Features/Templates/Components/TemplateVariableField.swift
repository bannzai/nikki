import Foundation

/// 変数入力シート(1m)の 1 変数分の入力状態。
/// Equatable は入力変化の検知(onChange)に使う(実装はコンパイラの自動合成)。
struct TemplateVariableField: Identifiable, Equatable {
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
    static func fields(template: JournalTemplate, today: Date, includesDemoValues: Bool) -> [TemplateVariableField] {
        template.variableNames.map { name in
            guard name == "date" else {
                return TemplateVariableField(
                    name: name,
                    isAuto: false,
                    value: includesDemoValues ? (demoValues[name] ?? "") : "",
                    bodyValue: nil,
                    placeholder: placeholders[name] ?? String(localized: "Type here")
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
    /// variableNames が受け付ける {{ weather }} のような空白入りトークンも置換できるよう、正規表現で照合する。
    static func substitutedMarkdown(template: JournalTemplate, fields: [TemplateVariableField]) -> String {
        fields.reduce(template.markdown) { result, field in
            field.substitution.isEmpty
                ? result
                : result.replacingOccurrences(
                    of: "\\{\\{\\s*\(field.name)\\s*\\}\\}",
                    with: NSRegularExpression.escapedTemplate(for: field.substitution),
                    options: .regularExpression
                )
        }
    }

    private static let demoValues: [String: String] = [
        "weather": String(localized: "Sunny, then a shower"),
        "place": String(localized: "Kamakura"),
    ]
    private static let placeholders: [String: String] = [
        "weather": String(localized: "Today's weather"),
        "place": String(localized: "Where did you go?"),
        "mood": String(localized: "Today's mood"),
    ]

    /// {{date}} の補完値。本文に保存される文字列のため、表記は端末の言語に追従させる。
    private static func dateText(_ date: Date, includesWeekday: Bool) -> String {
        includesWeekday
            ? date.formatted(localizedPattern: "EEEE, MMMM d, y")
            : date.formatted(localizedPattern: "MMMM d, y")
    }
}
