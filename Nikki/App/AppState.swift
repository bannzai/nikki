import SwiftUI
import Observation

enum HomeViewMode: Int, CaseIterable {
    case list
    case calendar

    var label: String {
        switch self {
        case .list: return "リスト"
        case .calendar: return "カレンダー"
        }
    }
}

@Observable
final class AppState {
    var isLocked: Bool = false
    var homeView: HomeViewMode = .list
    var paperColor: PaperColorPreset = .ecru
    var onboardingCompleted: Bool = false
}
