---
feature: _root
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# QA 全体ガイド

## 対象環境

- ローカル環境の Debug ビルド (開発用 in-memory / ローカルストア。CloudKit 同期は行われない)
- リリース前 QA は simtunnel (GitHub Actions macOS Runner 上の iOS Simulator) を優先する。経路の詳細は docs/simtunnel.md
- CloudKit 同期・課金の Sandbox 実購入は simulator では検証できない。TestFlight 配布後の人間確認項目とする

## 起動方法

- リモート (推奨): `simtunnel up nikki --ref <検証ブランチ> --wait` でセッションを起動する (docs/simtunnel.md)。アプリの build / install / launch は workflow が行う
- ローカル iOS: `make ios` (Simulator 向けビルドのみ)。ローカル macOS: `make macos`
- ユニットテスト: `.github/workflows/test.yml` (GitHub Actions) または `xcodebuild test -project Nikki.xcodeproj -scheme Nikki -only-testing:NikkiTests`
- 画面単体の直接起動 (DEBUG のみ): 環境変数 `NIKKI_SCREEN=<画面名>` (対応表は Nikki/App/ScreenCatalog.swift)。自動ロックの無効化は `NIKKI_AUTOLOCK_DISABLED=1`

## ログイン方法

アカウント・ログイン機構なし。初回起動でオンボーディングが表示され、以降はローカルデータで動作する。

## 動作確認手段

- iOS Simulator の準備・使い分け (ローカル sim-boot / リモート simtunnel) は /ios-simulator skill Phase 1 を SSOT とする
- UI のインタラクティブ検証: /verify-ui-mobile-mcp (simtunnel 経由では `~/.claude/skills/ios-simulator/scripts/ios-wda.sh` も使える)
- XCUITest / スナップショット: /swiftui-uitest
- 課金 (購入・復元) の機械検証: NikkiTests/StoreKitConfigurationTests.swift (StoreKit Configuration = Nikki.storekit + SKTestSession)。iOS 26.5 simulator では既知の問題で skip される (iOS 26.2 以下で実行する)

### 再現が難しい操作の手順

- 日本語 UI の確認: simtunnel の runner Simulator は英語ロケールのため、設定アプリ > General > Language & Region から日本語へ切り替えて再起動する
- 自動ロックの発動: エディタを開いたまま無操作で待つ。QA でロックを避けたい場合は `NIKKI_AUTOLOCK_DISABLED=1` を付けて起動する (simtunnel 経由では起動引数を渡せないため、ロック項目の確認を先に済ませる)

## 実行ナレッジ

（まだ知見なし。run-qa が実行中の flaky・落とし穴の知見を蓄積する。運用ルールは ~/.claude/skills/setup-qa/references/qa-md-format.md を参照）

## 横断確認項目

## 1. 起動と言語

- [ ] **初回起動でオンボーディングが表示される**: インストール直後の起動で welcome 画面から始まり、完了後にホームへ到達する
  - 自動化: manual（初回状態はアプリ再インストールが必要で E2E 化していない）
- [ ] **英語 UI**: 端末言語 en で全画面 (ホーム・エディタ・ノート・ロック・テンプレート・テーマ・設定・ペイウォール・アーカイブ) の文言・日付表記が英語で表示される
  - 自動化: manual（表示言語の目視確認）
- [ ] **日本語 UI**: 端末言語 ja で同画面群の文言・日付表記が日本語で表示される
  - 自動化: manual（表示言語の目視確認）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **初回起動でオンボーディングが表示される**: インストール直後の起動で welcome 画面から始まり、完了後にホームへ到達する

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **英語 UI**: 端末言語 en で全画面 (ホーム・エディタ・ノート・ロック・テンプレート・テーマ・設定・ペイウォール・アーカイブ) の文言・日付表記が英語で表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **日本語 UI**: 端末言語 ja で同画面群の文言・日付表記が日本語で表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

## 機能別 QA.md

- [Home](Nikki/Features/Home/QA.md)
- [Editor](Nikki/Features/Editor/QA.md)
- [Notebooks](Nikki/Features/Notebooks/QA.md)
- [Templates](Nikki/Features/Templates/QA.md)
- [Lock](Nikki/Features/Lock/QA.md)
- [Onboarding](Nikki/Features/Onboarding/QA.md)
- [Theme](Nikki/Features/Theme/QA.md)
- [Paywall](Nikki/Features/Paywall/QA.md)
- [Settings](Nikki/Features/Settings/QA.md)
- [Archive](Nikki/Features/Archive/QA.md)
- [License](Nikki/Features/License/QA.md)

## QA 対象外

- AppStoreScreenshots: App Store スクリーンショット撮影用のモック画面。`#if DEBUG` の ScreenCatalog + 環境変数 `NIKKI_SCREEN` 経由でしか到達できず、リリースビルドに含まれない
