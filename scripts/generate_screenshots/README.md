# App Store スクリーンショット生成パイプライン

「背景 + キャッチコピー + デバイスフレーム + アプリ画面風UI」を SwiftUI で1画面として実装し、
撮影テストで App Store Connect 要求ピクセルの PNG を生成して fastlane 形式に配置・アップロードする
(appstore-screenshot-builder skill の SwiftUI パイプライン)。

## 構成

| 対象 | キャンバス | 撮影エンジン |
|---|---|---|
| iPhone 6.9インチ (1320x2868) | `AppStoreScreenshotCanvas.iphone` | XCUITest (`NikkiUITests/AppStoreScreenshotSnapshotUITests`) を iPhone 16 Pro Max シミュレータで実行 |
| iPad 13インチ (2064x2752) | `AppStoreScreenshotCanvas.ipad` | 同上を iPad Pro 13-inch (M4) シミュレータで実行 |
| macOS (2880x1800) | `AppStoreScreenshotCanvas.mac` | `NikkiTests/AppStoreScreenshotRenderTests` が ImageRenderer で 1440x900pt @2x を直接描画 |
| iPhone Duo 外側ディスプレイ (1398x2034) | `AppStoreScreenshotCanvas.duoOuter` | XCUITest を iPhone Duo シミュレータ (閉じた姿勢) で実行 (下記「iPhone Duo」) |
| iPhone Duo 内側ディスプレイ (2853x2007) | `AppStoreScreenshotCanvas.duoInner` | XCUITest を iPhone Duo シミュレータ (開いた姿勢) で実行し、ホスト側で `simctl io screenshot --display=primary-1` が撮る (下記「iPhone Duo」) |

- スクショ画面: `Nikki/Features/AppStoreScreenshots/AppStoreScreenshot{1..6}Page.swift` (DEBUG 限定)
- 起動経路: カタログモード `NIKKI_SCREEN=appstore{1..6}` + 言語 `NIKKI_APPSTORE_LANG=ja|en`
- 言語: ja / en (キャッチコピー・モック内文言はスクショ機能内の switch で定義。アプリ本体は未ローカライズのため)

## ページ構成

| ページ | 画面 | 訴求 |
|---|---|---|
| 1 | ホーム(リスト) | 誰にもみられない(プライバシー) |
| 2 | ロック画面 | 自動ロック + Face ID / Touch ID |
| 3 | エディタ | 集中できるエディタ・マークダウン互換 |
| 4 | テンプレート変数入力 | テンプレートですぐ書ける |
| 5 | ホーム(カレンダー) | 振り返り + iPhone/iPad/Mac 同期 |
| 6 | テーマ | 紙色カスタマイズ (Nikki Plus) |

## スクリプト

| スクリプト | 責務 |
|---|---|
| `appstore_screenshot_env.sh` | 環境変数・共通関数(シミュレータの冪等作成、言語→fastlane ロケール、サイズ検証) |
| `build_appstore_screenshots.sh [ios\|mac\|duo\|all]` | build-for-testing (`duo` は iPhone Duo シミュレータ向けの別ビルド。`all` に含めない) |
| `run_appstore_screenshots.sh <device> [langs] [pages]` | test-without-building + xcresult から `artifacts/raw/{device}/` へ抽出 (`device` は iphone / ipad / mac / duo-outer / duo-inner) |
| `organize_appstore_screenshots.sh <device>` | manifest をパースし、サイズ検証して `fastlane/screenshots/` へ配置 |
| `generate_appstore_screenshots.sh [-d device] [-l langs] [-n pages] [--skip-build]` | 上記を一括実行するオーケストレーション (iphone / ipad / mac) |
| `upload_appstore_screenshots.sh [ios\|osx\|all]` | fastlane deliver で ASC にアップロード(スクショのみ。メタデータ・バイナリに触れない) |
| `generate_duo_screenshots.sh [-l langs] [-n pages] [--display outer\|inner\|both] [--skip-build]` | iPhone Duo の外側・内側を一括生成し、`verify_duo_screenshots.sh` で機械検証する (下記「iPhone Duo」) |
| `verify_duo_screenshots.sh <出力dir> <langs> <pages>` | Duo の出力の寸法・alpha・枚数を検証する (テスト: `tests/test_verify_duo_screenshots.sh`) |

## 使い方

```bash
# 1ページ・1言語で確認(iPhone)
./scripts/generate_screenshots/generate_appstore_screenshots.sh -d iphone -l ja -n 1

# 全デバイス・全言語・全ページ生成
./scripts/generate_screenshots/generate_appstore_screenshots.sh

# ASC にアップロード(要 ASC_API_KEY_ID / ASC_API_KEY_ISSUER_ID / ASC_API_KEY_P8_BASE64)
./scripts/generate_screenshots/upload_appstore_screenshots.sh
```

## 出力

- 中間生成物: `scripts/generate_screenshots/artifacts/raw/{device}/` (xcresult と抽出 PNG。gitignore 対象)
- 最終配置: `fastlane/screenshots/ios/{ja,en-US}/{ページ}_{device}.png` (iOS)、`fastlane/screenshots/macos/{ja,en-US}/` (macOS)。
  deliver は screenshots_path 直下のディレクトリをロケールとして読むため、プラットフォームごとに互いを含まないルートに分けている。
  いずれも gitignore 対象で、必要になったら本パイプラインで再生成する

## 注意

- 撮影テストは通常の `xcodebuild test -scheme Nikki` にも含まれるが、`SNAPSHOT_ENABLED=1` (run スクリプトが `TEST_RUNNER_` 経由で渡す) が無い時はスキップする。通常の UI テスト実行にアプリ再起動 12 回と大型 attachment を足さないため
- 撮影はスクショ画面のルート要素 (`AppStoreScreenshotFrame`) の出現を待ってから行い、起動画面や描画途中を撮らない
- 撮影中に OS の通知バナーが出た場合はテスト側で消えるのを待ってから撮影し、消えなければテストを失敗させる (バナーが重なった画像を成果物にしない)
- 部分生成 (`-l` / `-n` の絞り込み) では organize が同デバイスの旧出力を先にすべて消すため、fastlane/screenshots は「今回のコードで生成した分」だけになる。アップロード前の全数チェックはこれを前提にしている (全数生成で再び揃う)
- シミュレータの OS は `appstore_screenshot_env.sh` の `SIM_RUNTIME` に固定している。ランタイム更新時はこの値を上げる(既存端末は SIM_RUNTIME のランタイム内でだけ再利用され、旧ランタイムの同名端末は使われない)
- deliver は画像のピクセルサイズからデバイス種別(6.9インチ / 13インチ / Mac)を判定する。サイズ検証は organize 時に `verify_png_size` が行う
- upload は `--overwrite_screenshots` で ASC の既存スクリーンショットを置き換えるため、全ページ・全言語・全デバイスが揃っていない状態では実行前チェックで失敗する(部分生成のまま既存を消さないため)

## iPhone Duo

折りたたみ端末 iPhone Duo の App Store スクリーンショット (外側ディスプレイ・内側ディスプレイ) は、上の iPhone / iPad / mac とは別の `generate_duo_screenshots.sh` で生成する。
作り方の SSOT は appstore-screenshot-builder skill の `references/iphone-duo.md`。

### 生成

```bash
# 全言語・全ページの外側 + 内側 (24 枚) を生成し、機械検証まで行う
./scripts/generate_screenshots/generate_duo_screenshots.sh

# 1 ページ・1 言語で確認
./scripts/generate_screenshots/generate_duo_screenshots.sh -l ja -n 1
```

- 前提: Xcode 27.1 以降 + iOS 27.1 ランタイム (iPhone Duo のシミュレータはそれ以降にしか無い)、ImageMagick (`magick`)、jq、ios-simulator skill の `duo-pose.sh`
- ローカルの Mac でしか実行できない。姿勢の切り替え (`duo-pose.sh`) が Device Hub のウィンドウをアクセシビリティ API で操作するため、simtunnel のリモート simulator では使えない。本リポジトリの CLAUDE.md「シミュレータでの動作確認は simtunnel を使う」の例外に当たる
- 外側は閉じた姿勢で撮影テスト (`AppStoreScreenshotSnapshotUITests`) が撮る。内側は XCTest の API では仕様の寸法で撮れないため、テストがページを表示して `{attachment 名}.ready` を書いた時点でホスト側が `xcrun simctl io <UDID> screenshot --display=primary-1` で撮り、`.done` を書いてテストを進める (撮影に失敗した時は `.failed` を書き、テストは timeout を待たずに失敗する) (根拠: `references/iphone-duo.md` の SwiftUI の節 5 番「`XCTAttachment(screenshot: app.screenshot())` は真っ黒な 2006×2852 を返す」「`screens[1].screenshot()` は…仕様 (2853×2007) より縦横 1px ずつ小さい」)
- 内側は横向き (2853x2007) で作る。開いた姿勢のシミュレータは向きが landscapeRight になり、simctl が回転なしで 2853x2007 を返すため (同参照「決めること」の根拠)。レイアウトは `AppStoreScreenshotCanvas.duoInner` (キャッチコピーを左、縮小した iPhone フレームを右に置く 2 カラム)
- キャンバスは環境変数 `NIKKI_APPSTORE_CANVAS` (duoOuter / duoInner) で切り替える。Duo の idiom は phone のため、端末種別からは iPhone と区別できない
- xcodebuild には `-parallel-testing-enabled NO` を渡す。既定の clone は閉じた姿勢で起動し、元の simulator の姿勢が反映されないため (同参照 SwiftUI の節 2 番)

### 出力

`scripts/generate_screenshots/artifacts/duo/{ja,en-US}/{outer,inner}/{1..6}.png` (gitignore 対象)。

`fastlane/screenshots/` には置かない。fastlane deliver は画像の px 寸法で表示クラスを判定し、Duo の寸法を知らないため、置くと deliver の検証で iPhone / iPad のアップロード全体が止まる (根拠: `references/iphone-duo.md`「アップロード経路」の表: deliver 2.241.0 の `deliver/lib/deliver/app_screenshot.rb` の `DEVICE_RESOLUTIONS` に Duo の寸法が無く、`app_screenshot_validator.rb` が「Screenshot size is not supported」で落とす)。

### App Store Connect へのアップロード

`upload_appstore_screenshots.sh` (deliver) は Duo を扱わない。次のどちらかで上げる。

1. **`asc` CLI (5.12.0 以降)**。App Store Connect API は公開の OpenAPI 仕様に無い表示タイプ `APP_IPHONE_DUO` を受け付け、`asc` 5.12.0 が対応した (根拠: 同参照「アップロード経路」の表。対応 PR https://github.com/rorkai/App-Store-Connect-CLI/pull/2926 )。API 上は外側と内側の 4 寸法が 1 つの表示タイプ `APP_IPHONE_DUO` に属し、`asc screenshots sizes --display-type APP_IPHONE_DUO` が 4 寸法を 1 つの表示タイプとして返す (根拠: 同参照「アップロード経路」の表の asc の行)。1 つの表示タイプの枠は最大 10 枚のため、外側 6 枚 + 内側 6 枚の 12 枚は全部は入らない。**内側の寸法をサーバが受け付けるかは未確認** (同 PR が明記)。Web UI でこの表示タイプがどう見えるか (1 つの枠か、外側・内側で別の枠か) は、API の扱いとは別に未確認 (次の 2 を参照)

   ```bash
   asc --version   # 5.12.0 以降であること
   # <LOCALIZATION_ID> は対象バージョンの言語ごとの ID (asc の version-localizations の一覧コマンドで取る。取り方は asc のヘルプを正とする)
   # 1 枠に最大 10 枚のため、--path には 10 枚以内に選んだ画像を置いたディレクトリを渡す (例: 外側 6 枚 + 内側 4 枚)
   asc screenshots upload --version-localization <LOCALIZATION_ID> --path <10 枚以内に選んだ画像のディレクトリ> --device-type APP_IPHONE_DUO --skip-existing
   ```

   言語ごとに `<LOCALIZATION_ID>` と `--path` を変えて実行する (ja と en-US で 2 回)。

2. **App Store Connect の Web UI**。App Store Connect → 対象アプリ → 対象バージョン → 「iPhone Duo」の枠を開く (枠の名称・表示と、API 上は 1 つの表示タイプである外側と内側を Web UI が 1 つの枠で見せるか別の枠で見せるかは未確認。Web UI の画面を本パイプラインの作成時に見ていない)
   - 外側と内側が同じ枠なら、1 枠が最大 10 枚のため、`artifacts/duo/{言語}/outer/{1..6}.png` と `inner/{1..6}.png` の 12 枚から 10 枚以内 (例: 外側 6 枚 + 内側 1〜4) を選んでページ番号順にドラッグする
   - 別の枠なら、外側の枠に `outer/{1..6}.png`、内側の枠に `inner/{1..6}.png` をそれぞれページ番号順にドラッグする
   - 言語ごとに ja と en-US を切り替えて同じ操作を行う
