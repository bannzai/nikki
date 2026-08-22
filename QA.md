---
feature: _root
verification: mobile-mcp
last_verified_commit: da31688b6eaa28f714d9c3c264de77687e05f228
last_verified_at: 2026-08-21
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

- 日本語 UI の確認: simtunnel の runner Simulator は英語ロケールのため、アプリを `-AppleLanguages (ja) -AppleLocale ja_JP` の起動引数付きで起動してアプリの表示言語だけを ja にする。WDA の `POST /session/<sid>/wda/apps/launch` に `arguments` を渡す (`ios-wda.sh launch` は bundleId しか送らないため直接 POST する)。設定アプリからの端末言語切り替えは使わない (下記「端末言語を切り替えるとセッションが落ちる」)
- 自動ロックの発動: エディタを開いたまま無操作で待つ。QA でロックを避けたい場合は `NIKKI_AUTOLOCK_DISABLED=1` を付けて起動する (simtunnel 経由では起動引数を渡せないため、ロック項目の確認を先に済ませる)

## 実行ナレッジ

### simtunnel の runner Simulator の外部到達性はセッションにより異なる

- 発見日: 2026-08-21
- 事象: あるセッションでは Simulator から App Store / RevenueCat / bannzai.github.io のいずれにも到達できず、ペイウォールは常に「Couldn't load prices.」+「Retry」になった (リンク先自体は手元から curl で HTTP 200 を確認済み)。同日の別セッションでは価格の取得に成功し US storefront の $ 価格が表示された。到達可否はセッション (runner) ごとに変わる
- 対処: ネットワーク依存の項目 (価格表示・Web リンク先の表示) は結果を鵜呑みにせず、失敗した場合は読み込み失敗パスの確認として記録する。価格・購入・復元の確定的な検証は StoreKit テスト (NikkiTests/StoreKitConfigurationTests.swift) の機械検証と TestFlight 後の人間確認に回す

### 端末言語を切り替えるとセッションが落ちる

- 発見日: 2026-08-21
- 事象: 設定アプリ > General > Language & Region で日本語を Primary にすると SpringBoard が再起動し、その巻き添えで WDA (XCUITest runner) が落ちる。session workflow は全 WDA の無応答を検知するとセッションを終了するため、セッションごと失われる (run 32457488962: `WDA :8100 を停止と判定` → `全 WDA が応答しなくなったためセッションを終了する`)
- 対処: 端末言語は切り替えず、アプリの起動引数 `-AppleLanguages (ja) -AppleLocale ja_JP` で表示言語を変える。アプリは `Bundle.main.preferredLocalizations` から表示言語 (Locale.appLanguage) を決めるため、文言だけでなく月名・曜日名・日付書式もこの経路で切り替わる。OS 側の UI (システムダイアログ・キーボード・App Store の通貨) は英語 / US のまま

### simtunnel のセッションには寿命がある

- 発見日: 2026-08-21
- 事象: 起動から約 1 時間 30 分でセッションの workflow run が終了し、WDA への接続が curl のタイムアウトで落ちる (`simtunnel status <名前>` が「tailnet に存在しない」になる)
- 対処: 長い QA バッチは寿命内に収まる単位へ分ける。落ちたら `gh run view <run id>` で終了時刻を確認し、セッションを起動し直す。起動し直すとアプリは再インストールされ、日記・テンプレート・設定はすべて初期状態に戻る

## 横断確認項目

## 1. 起動と言語

- [x] **初回起動でオンボーディングが表示される**: インストール直後の起動で welcome 画面から始まり、完了後にホームへ到達する
  - 自動化: manual（初回状態はアプリ再インストールが必要で E2E 化していない）
  - インストール直後の起動で welcome 画面から始まり、暗号化の説明 (1/2) → 生体認証の案内 (2/2) → ホームへ到達した
- [x] **英語 UI**: 端末言語 en で全画面 (ホーム・エディタ・ノート・ロック・テンプレート・テーマ・設定・ペイウォール・アーカイブ) の文言・日付表記が英語で表示される
  - 自動化: manual（表示言語の目視確認）
  - 英語ロケールの Simulator で全画面を確認済み (テーマ・ペイウォール・アーカイブ含む)。オンボーディング・ホーム (リスト / カレンダー / 検索)・エディタ・ノート・ロック・テンプレート・テーマ・設定・ペイウォール・アーカイブが英語で表示され、日付表記も「Friday, August 21」「August 2026」の英語表記だった
- [x] **日本語 UI**: アプリ表示言語 ja で同画面群の文言・日付表記が日本語で表示される
  - 自動化: manual（表示言語の目視確認）
  - アプリの表示言語を ja にした Simulator で、オンボーディング・ホーム (リスト / カレンダー / 検索)・エディタ・ノート・テンプレート・ロック・テーマ・設定・ペイウォール・アーカイブ・OSS ライセンスが日本語で表示された。日付表記も月見出し「2026年8月」・一覧の曜日「金曜」・エディタとカレンダーの「8月21日 金曜日」・カレンダーの曜日ヘッダ「日月火水木金土」と日本語表記だった。未翻訳の文言は見つからなかった

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **初回起動でオンボーディングが表示される**: インストール直後の起動で welcome 画面から始まり、完了後にホームへ到達する

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/a08eeaf3-5dca-497d-ad85-3f4f2f6a9706.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/eeb98caf-5136-4b80-96ac-8b4c7e5080ab.jpg" width="320">

</details>

### **英語 UI**: 端末言語 en で全画面 (ホーム・エディタ・ノート・ロック・テンプレート・テーマ・設定・ペイウォール・アーカイブ) の文言・日付表記が英語で表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

ホーム (1 枚目)、エディタ (2 枚目)、ロック (3 枚目)、テーマ (4 枚目)、ペイウォールの読み込み失敗パス (5 枚目)、アーカイブ一覧 (6 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/233d9709-6524-4a8d-9d39-b7de0aada7dc.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cc03d133-fc9a-4b76-bc95-039e85cc262c.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/f8bccb1f-faa0-416b-b957-a14e614464a2.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7f937d41-6344-42f5-be63-c50d9f59c834.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7640cf5b-6909-4dfb-9628-c1ae97eb630d.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7b0924ee-d8a5-4dc1-adf2-aebb841e1d99.jpg" width="320">

</details>

### **日本語 UI**: アプリ表示言語 ja で同画面群の文言・日付表記が日本語で表示される

<details><summary>動作確認スクショ</summary>

確認方法: 起動引数 `-AppleLanguages (ja)` によるアプリプロセスの言語切り替え (システム言語の切り替えは simtunnel では respring で WDA が落ちるため不可)

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/8ff1eb81-ee15-4f63-bc1e-4bebf03765cf.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/eedf09aa-a1cd-4d62-8aa8-071db84bfb78.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/818bf794-d67e-47d8-af62-0592fcebf8b0.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0f2d687e-15c4-4d01-8889-6dd9d5729d04.jpg" width="320">

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
