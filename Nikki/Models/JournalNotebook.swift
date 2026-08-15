import Foundation
import SwiftData

/// ノートに書くことを思い出させる頻度。
enum JournalReminderFrequency: String, CaseIterable {
    // リマインドしない
    case none
    // 毎日
    case daily
    // 毎週
    case weekly
}

/// 日記をまとめる単位のノート(例: 寝る前のノート・週のふりかえり・仕事のノート・育児ノート)。
/// 日記はいずれかのノートに属し、ノートごとに書き出しのテンプレートとリマインドの頻度を持つ。
/// テンプレートは原則1件だが、あとから複数の紙を使い分けられるよう 1:N で持つ。
/// CloudKit 同期の制約(unique 制約不可・全プロパティに既定値または Optional が必要・
/// リレーションは全て Optional かつ inverse が必要・Deny の削除ルールは不可)に合わせる。
/// ref: https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit
@Model
final class JournalNotebook {
    private(set) var id: UUID = UUID()
    private(set) var name: String = ""
    /// JournalReminderFrequency の rawValue。
    /// SwiftData の enum プロパティは CloudKit 同期で値がずれる報告があるため、String の実値で保存する。
    private(set) var reminderFrequencyRawValue: String = JournalReminderFrequency.none.rawValue
    /// 一覧の表示順。CloudKit 同期はレコードの取得順を保証しないため明示的に持つ。
    private(set) var sortOrder: Int = 0

    /// このノートで日記を書き出すときに使うテンプレート。ノートを消したら一緒に消す。
    @Relationship(deleteRule: .cascade, inverse: \JournalTemplate.notebook)
    private(set) var templates: [JournalTemplate]? = []

    /// このノートに書かれた日記。ノートを消しても日記そのものは残す。
    @Relationship(deleteRule: .nullify, inverse: \JournalEntry.notebook)
    private(set) var entries: [JournalEntry]? = []

    // templates はコンテキストへ挿入したあとに add(template:) で紐付けるため、引数から受け取らない。
    init(name: String, reminderFrequency: JournalReminderFrequency, sortOrder: Int) {
        self.name = name
        self.reminderFrequencyRawValue = reminderFrequency.rawValue
        self.sortOrder = sortOrder
    }

    /// reminderFrequencyRawValue を型として読む。
    /// 知らない値(新しいバージョンが書いた頻度が同期されてきた場合)はリマインドなしとして扱う。
    var reminderFrequency: JournalReminderFrequency {
        JournalReminderFrequency(rawValue: reminderFrequencyRawValue) ?? .none
    }

    /// 日記を書き出すときに使うテンプレート。原則1件だが 1:N で持つため、表示順が先頭のものを使う。
    var template: JournalTemplate? {
        templates?.min { $0.sortOrder < $1.sortOrder }
    }

    /// テンプレートをこのノートに紐付ける。すでに紐付いているテンプレートは追加しない(冪等)。
    func add(template: JournalTemplate) {
        if templates?.contains(where: { $0.id == template.id }) == true {
            return
        }
        templates = (templates ?? []) + [template]
    }
}

// MARK: - 挿入

extension ModelContext {
    /// ノートと、そのノートが持つテンプレートを挿入する。
    /// 挿入がリレーション先へ伝播することに頼らず、テンプレートも明示的に挿入する。
    func insert(notebooks: [JournalNotebook]) {
        for notebook in notebooks {
            insert(notebook)
            for template in notebook.templates ?? [] {
                insert(template)
            }
        }
    }
}
