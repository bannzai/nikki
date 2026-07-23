import SwiftUI

/// 挿入予定位置を示す 2.5px の墨インジケータライン。
struct EditorInsertionIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.ink)
            .frame(height: 2.5)
            .padding(.horizontal, 6)
    }
}

struct EditorInsertionIndicator_Previews: PreviewProvider {
    static var previews: some View {
        EditorInsertionIndicator()
            .padding()
            .background(Color.inkPaper)
    }
}
