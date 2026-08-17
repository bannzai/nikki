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
| `build_appstore_screenshots.sh [ios\|mac\|all]` | build-for-testing |
| `run_appstore_screenshots.sh <device> [langs] [pages]` | test-without-building + xcresult から `artifacts/raw/{device}/` へ抽出 |
| `organize_appstore_screenshots.sh <device>` | manifest をパースし、サイズ検証して `fastlane/screenshots/` へ配置 |
| `generate_appstore_screenshots.sh [-d device] [-l langs] [-n pages] [--skip-build]` | 上記を一括実行するオーケストレーション |
| `upload_appstore_screenshots.sh [ios\|osx\|all]` | fastlane deliver で ASC にアップロード(スクショのみ。メタデータ・バイナリに触れない) |

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

- 撮影中に OS の通知バナーが出た場合はテスト側で消えるのを待ってから撮影する(`AppStoreScreenshotSnapshotUITests`)
- シミュレータの OS は `appstore_screenshot_env.sh` の `SIM_RUNTIME` に固定している。ランタイム更新時はこの値を上げる(既存端末は SIM_RUNTIME のランタイム内でだけ再利用され、旧ランタイムの同名端末は使われない)
- deliver は画像のピクセルサイズからデバイス種別(6.9インチ / 13インチ / Mac)を判定する。サイズ検証は organize 時に `verify_png_size` が行う
- upload は `--overwrite_screenshots` で ASC の既存スクリーンショットを置き換えるため、全ページ・全言語・全デバイスが揃っていない状態では実行前チェックで失敗する(部分生成のまま既存を消さないため)
