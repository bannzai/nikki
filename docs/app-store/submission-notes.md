# App Store 提出時の申告メモ (issue #5)

審査提出・App Store Connect 入力時に参照する、コードの実態に基づく申告内容のメモ。
コード側の変更で実態が変わったら本メモも更新する。

## App Privacy (プライバシーラベル)

申告: **データは収集されません (Data Not Collected)**

根拠:

- 日記データはユーザーの端末と iCloud private database (`iCloud.com.bannzai.Nikki`) にのみ保存され、開発者はアクセスできない。Apple のガイドライン上、開発者がアクセスできない iCloud private database のデータは「収集」に該当しない
- アクセス解析・広告 SDK・トラッキングなし。開発者運営のサーバーなし
- Face ID / Touch ID の生体情報は OS 内で完結し、アプリからアクセス不可
- IAP の決済情報は Apple が処理し、開発者には渡らない

## 輸出コンプライアンス (暗号化)

申告: **免除区分 (Info.plist の `ITSAppUsesNonExemptEncryption` = false を設定済み)**

根拠: 独自の暗号実装を持たず、HTTPS と iCloud (CloudKit) の OS 標準暗号化のみを使用するため。
提出ごとの申告質問は Info.plist の宣言により省略される。

## 特定商取引法表記

結論: **原則不要**

根拠: 販売はすべて Apple の IAP 経由であり、日本での販売者 (販売業者) は Apple (iTunes 株式会社) となるため、
開発者側での特商法表記は原則不要。IAP 以外の直接販売を始める場合は再検討する。

## プラットフォーム構成 / App Sandbox

- iOS / iPadOS: 単一の iOS アプリターゲット (`TARGETED_DEVICE_FAMILY = 1,2`)。App ID `com.bannzai.Nikki` は UNIVERSAL
- macOS: ネイティブ macOS ターゲットは持たず、**iPad アプリを Apple シリコン Mac で配布する (Designed for iPad)**。
  Mac App Store への掲載は App Store Connect の「Mac で利用可能」設定で行う
- App Sandbox: iOS アプリを Mac で実行する場合はシステムが自動でサンドボックス化するため、
  entitlements への `com.apple.security.app-sandbox` 追加は不要 (ネイティブ macOS ターゲットを作る場合にのみ必要)

## iCloud (CloudKit) スキーマ管理

- コンテナ: `iCloud.com.bannzai.Nikki` (development / production の 2 環境を持つ)
- SwiftData (`ModelConfiguration(cloudKitDatabase: .private(...))`) は development 環境へは実行時にスキーマを自動生成するが、
  **production へは自動反映されない**。リリース前に CloudKit Console で「Deploy Schema Changes」
  (development → production) を実行すること。モデル変更を伴うリリースの都度必要
- TestFlight / App Store ビルドは production 環境を使うため、スキーマ未デプロイだと同期が失敗する

## エラートラッキング・監視

方針: **導入しない**。「データは収集されません」のプライバシーラベルおよびプライバシーポリシーの
「アクセス解析なし」記述と整合させるため、サードパーティのクラッシュ解析・監視 SDK は入れない。
クラッシュ把握は Apple 標準 (ユーザーが共有に同意した場合の Xcode Organizer / App Store Connect のクラッシュレポート) のみを使う。

## 法務ドキュメントの掲載

- 利用規約 / プライバシーポリシー (日英) は `docs/legal/` に静的 HTML として用意済み
- App Store の URL 要件を満たすため、公開ホスティング (GitHub Pages 等) の有効化が別途必要
