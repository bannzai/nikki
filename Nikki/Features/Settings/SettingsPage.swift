import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 設定画面(1r)。iOS 標準のグループ化リスト形式で各設定項目を表示し、
/// 各行の選択・切り替えを AppStorage の typed key へ永続化する。
struct SettingsPage: View {
    @AppStorage(.faceIDUnlockEnabled) var faceIDUnlockEnabled: Bool = true
    // README の「5秒タイプがなかったらロック」に合わせた既定値。
    @AppStorage(.autoLockSeconds) var autoLockSeconds: Int = 5
    @AppStorage(.textSize) var textSize: TextSize = .standard
    // 見本(1n)の初期選択が「生成」(プリセット2番目)のため。
    @AppStorage(.paperColorPresetIndex) var paperColorPresetIndex: Int = 1

    @State var notebookSettingsIsPresented = false
    @State var autoLockIsPresented = false
    @State var textSizeConfirmationDialogIsPresented = false
    @State var themeIsPresented = false
    @State var licenseIsPresented = false
    @State var archiveIsPresented = false
    @State var paywallSheetIsPresented = false
    @State var markdownExporterIsPresented = false
    @State var deleteAllEntriesConfirmationDialogIsPresented = false

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]
    /// Markdown 書き出しは読んだときに時系列で並ぶよう古い順に取り出す。
    @Query(sort: \JournalEntry.date) var entries: [JournalEntry]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.plusActive) private var plusActive
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor

    var body: some View {
        ZStack(alignment: .top) {
            paperColor.ignoresSafeArea()

            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title(String(localized: "Settings")), onLeading: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsSectionLabel(text: String(localized: "Writing"))
                        InkListSection {
                            // テンプレートの管理(作成・編集・削除)の入り口。
                            InkListRow(
                                title: String(localized: "Templates"),
                                value: String(localized: "\(notebooks.count) templates"),
                                action: { notebookSettingsIsPresented = true }
                            )
                            InkListRow(
                                title: String(localized: "Auto-lock"),
                                // Plus 失効時は自動ロックのフォールバックと同じ実効値を表示する。
                                value: String(localized: "\(effectiveAutoLockSeconds(storedSeconds: autoLockSeconds, plusActive: plusActive)) seconds"),
                                showsSeparator: false,
                                action: { autoLockIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: String(localized: "Lock"))
                        InkListSection {
                            // パスキーは未実装のため行を置かない(実装したらここに登録行を戻す。issue #84)。
                            InkListRow(title: String(localized: "Unlock with Face ID"), showsSeparator: false, trailing: AnyView(SettingsToggle(isOn: $faceIDUnlockEnabled)))
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: String(localized: "Appearance"))
                        InkListSection {
                            InkListRow(
                                title: String(localized: "Theme"),
                                // Plus 失効時はテーマ画面のフォールバックと同じ実効値を表示する。
                                value: paperColorPresetLabel(index: effectivePaperColorPresetIndex(storedIndex: paperColorPresetIndex, plusActive: plusActive)),
                                action: { themeIsPresented = true }
                            )
                            InkListRow(
                                title: String(localized: "Text size"),
                                value: textSizeLabel(textSize),
                                showsSeparator: false,
                                action: { textSizeConfirmationDialogIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: String(localized: "Data"))
                        InkListSection {
                            InkListRow(
                                title: String(localized: "Archived entries"),
                                action: { archiveIsPresented = true }
                            )
                            InkListRow(
                                title: String(localized: "Export as Markdown"),
                                action: { markdownExporterIsPresented = true }
                            )
                            // 遷移ではなく確認ダイアログを開くアクション行のため、シェブロンは出さない。
                            InkListRow(
                                title: String(localized: "Delete all entries"),
                                showsChevron: false,
                                action: { deleteAllEntriesConfirmationDialogIsPresented = true }
                            )
                            InkListRow(
                                title: "Nikki Plus",
                                value: plusActive ? String(localized: "Active") : String(localized: "Not subscribed"),
                                showsSeparator: false,
                                action: { paywallSheetIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: String(localized: "About"))
                        InkListSection {
                            InkListRow(
                                title: String(localized: "Open source licenses"),
                                showsSeparator: false,
                                action: { licenseIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        Text("Nikki 1.0.0 — Your journal stays on this device.")
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
        .inkNavigationBarHidden()
        .navigationDestination(isPresented: $themeIsPresented) {
            ThemePage()
        }
        .navigationDestination(isPresented: $licenseIsPresented) {
            LicensePage()
        }
        .navigationDestination(isPresented: $archiveIsPresented) {
            ArchivePage()
        }
        .navigationDestination(isPresented: $notebookSettingsIsPresented) {
            NotebookSettingsPage()
        }
        .navigationDestination(isPresented: $autoLockIsPresented) {
            AutoLockPage()
        }
        .sheet(isPresented: $paywallSheetIsPresented) {
            PaywallPage()
        }
        .confirmationDialog("Delete all entries", isPresented: $deleteAllEntriesConfirmationDialogIsPresented, titleVisibility: .visible) {
            Button("Delete all entries", role: .destructive) {
                // 直後にアプリが kill されても結果が残るよう save まで行う。失敗しても @Query の再評価でストアの実態に追従するため、ここではエラーを扱わない。
                try? modelContext.deleteAllJournalEntries()
            }
        } message: {
            Text("This deletes every entry, including archived ones. This cannot be undone.")
        }
        .confirmationDialog("Text size", isPresented: $textSizeConfirmationDialogIsPresented, titleVisibility: .visible) {
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
        case .small: return String(localized: "Small")
        case .standard: return String(localized: "Standard")
        case .large: return String(localized: "Large")
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
