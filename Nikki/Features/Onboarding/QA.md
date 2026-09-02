---
feature: Onboarding
verification: mobile-mcp
last_verified_commit: d9a0668810533553706dff848ecd52d427c13c22
last_verified_at: 2026-09-02
---

# Onboarding QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、コードの実挙動を正として項目を書いている)
- 関連: https://github.com/bannzai/nikki/pull/10 (デザイン引き継ぎ書からの画面実装)
- 関連: https://github.com/bannzai/nikki/pull/34 (ようこそ画面のロゴマークを日記帳アイコンに置き換え)
- 関連: https://github.com/bannzai/nikki/issues/84 (パスキーでの登録・認証の実装)

## 1. 初回起動のステップ進行

- [x] **ようこそ画面から始まる**: 初回起動でロゴマークと「書いたものはあなただけが読める」旨のキャッチコピー、「はじめる」ボタンが表示される
  - 自動化: manual（初回状態を作るにはアプリの再インストールが必要で E2E 化していない）
- [x] **暗号化の説明へ進む**: 「はじめる」で、書く / 鍵をかける / 読めるのはあなただけ の3項目とステップ表示 (1/2) がある画面に進む
  - 自動化: manual（初回起動フローの目視確認）
- [x] **生体認証の案内へ進む**: 「次へ」で、ステップ表示 (2/2) と Face ID 端末に合った図像・見出し・ボタン文言の画面に進む
  - 自動化: manual（端末ごとの生体認証構成に依存する表示の目視確認）
  - iOS Simulator (iPhone / Face ID 対応機) では Face ID の図像・見出し「From now on, just your face.」・ボタン「Enable Face ID」が出た
- [ ] **Touch ID / パスコード端末の生体認証案内**: Touch ID 端末では Touch ID の図像・文言、生体認証を使えない端末ではパスコード・パスワードの文言に切り替わる
  - 自動化: manual（端末ごとの生体認証構成に依存する表示の目視確認）
  - ⏭️ スキップ: Touch ID 搭載・生体認証なしの構成は iOS Simulator で用意できない。Touch ID 実機またはローカル macOS ビルドでの確認に回す
- [x] **完了してホームへ到達する**: 生体認証を有効にするボタンを押すとオンボーディングが終わり、日記一覧が表示される
  - 自動化: manual（初回起動フローの目視確認）
  - 「Enable Face ID」で完了しホームへ到達することを確認した
- [x] **パスキー登録ボタンが出る**: 最終ステップに、生体認証を有効にする主ボタンの下に枠線の「パスキーを登録する」ボタンが出る (issue #84)
  - 自動化: manual（最終ステップの表示を目視で確認する）
  - 2026-09-02 iOS (simtunnel、カタログの biometric) で「Enable Face ID」の下に枠線の「Register a passkey」、macOS (Debug、カタログの biometric) で「Touch ID を有効にする」の下に「パスキーを登録する」が出た
- [ ] **パスキーを登録して完了する**: 「パスキーを登録する」で OS のパスキー登録が始まり、登録できるとオンボーディングが終わってホームへ到達する。キャンセルするとこの画面に留まる
  - 自動化: manual（OS のパスキー登録ダイアログを伴うため）
  - ⏭️ スキップ: OS のパスキー登録は relying party (bannzai.github.io) の apple-app-site-association の配信 ( https://github.com/bannzai/bannzai.github.io/pull/4 ) と署名済みビルドが前提で、simtunnel の署名なし Simulator ビルドと未署名の macOS Debug ビルドでは登録に進めない。AASA 配信後に実機 (または署名済みビルド) で確認する

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ようこそ画面から始まる**: 初回起動でロゴマークと「書いたものはあなただけが読める」旨のキャッチコピー、「はじめる」ボタンが表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/a08eeaf3-5dca-497d-ad85-3f4f2f6a9706.jpg" width="320">

</details>

### **暗号化の説明へ進む**: 「はじめる」で、書く / 鍵をかける / 読めるのはあなただけ の3項目とステップ表示 (1/2) がある画面に進む

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0902eb93-6cc1-41a6-8f3c-cc7b108b7930.jpg" width="320">

</details>

### **生体認証の案内へ進む**: 「次へ」で、ステップ表示 (2/2) と Face ID 端末に合った図像・見出し・ボタン文言の画面に進む

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/e3838ba7-f3ad-43b3-bc04-816861f79cef.jpg" width="320">

</details>

### **完了してホームへ到達する**: 生体認証を有効にするボタンを押すとオンボーディングが終わり、日記一覧が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/eeb98caf-5136-4b80-96ac-8b4c7e5080ab.jpg" width="320">

</details>

### **Touch ID / パスコード端末の生体認証案内**: Touch ID 端末では Touch ID の図像・文言、生体認証を使えない端末ではパスコード・パスワードの文言に切り替わる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **パスキー登録ボタンが出る**: 最終ステップに、生体認証を有効にする主ボタンの下に枠線の「パスキーを登録する」ボタンが出る (issue #84)

<details><summary>動作確認スクショ</summary>

**確認日: 2026-09-02**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260902/11ba36bd-b2cb-4625-be88-230fd0689d70.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260902/d758a662-bfff-4575-947d-346f93ac7af8.png" width="320">

</details>

### **パスキーを登録して完了する**: 「パスキーを登録する」で OS のパスキー登録が始まり、登録できるとオンボーディングが終わってホームへ到達する。キャンセルするとこの画面に留まる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 2. 再起動時の扱い

- [x] **2回目以降は表示されない**: オンボーディング完了後にアプリを終了して起動し直すと、オンボーディングを経ずに日記一覧が表示される
  - 自動化: manual（アプリの終了・再起動を伴う確認のため）
- [x] **途中で終了しても続きから再開する**: 暗号化の説明まで進んだ状態でアプリを終了して起動し直すと、ようこそ画面に戻らず暗号化の説明から再開する
  - 自動化: manual（アプリの終了・再起動を伴う確認のため）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **2回目以降は表示されない**: オンボーディング完了後にアプリを終了して起動し直すと、オンボーディングを経ずに日記一覧が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cc76e87b-d872-46e8-b62a-c3749acd5b98.jpg" width="320">

</details>

### **途中で終了しても続きから再開する**: 暗号化の説明まで進んだ状態でアプリを終了して起動し直すと、ようこそ画面に戻らず暗号化の説明から再開する

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/4d949864-762b-4217-879a-b01dc070a674.jpg" width="320">

</details>

</details>
