import SwiftUI

/// ノートの作成・編集フォームの入力欄(名前 + 書き出しのテンプレート markdown)。
/// 作成(まだノートが無い)と編集(ノートへ書き戻す)の両方から使うため、値は Binding で受け取る。
struct NotebookFormFields: View {
    @Binding var name: String
    @Binding var markdown: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("名前")
                    .font(.ink(12, .medium))
                    .foregroundStyle(Color.inkTextTertiary)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 8)

                TextField(
                    "ノートの名前",
                    text: $name,
                    prompt: Text("ノートの名前")
                        .font(.ink(14.5, .regular))
                        .foregroundStyle(Color.inkTextTertiary)
                )
                .font(.ink(14.5, .regular))
                .foregroundStyle(Color.ink)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.inkSurfaceInset)
                )
                .padding(.bottom, 24)

                Text("書き出し")
                    .font(.ink(12, .medium))
                    .foregroundStyle(Color.inkTextTertiary)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 8)

                TextEditor(text: $markdown)
                    .font(.inkMono(12.5))
                    .lineSpacing(inkLineSpacing(fontSize: 12.5, multiplier: 1.9))
                    .foregroundStyle(Color.ink)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    // 書き出しの数行 + 追記の余地が一目で見える高さ。
                    .frame(minHeight: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.inkSurfaceInset)
                    )
                    .padding(.bottom, 8)

                Text("このノートの新しい日記は、この内容から書きはじめます。{{date}} は日記の日付に置き換わります。")
                    .font(.ink(11.5, .regular))
                    .foregroundStyle(Color.inkTextTertiary)
                    .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }
}

struct NotebookFormFields_Previews: PreviewProvider {
    static var previews: some View {
        NotebookFormFields(name: .constant("朝の3行"), markdown: .constant("# {{date}} の朝\n- 今日たのしみなこと"))
            .background(Color.inkPaper)
    }
}
