import Foundation

struct ChecklistItem: Identifiable, Hashable {
    var id: UUID = UUID()
    var text: String
    var done: Bool
}

/// 日記本文を構成するブロック。マークダウン互換の見出し / 段落 / チェックリストと、
/// サポートする HTML タグ(img / details)を表現する。
enum Block: Identifiable, Hashable {
    case heading(id: UUID = UUID(), level: Int, text: String)
    case paragraph(id: UUID = UUID(), text: String)
    case checklist(id: UUID = UUID(), items: [ChecklistItem])
    case image(id: UUID = UUID(), label: String)
    case details(id: UUID = UUID(), summary: String, isCollapsed: Bool)

    var id: UUID {
        switch self {
        case .heading(let id, _, _): return id
        case .paragraph(let id, _): return id
        case .checklist(let id, _): return id
        case .image(let id, _): return id
        case .details(let id, _, _): return id
        }
    }
}
