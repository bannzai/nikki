import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 設定画面(1r)。iOS 標準のグループ化リスト形式で各設定項目を表示し、
/// 各行の選択・切り替えを AppStorage の typed key へ永続化する。
struct SettingsPage: View {
    @AppStorage(.faceIDUnlockEnabled) var faceIDUnlockEnabled: Bool = true
    /// パスキーの登録状態。登録フロー自体は未実装のため、現状は常に未登録のまま表示だけ実値に追従する。
    @AppStorage(.passkeyRegistered) var passkeyRegistered: Bool = false
    // README の「5秒タイプがなかったらロック」に合わせた既定値。
    @AppStorage(.autoLockSeconds) var autoLockSeconds: Int = 5
    /// 既定のテンプレートの id(UUID 文字列)。空のときは未設定。
    @AppStorage(.defaultTemplateID) var defaultTemplateID: String = ""
    @AppStorage(.textSize) var textSize: TextSize = .standard
    // 見本(1n)の初期選択が「生成」(プリセット2番目)のため。
    @AppStorage(.paperColorPresetIndex) var paperColorPresetIndex: Int = 1

    @State var defaultTemplateConfirmationDialogIsPresented = false
    @State var autoLockConfirmationDialogIsPresented = false
    @State var textSizeConfirmationDialogIsPresented = false
    @State var themeIsPresented = false
    @State var paywallSheetIsPresented = false
    @State var markdownExporterIsPresented = false

    @Query(sort: \JournalTemplate.sortOrder) var templates: [JournalTemplate]
    /// Markdown 書き出しは読んだときに時系列で並ぶよう古い順に取り出す。
    @Query(sort: \JournalEntry.date) var entries: [JournalEntry]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.plusActive) private var plusActive

    var body: some View {
        ZStack(alignment: .top) {
            Color.inkPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("設定"), onLeading: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsSectionLabel(text: "書くこと")
                        InkListSection {
                            InkListRow(
                                title: "既定のテンプレート",
                                value: templates.first { $0.id.uuidString == defaultTemplateID }?.name ?? "未設定",
                                action: { defaultTemplateConfirmationDialogIsPresented = true }
                            )
                            InkListRow(
                                title: "自動ロック",
                                value: "\(autoLockSeconds)秒",
                                showsSeparator: false,
                                action: { autoLockConfirmationDialogIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "鍵")
                        InkListSection {
                            InkListRow(title: "Face ID で解除", trailing: AnyView(SettingsToggle(isOn: $faceIDUnlockEnabled)))
                            // パスキーの登録フローが未実装で遷移先がないため、シェブロンは出さない。
                            InkListRow(
                                title: "パスキー",
                                value: passkeyRegistered ? "登録済み" : "未登録",
                                showsChevron: false,
                                showsSeparator: false
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "外観")
                        InkListSection {
                            InkListRow(
                                title: "テーマ",
                                value: paperColorPresetLabel(index: paperColorPresetIndex),
                                action: { themeIsPresented = true }
                            )
                            InkListRow(
                                title: "文字の大きさ",
                                value: textSizeLabel(textSize),
                                showsSeparator: false,
                                action: { textSizeConfirmationDialogIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "データ")
                        InkListSection {
                            InkListRow(
                                title: "Markdown で書き出す",
                                action: { markdownExporterIsPresented = true }
                            )
                            InkListRow(
                                title: "Nikki Plus",
                                value: plusActive ? "加入中" : "未加入",
                                showsSeparator: false,
                                action: { paywallSheetIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        Text("Nikki 1.0.0 — あなたの日記は、この端末の中に。")
                            .font(.ink(11, .regular))
                            .foregroundStyle(Color.inkTextQuaternary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $themeIsPresented) {
            ThemePage()
        }
        .sheet(isPresented: $paywallSheetIsPresented) {
            PaywallPage()
        }
        .confirmationDialog("既定のテンプレート", isPresented: $defaultTemplateConfirmationDialogIsPresented, titleVisibility: .visible) {
            ForEach(templates) { template in
                Button(template.name) {
                    defaultTemplateID = template.id.uuidString
                }
            }
        }
        .confirmationDialog("自動ロックまでの秒数", isPresented: $autoLockConfirmationDialogIsPresented, titleVisibility: .visible) {
            // 既定の5秒(README)を最短に、離席しがちな使い方向けの緩い選択肢を並べる。
            ForEach([5, 10, 30, 60], id: \.self) { seconds in
                Button("\(seconds)秒") {
                    autoLockSeconds = seconds
                }
            }
        }
        .confirmationDialog("文字の大きさ", isPresented: $textSizeConfirmationDialogIsPresented, titleVisibility: .visible) {
            ForEach(TextSize.allCases, id: \.self) { size in
                Button(textSizeLabel(size)) {
                    textSize = size
                }
            }
        }
        .fileExporter(
            isPresented: $markdownExporterIsPresented,
            document: SettingsMarkdownDocument(text: entries.exportMarkdown),
            contentType: SettingsMarkdownDocument.markdownType,
            defaultFilename: "Nikki"
        ) { _ in
            // 保存先の選択キャンセル・失敗はユーザー操作の範囲なので何もしない。
        }
    }

    /// TextSize の表示名。
    private func textSizeLabel(_ textSize: TextSize) -> String {
        switch textSize {
        case .small: return "小さめ"
        case .standard: return "標準"
        case .large: return "大きめ"
        }
    }
}

/// 「Markdown で書き出す」の fileExporter に渡す書類。FileDocument 準拠がフレームワークの要求のため struct で定義する。
struct SettingsMarkdownDocument: FileDocument {
    nonisolated static let readableContentTypes: [UTType] = [markdownType]
    /// .md 拡張子の UTType。環境に markdown の型定義がない場合は plainText に倒す。
    nonisolated static let markdownType = UTType(filenameExtension: "md", conformingTo: .plainText) ?? .plainText

    let text: String

    init(text: String) {
        self.text = text
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct SettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsPage()
        }
        .modelContainer(SampleData.inMemoryContainer())
    }
}
