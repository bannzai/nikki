import SwiftUI

/// 「Face ID で開く」墨 pill ボタン。高さ50・横パディング26・角丸25。
struct LockFaceIDButton: View {
    var body: some View {
        // 自動ロック・Face ID 解除は未実装のため、ボタンはまだ何もしない(https://github.com/bannzai/nikki/issues/14)。
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: InkIcons.faceID)
                    .font(.system(size: 18, weight: .regular))
                Text("Face ID で開く")
                    .font(.ink(15, .medium).weight(.semibold))
            }
        }
        .buttonStyle(LockFaceIDButtonStyle())
    }
}

/// 「Face ID で開く」ボタンの ButtonStyle。
private struct LockFaceIDButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.inkPrimaryButtonText)
            .frame(height: 50)
            .padding(.horizontal, 26)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color.ink)
            )
    }
}

struct LockFaceIDButton_Previews: PreviewProvider {
    static var previews: some View {
        LockFaceIDButton()
            .padding()
            .background(Color.inkPaper)
    }
}
