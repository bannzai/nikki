# App Store 提出時の申告メモ (issue #5)

審査提出・App Store Connect 入力時に参照する、コードの実態に基づく申告内容のメモ。
コード側の変更で実態が変わったら本メモも更新する。

## App Privacy (プライバシーラベル)

申告: **購入 (Purchase History) のみ収集 / ユーザーに紐付かない (Data Not Linked to You) / トラッキングなし**

回答定義の SSOT: `fastlane/app_privacy_details.json` (appstore-app-privacy skill で ASC へ適用・publish する)

- category: `PURCHASE_HISTORY`
- purposes: `ANALYTICS`, `APP_FUNCTIONALITY`
- data_protections: `DATA_NOT_LINKED_TO_YOU`

根拠:

- RevenueCat SDK (PaywallPage / RootPage で使用) を導入したため、当初方針の「データは収集されません (Data Not Collected)」から変更した。RevenueCat 公式ドキュメント ( https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-app-privacy ) は「If you are using RevenueCat, you must disclose that your app collects 'Purchases' information」とし、Purchase History の purposes には最低限 Analytics (Customer History / Charts / Experiments のダッシュボード機能) と App Functionality (不正防止のレシート検証・Entitlements) の両方を選ぶよう定めている
- ユーザーへの紐付け: RevenueCat の匿名 app user ID のみを使用しており (`Purchases.logIn` やカスタム app user ID の設定はコードベースに存在しない)、個人を特定する手段がないため Data Not Linked to You。公式ドキュメントも「If you are using RevenueCat's anonymous app user ID's, and do not have a way to identify individual users, you can select 'No'.」としている
- トラッキング: RevenueCat は購入履歴をアプリ横断の広告トラッキングに使わない (公式ドキュメント「RevenueCat, as a third-party, does not inherently use purchase history to track users across different apps for advertising.」)。IDFA・広告 SDK も未使用のため Data Used to Track You は申告しない
- 今後 `Purchases.logIn` 等でカスタム ID を連携する場合は、Data Linked to You への変更と User ID category の追加が必要になる (再判定のトリガー)

RevenueCat 以外は引き続き収集なし:

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

- iOS / iPadOS / macOS: 単一のマルチプラットフォームターゲット (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx`)。
  App ID `com.bannzai.Nikki` は UNIVERSAL で、iOS / macOS とも**同一 Bundle ID** で配布する
- macOS: **ネイティブ macOS アプリとして配布する** (issue #26 で Designed for iPad から移行)。
  `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO` のため「iPad アプリを Mac で実行」の配布形態は持たない
- Info.plist / entitlements は macOS 専用ファイル (`Nikki/Info-macOS.plist` / `Nikki/Nikki-macOS.entitlements`) を
  `[sdk=macosx*]` の条件付きビルド設定で使い分ける
- App Sandbox: Mac App Store の必須要件として、macOS 側 entitlements に `com.apple.security.app-sandbox` を設定済み。
  CloudKit / RevenueCat の通信のため `com.apple.security.network.client` も併せて必要。iOS 側 entitlements には不要
- APNs (CloudKit のサーバ変更通知): macOS は iOS の `aps-environment` と異なり
  `com.apple.developer.aps-environment` キーを使う

## iCloud (CloudKit) スキーマ管理

- コンテナ: `iCloud.com.bannzai.Nikki` (development / production の 2 環境を持つ)
- SwiftData (`ModelConfiguration(cloudKitDatabase: .private(...))`) は development 環境へは実行時にスキーマを自動生成するが、
  **production へは自動反映されない**。リリース前に CloudKit Console で「Deploy Schema Changes」
  (development → production) を実行すること。モデル変更を伴うリリースの都度必要
- TestFlight / App Store ビルドは production 環境を使うため、スキーマ未デプロイだと同期が失敗する

## エラートラッキング・監視

方針: **導入しない**。プライバシーラベルの「購入以外は収集なし」の申告およびプライバシーポリシーの
「アクセス解析なし」記述と整合させるため、サードパーティのクラッシュ解析・監視 SDK は入れない。
クラッシュ把握は Apple 標準 (ユーザーが共有に同意した場合の Xcode Organizer / App Store Connect のクラッシュレポート) のみを使う。

## 法務ドキュメントの掲載

- 利用規約 / プライバシーポリシー (日英) は `docs/legal/` に markdown で用意し、GitHub Pages (main ブランチ /docs, Jekyll) で公開する
- 公開 URL: https://bannzai.github.io/nikki/legal/terms-ja.html ほか (.md は Jekyll が .html に変換する)

## 提出前の ASC 設定 (カテゴリ・価格・年齢制限・審査連絡先・販売地域)

定義の SSOT: `fastlane/asc_submission_settings.json`。適用と検証は `scripts/asc_apply_submission_settings.sh` で行う
(現状 GET → 差分があれば適用 → 再 GET で検証。定義どおりなら書き込まない)。`--dry-run` で差分確認のみできる。

- カテゴリ: primary = ライフスタイル (`LIFESTYLE`)、secondary = 仕事効率化 (`PRODUCTIVITY`)
- アプリ本体の価格: 無料 (ベーステリトリー JPN、customerPrice 0)。有料機能はすべて IAP (RevenueCat) で提供する
- 年齢制限指定: 全質問「なし」(enum は `NONE`、真偽値は `false`)。日記アプリで該当項目がないため。iOS / macOS 共通の appInfo に紐付く
- App Review 連絡先: iOS / macOS 各バージョンの `appStoreReviewDetails` に設定。デモアカウントはアカウント不要アプリのため「不要」。
  電話番号は個人情報のためリポジトリに含めず、環境変数 `ASC_REVIEW_CONTACT_PHONE` (E.164 形式) で渡す
- 販売地域: 全テリトリー (`availableInNewTerritories: true` + 全テリトリー available)
- 新しいバージョンを作成したら、審査連絡先はバージョンごとのリソースのため同スクリプトを再実行する
