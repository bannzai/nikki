import SwiftUI

/// チェックボックスの ToggleStyle。完了は墨地+白チェック、未完了は角丸枠で、ラベルをチェックの右に並べる。
struct EditorCheckboxToggleStyle: ToggleStyle {
    // 見本(1j)のチェックボックス寸法と、ボックスとラベルの間隔。
    var boxSize: CGFloat = 19
    var boxSpacing: CGFloat = 11

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: boxSpacing) {
                if configuration.isOn {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.ink)
                        .frame(width: boxSize, height: boxSize)
                        .overlay {
                            Image(systemName: InkIcons.checkmark)
                                .font(.system(size: boxSize * 0.5, weight: .bold))
                                .foregroundStyle(Color.inkPrimaryButtonText)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.ink.opacity(0.35), lineWidth: 1.5)
                        .frame(width: boxSize, height: boxSize)
                }
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

struct EditorCheckboxToggleStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: .constant(true)) { Text(verbatim: "麦茶のパック") }
            Toggle(isOn: .constant(false)) { Text(verbatim: "蚊取り線香") }
        }
        .toggleStyle(EditorCheckboxToggleStyle())
        .padding()
        .background(Color.inkPaper)
    }
}
