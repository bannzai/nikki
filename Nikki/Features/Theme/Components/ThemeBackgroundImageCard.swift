import SwiftUI
import PhotosUI

/// 背景画像の選択リスト(#96)。「写真から選ぶ」と、現在選択中の状態(なし/選択済み)を表示する。
/// Plus 限定機能。未加入時は選択導線をロックし、タップで PaywallPage を開く。
struct ThemeBackgroundImageCard: View {
    let plusActive: Bool
    @Binding var paywallSheetIsPresented: Bool

    // ファイルの実在確認から初期値を導く必要があるため、既定値付きのカスタムプロパティにしている。
    @State var hasStoredImage = ThemeBackgroundImage.load() != nil
    @State var photosPickerItem: PhotosPickerItem? = nil

    var body: some View {
        InkListSection {
            if plusActive {
                // PhotosPicker の label クロージャは PhotosUI 側の関数型に MainActor 注釈が無く、
                // プロジェクト側の(デフォルト MainActor 分離の)独自型の初期化を中で呼べないため、
                // InkListRowSurface を使わず SwiftUI 標準の View だけで同じ見た目を組み立てる。
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    HStack(spacing: 8) {
                        Text(String(localized: "Choose from Photos"))
                            .font(.system(size: 14.5, weight: .regular))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.inkSeparator)
                    .frame(height: 0.5)
                    .padding(.leading, 16)

                InkListRow(
                    title: String(localized: "None"),
                    showsChevron: false,
                    showsSeparator: false,
                    trailing: hasStoredImage ? nil : AnyView(
                        Image(systemName: InkIcons.checkmark)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.ink)
                    ),
                    // 既に「なし」が選択中(画像未保存)のときは押しても変わらないため、タップ不要にする。
                    action: hasStoredImage ? { removeImage() } : nil
                )
            } else {
                InkListRow(
                    title: String(localized: "Choose from Photos"),
                    showsChevron: false,
                    showsSeparator: false,
                    trailing: AnyView(
                        Image(systemName: InkIcons.lock)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.inkTextSecondary)
                    ),
                    action: { paywallSheetIsPresented = true }
                )
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    try? ThemeBackgroundImage.save(data: data)
                    hasStoredImage = true
                }
            }
        }
    }

    /// 背景画像を削除して「なし」に戻す。
    private func removeImage() {
        try? ThemeBackgroundImage.remove()
        hasStoredImage = false
    }
}

struct ThemeBackgroundImageCard_Previews: PreviewProvider {
    static var previews: some View {
        ThemeBackgroundImageCard(plusActive: true, paywallSheetIsPresented: .constant(false))
            .padding()
            .background(Color.inkPaper)
    }
}
