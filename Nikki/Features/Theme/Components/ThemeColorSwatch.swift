import SwiftUI

/// 紙色プリセット1つを表す丸スウォッチ + ラベル。選択中は墨枠とチェックを表示する。
/// locked のスウォッチは錠前を重ね、タップで選択せずペイウォールを開く。
struct ThemeColorSwatch: View {
    /// 自分が表す紙色プリセットの添字(Color.paperColorPreset と同順)。
    let index: Int
    let label: String
    /// 選択中プリセットの添字。タップで自分の index に更新して選択を切り替える。
    @Binding var selectedIndex: Int
    /// Nikki Plus 未加入でこのプリセットを選べないかどうか。
    let locked: Bool
    /// locked のスウォッチをタップした時に開くペイウォールの表示状態。
    @Binding var paywallSheetIsPresented: Bool

    var body: some View {
        Button {
            if locked {
                paywallSheetIsPresented = true
            } else {
                selectedIndex = index
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.paperColorPreset[index])
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: InkIcons.checkmark)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.ink)
                        } else if locked {
                            Image(systemName: InkIcons.lock)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.inkTextSecondary)
                        }
                    }
                Text(label)
                    .font(.ink(11, isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.ink : Color.inkTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    /// 自分の紙色が選択中かどうか。
    private var isSelected: Bool {
        index == selectedIndex
    }

    /// 非選択時の枠色。白(プリセット先頭)は紙地に対して輪郭が沈むため、他色より濃い枠にする。
    private var borderColor: Color {
        if isSelected {
            return Color.ink
        }
        return index == 0 ? Color.black.opacity(0.12) : Color.inkBorder
    }
}

struct ThemeColorSwatch_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 14) {
            ThemeColorSwatch(index: 0, label: "White", selectedIndex: .constant(1), locked: false, paywallSheetIsPresented: .constant(false))
            ThemeColorSwatch(index: 1, label: "Cream", selectedIndex: .constant(1), locked: false, paywallSheetIsPresented: .constant(false))
            ThemeColorSwatch(index: 2, label: "Ash", selectedIndex: .constant(1), locked: true, paywallSheetIsPresented: .constant(false))
        }
        .padding()
        .background(Color.inkPaper)
    }
}
