import SwiftUI

/// テンプレートの作成・編集フォームの入力欄(名前 + 書き出しの markdown)。
/// 作成(まだテンプレートが無い)と編集(テンプレートへ書き戻す)の両方から使うため、値は Binding で受け取る。
struct NotebookFormFields: View {
    @Binding var name: String
    @Binding var markdown: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Name")
                    .font(.ink(12, .medium))
                    .foregroundStyle(Color.inkTextTertiary)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 8)

                TextField(
                    "Template name",
                    text: $name,
                    prompt: Text("Template name")
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

                Text("Content")
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

                Text("New entries using this template start with this content. {{date}} is replaced with the entry's date.")
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
