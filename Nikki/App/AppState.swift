import SwiftUI
import Observation

enum HomePageMode: Int, CaseIterable {
    case list
    case calendar
}

// アプリ全体で共有し、複数画面から参照・更新するルート状態のため @Observable を用いる。
@Observable
final class AppState {
    var isLocked: Bool = false
    var homeView: HomePageMode = .list
    var paperColor: PaperColorPreset = .ecru
    var onboardingCompleted: Bool = false
}
