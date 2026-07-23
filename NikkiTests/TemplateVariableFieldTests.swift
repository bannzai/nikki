import Foundation
import Testing
@testable import Nikki

struct TemplateVariableFieldTests {
    @Test("{{変数}} を入力値で置換する")
    func substitutesTokens() {
        let template = JournalTemplate(name: "一日の振り返り", markdown: "# {{date}}\n天気: {{weather}}", sortOrder: 0)
        let fields = [
            TemplateVariableField(name: "date", isAuto: true, value: "2026年7月23日 木曜日", bodyValue: "2026年7月23日", placeholder: ""),
            TemplateVariableField(name: "weather", isAuto: false, value: "晴れ", bodyValue: nil, placeholder: ""),
        ]
        #expect(
            TemplateVariableField.substitutedMarkdown(template: template, fields: fields)
                == "# 2026年7月23日\n天気: 晴れ"
        )
    }

    @Test("空白入りの {{ 変数 }} トークンも置換する")
    func substitutesSpacedTokens() {
        let template = JournalTemplate(name: "白紙", markdown: "# {{ date }}", sortOrder: 0)
        let fields = [
            TemplateVariableField(name: "date", isAuto: true, value: "2026年7月23日 木曜日", bodyValue: "2026年7月23日", placeholder: ""),
        ]
        #expect(
            TemplateVariableField.substitutedMarkdown(template: template, fields: fields)
                == "# 2026年7月23日"
        )
    }

    @Test("未入力の変数はトークンのまま残す")
    func keepsUnfilledTokens() {
        let template = JournalTemplate(name: "一日の振り返り", markdown: "天気: {{weather}}", sortOrder: 0)
        let fields = [
            TemplateVariableField(name: "weather", isAuto: false, value: "", bodyValue: nil, placeholder: "きょうの天気"),
        ]
        #expect(
            TemplateVariableField.substitutedMarkdown(template: template, fields: fields)
                == "天気: {{weather}}"
        )
    }

    @Test("正規表現の特殊文字を含む入力値もそのまま差し込む")
    func substitutesValuesContainingRegexTemplateCharacters() {
        let template = JournalTemplate(name: "白紙", markdown: "# {{place}}", sortOrder: 0)
        let fields = [
            TemplateVariableField(name: "place", isAuto: false, value: "鎌倉 $0\\海岸", bodyValue: nil, placeholder: ""),
        ]
        #expect(
            TemplateVariableField.substitutedMarkdown(template: template, fields: fields)
                == "# 鎌倉 $0\\海岸"
        )
    }
}
