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
    /// 既定のノートの id(UUID 文字列)。空のときは未設定。
    @AppStorage(.defaultNotebookID) var defaultNotebookID: String = ""
    @AppStorage(.textSize) var textSize: TextSize = .standard
    // 見本(1n)の初期選択が「生成」(プリセット2番目)のため。
    @AppStorage(.paperColorPresetIndex) var paperColorPresetIndex: Int = 1

    @State var defaultNotebookConfirmationDialogIsPresented = false
    @State var autoLockConfirmationDialogIsPresented = false
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

    var body: some View {
        ZStack(alignment: .top) {
            Color.inkPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                InkNavBar(leading: .back, center: .title("設定"), onLeading: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsSectionLabel(text: "書くこと")
                        InkListSection {
                            // ノートが1冊の間はノートを意識させないため、選択肢が生まれる2冊以上のときだけ行を出す。
                            if notebooks.count >= 2 {
                                InkListRow(
                                    title: "既定のノート",
                                    // 未設定のときは新規作成と同じ解決(先頭のノート)を表示する。
                                    value: (notebooks.first { $0.id.uuidString == defaultNotebookID } ?? notebooks.first)?.name ?? "未設定",
                                    action: { defaultNotebookConfirmationDialogIsPresented = true }
                                )
                            }
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
                                // Plus 失効時はテーマ画面のフォールバックと同じ実効値を表示する。
                                value: paperColorPresetLabel(index: effectivePaperColorPresetIndex(storedIndex: paperColorPresetIndex, plusActive: plusActive)),
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
                                title: "アーカイブした日記",
                                action: { archiveIsPresented = true }
                            )
                            InkListRow(
                                title: "Markdown で書き出す",
                                action: { markdownExporterIsPresented = true }
                            )
                            // 遷移ではなく確認ダイアログを開くアクション行のため、シェブロンは出さない。
                            InkListRow(
                                title: "すべての日記を削除",
                                showsChevron: false,
                                action: { deleteAllEntriesConfirmationDialogIsPresented = true }
                            )
                            InkListRow(
                                title: "Nikki Plus",
                                value: plusActive ? "加入中" : "未加入",
                                showsSeparator: false,
                                action: { paywallSheetIsPresented = true }
                            )
                        }
                        .padding(.bottom, 20)

                        SettingsSectionLabel(text: "このアプリについて")
                        InkListSection {
                            InkListRow(
                                title: "OSS ライセンス",
                                showsSeparator: false,
                                action: { licenseIsPresented = true }
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
        .sheet(isPresented: $paywallSheetIsPresented) {
            PaywallPage()
        }
        .confirmationDialog("すべての日記を削除", isPresented: $deleteAllEntriesConfirmationDialogIsPresented, titleVisibility: .visible) {
            Button("すべての日記を削除", role: .destructive) {
                // 直後にアプリが kill されても結果が残るよう save まで行う。失敗しても @Query の再評価でストアの実態に追従するため、ここではエラーを扱わない。
                try? modelContext.deleteAllJournalEntries()
            }
        } message: {
            Text("アーカイブした日記も含めて、すべての日記を削除します。この操作は取り消せません。")
        }
        .confirmationDialog("既定のノート", isPresented: $defaultNotebookConfirmationDialogIsPresented, titleVisibility: .visible) {
            ForEach(notebooks) { notebook in
                Button(notebook.name) {
                    defaultNotebookID = notebook.id.uuidString
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
