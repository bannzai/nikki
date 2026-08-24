# iOS の TestFlight 配布手順

`.github/workflows/ios-deploy.yml` を手動起動すると、Nikki (bundle `com.bannzai.Nikki`) の Release ビルドが
arm64 実機向けにアーカイブされ、TestFlight (App Store Connect、appId 6799104638) へアップロードされる。
署名は手動署名 (Secrets の証明書 + profile を CI で復元)。cloud signing (自動署名) は API Key に Admin ロールが
必須になるため採用していない。方式の決定理由は castle の ios-deploy-actions skill の
`references/signing-design.md` (`~/.claude/skills/ios-deploy-actions/references/signing-design.md`) を参照。

workflow は同 skill (`~/.claude/skills/ios-deploy-actions/SKILL.md`) が生成・管理する (1 行目に管理マーカー)。
手で編集せず、変更が必要な時は skill の `scaffold-ios-deploy.sh` で再生成する。
skill の実体は https://github.com/bannzai/castle の `home/.agents/skills/ios-deploy-actions/` にあり、
新しい運用マシンでは castle のセットアップ (homesick) で `~/.claude/skills/` に展開される。

macOS 版のビルド・配布はこの workflow の対象外 (Archive は `generic/platform=iOS` のみ)。

## 前提 (初回のみ / 更新時)

1. App Store Connect のアプリレコード (appId 6799104638、Nikki - Private Journal) は作成済み
2. App Store Connect API Key。アップロード認証 (altool) と profile の API 発行に使う。Admin ロール不要
3. 配布証明書と provisioning profile。profile は発行済み (`Nikki.AppStore`、期限は **2027-06-10**)。
   証明書の期限は profile とは別で、skill の `asc-api.sh GET "/v1/certificates"` で確認する。
   証明書はチームで 1 枚を使い回す (プロジェクトごとに発行すると Apple のチーム上限に当たる)。
   再発行は ios-deploy-actions skill の `signing-assets.sh` で行う
4. GitHub Secrets (Settings > Secrets and variables > Actions) に次の 6 つを登録する。
   登録は ios-deploy-actions skill の `register-secrets.sh` (非空検証つき一括登録) を使う

   | Secret | 内容 |
   | --- | --- |
   | `ASC_API_KEY_ID` | API Key の Key ID |
   | `ASC_API_KEY_ISSUER_ID` | Issuer ID (UUID) |
   | `ASC_API_KEY_P8_BASE64` | `AuthKey_<KEY_ID>.p8` の base64 |
   | `IOS_P12_CERTIFICATE_BASE64` | 配布証明書 .p12 の base64 (チーム共有の CI 用) |
   | `IOS_P12_PASSWORD` | p12 のパスワード |
   | `IOS_PROVISIONING_PROFILE_BASE64` | `Nikki.AppStore` profile の base64 |

秘密の実値はリポジトリに置かない。RevenueCat の public API key はアプリに同梱される公開値のため
`Nikki/Models/Const.swift` にそのまま置いてあり、ビルド時の Secret は不要 (Xcode Cloud 由来の
`ci_scripts/` や `Config.local.xcconfig` の仕組みも持たない)。

## 配布する

```sh
gh workflow run ios-deploy.yml --ref main
gh run list --workflow ios-deploy.yml --limit 3
RUN_ID=123456789   # 直前の gh run list で確認した、今起動した run の ID
gh run watch "$RUN_ID"
```

- workflow_dispatch はデフォルトブランチに workflow がある状態でないと起動できない。新規追加・改名した時は
  main へマージしてから初回を起動する
- ビルド番号は `github.run_number + BUILD_NUMBER_OFFSET`。**現在の offset は 1** (TestFlight にビルドが 1 件も
  無い状態から始めたため)。run_number が巻き戻る事態では offset を既存の最大ビルド番号を超える値に上げる
- ビルド番号の実体は `Nikki/Info.plist` の `CFBundleVersion` = `$(CURRENT_PROJECT_VERSION)`。workflow が
  xcodebuild へ `CURRENT_PROJECT_VERSION=<番号>` を渡して上書きする。ここを固定値に戻すと毎回同じ番号を
  アップロードして拒否される
- アプリのバージョンは `Nikki/Info.plist` の `CFBundleShortVersionString` (現在 1.0.0)。TestFlight のビルドは
  この値のグループに並ぶため、App Store 側で用意したバージョン番号と揃えてから配布する
- 配布は同時に 1 本だけ。先行 run が未完了だと最初の step (Reject concurrent dispatch) で失敗する
- Upload to TestFlight まで進んで失敗した run は Re-run せず新しく dispatch する (Re-run ではビルド番号が
  変わらず、アップロード済みと同じ番号の再送は拒否されるため)。Upload より前の step で失敗した run は、
  その番号がまだアップロードされていないため Re-run で復旧してよい
- public リポジトリのため macOS runner は無料

## TestFlight で処理完了になったことを確認する

```sh
bash ~/.claude/skills/ios-deploy-actions/scripts/asc-api.sh GET \
  "/v1/builds?filter[app]=6799104638&sort=-uploadedDate&limit=5&fields[builds]=version,processingState,uploadedDate" \
  | jq '.data[] | {version: .attributes.version, processingState: .attributes.processingState, uploadedDate: .attributes.uploadedDate}'
```

`processingState` が `PROCESSING` → `VALID` になれば TestFlight にビルドが並ぶ。
`Info.plist` の `ITSAppUsesNonExemptEncryption = false` 設定済みのため輸出コンプライアンスの毎回回答は不要。

## ローカルビルドへの影響

`project.pbxproj` の手動署名指定は Release かつ実機 SDK (`[sdk=iphoneos*]`) に限定してある。

- simulator ビルド (`make ios`) と macOS ビルド (`make macos`) は Automatic 署名のまま。影響しない
- 実機 Release ビルド (`make ios-device`) は `Nikki.AppStore` profile と Apple Distribution 証明書を
  ローカルの Keychain / Provisioning Profiles に持っている必要がある。持っていない場合は
  `-configuration Debug` でビルドする

## うまくいかない時

- `No signing certificate` / `No profiles ... were found`: Secrets の .p12 / .mobileprovision と、
  `project.pbxproj` の `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]` の profile 名 (`Nikki.AppStore`)、
  workflow が生成する ExportOptions.plist の profile 名の 3 つが一致しているか確認する
- profile の期限切れ (2027-06-10) か証明書の期限切れ (期限は別。`asc-api.sh GET "/v1/certificates"` で確認):
  ios-deploy-actions skill で再発行し Secrets を更新する
- `The bundle version must be higher than the previously uploaded version`: `BUILD_NUMBER_OFFSET` を上げる
- Archive が SwiftPM プラグインの信頼確認で止まる: workflow の Archive は LicenseList の BuildToolPlugin の
  ために `-skipPackagePluginValidation` を付けてある (Makefile・test.yml と同じ理由)。再生成する時は
  `--var 'EXTRA_XCODEBUILD_FLAGS=-skipPackagePluginValidation'` を落とさない
- `SecKeychainItemImport: MAC verification failed`: .p12 が OpenSSL 3.x の既定形式。`-legacy` で作り直す
