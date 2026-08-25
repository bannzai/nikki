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
    @State var pdfExporterIsPresented = false
    @State var htmlExporterIsPresented = false
    @State var deleteAllEntriesConfirmationDialogIsPresented = false

    @Query(sort: \JournalNotebook.sortOrder) var notebooks: [JournalNotebook]
    /// Markdown 書き出しは読んだときに時系列で並ぶよう古い順に取り出す。
    @Query(sort: \JournalEntry.date) var entries: [JournalEntry]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.plusActive) private var plusActive
    @Environment(\.modelContext) private var modelContext
    @Environment(\.paperColor) private var paperColor
    @Environment(\.cloudSyncActive) private var cloudSyncActive

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
                        // 加入状態と実際の同期状態が食い違う間だけ出す注記(#93)を、セクションの直下に添える。
                        VStack(alignment: .leading, spacing: 0) {
                            InkListSection {
                                InkListRow(
                                    title: String(localized: "Archived entries"),
                                    action: { archiveIsPresented = true }
                                )
                                // fileExporter は同じ View に複数付けると最後の1つしか機能しないため、
                                // 書き出し行ごとに自分の行へ付けて分離する(PDF / HTML の行も同様)。
                                InkListRow(
                                    title: String(localized: "Export as Markdown"),
                                    action: { markdownExporterIsPresented = true }
                                )
                                .fileExporter(
                                    isPresented: $markdownExporterIsPresented,
                                    document: SettingsMarkdownDocument(text: entries.exportMarkdown),
                                    contentType: SettingsMarkdownDocument.markdownType,
                                    defaultFilename: "Nikki"
                                ) { _ in
                                    // 保存先の選択キャンセル・失敗はユーザー操作の範囲なので何もしない。
                                }
                                // PDF / HTML の装飾付き書き出しは Plus 限定(#95)。Markdown は無料のまま変更しない。
                                InkListRow(
                                    title: String(localized: "Export as PDF"),
                                    trailing: plusActive ? nil : AnyView(
                                        Image(systemName: InkIcons.lock)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Color.inkTextSecondary)
                                    ),
                                    action: {
                                        if plusActive {
                                            pdfExporterIsPresented = true
                                        } else {
                                            paywallSheetIsPresented = true
                                        }
                                    }
                                )
                                .fileExporter(
                                    isPresented: $pdfExporterIsPresented,
                                    document: SettingsPDFDocument(
                                        // PDF はページごとに ImageRenderer で描画する分 markdown/HTML より重いため、シートを開く
                                        // 直前まで(pdfExporterIsPresented が true になるまで)計算を遅らせ、body の再評価のたびには作らない。
                                        data: pdfExporterIsPresented
                                            ? SettingsExportPDFGenerator.makeData(
                                                entries: entries,
                                                paperColor: effectivePaperColor(storedIndex: paperColorPresetIndex, plusActive: plusActive)
                                            )
                                            : Data()
                                    ),
                                    contentType: SettingsPDFDocument.pdfType,
                                    defaultFilename: "Nikki"
                                ) { _ in
                                    // 保存先の選択キャンセル・失敗はユーザー操作の範囲なので何もしない。
                                }
                                InkListRow(
                                    title: String(localized: "Export as HTML"),
                                    trailing: plusActive ? nil : AnyView(
                                        Image(systemName: InkIcons.lock)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Color.inkTextSecondary)
                                    ),
                                    action: {
                                        if plusActive {
                                            htmlExporterIsPresented = true
                                        } else {
                                            paywallSheetIsPresented = true
                                        }
                                    }
                                )
                                .fileExporter(
                                    isPresented: $htmlExporterIsPresented,
                                    document: SettingsHTMLDocument(
                                        // 全件を HTML へ変換する処理は件数に比例して重いため、シートを開く直前まで
                                        // (htmlExporterIsPresented が true になるまで)遅らせ、body の再評価のたびには作らない。
                                        text: htmlExporterIsPresented
                                            ? entries.exportHTML(
                                                paperColorHex: String(
                                                    format: "#%06X",
                                                    Color.paperColorPresetHex[effectivePaperColorPresetIndex(storedIndex: paperColorPresetIndex, plusActive: plusActive)]
                                                ),
                                                // 未対応言語の端末は英語 UI にフォールバックするため、言語コードが取れない場合も開発言語(en)にする。
                                                languageCode: Locale.appLanguage.language.languageCode?.identifier ?? "en"
                                            )
                                            : ""
                                    ),
                                    contentType: SettingsHTMLDocument.htmlType,
                                    defaultFilename: "Nikki"
                                ) { _ in
                                    // 保存先の選択キャンセル・失敗はユーザー操作の範囲なので何もしない。
                                }
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

                            // ModelContainer は起動時に一度だけ構成されるため、加入状態を変えた直後は
                            // 実際に同期しているか(cloudSyncActive)と食い違う(#93)。
                            if plusActive != cloudSyncActive {
                                Text("Restart Nikki to apply your plan change to iCloud sync.")
                                    .font(.ink(11.5))
                                    .lineSpacing(inkLineSpacing(fontSize: 11.5, multiplier: 1.9))
                                    .foregroundStyle(Color.inkTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                            }
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

/// 「PDF で書き出す」(#95、Plus 限定)の fileExporter に渡す書類。
struct SettingsPDFDocument: FileDocument {
    nonisolated static let readableContentTypes: [UTType] = [pdfType]
    nonisolated static let pdfType = UTType.pdf

    let data: Data

    init(data: Data) {
        self.data = data
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// 「HTML で書き出す」(#95、Plus 限定)の fileExporter に渡す書類。
struct SettingsHTMLDocument: FileDocument {
    nonisolated static let readableContentTypes: [UTType] = [htmlType]
    /// .html 拡張子の UTType。環境に html の型定義がない場合は plainText に倒す。
    nonisolated static let htmlType = UTType(filenameExtension: "html", conformingTo: .plainText) ?? .plainText

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
