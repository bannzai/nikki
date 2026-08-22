---
feature: Onboarding
verification: mobile-mcp
last_verified_commit: 2f8b4ab97dc9113a82b5f76671c2de80fc1f55e5
last_verified_at: 2026-08-22
---

# Onboarding QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、コードの実挙動を正として項目を書いている)
- 関連: https://github.com/bannzai/nikki/pull/10 (デザイン引き継ぎ書からの画面実装)
- 関連: https://github.com/bannzai/nikki/pull/34 (ようこそ画面のロゴマークを日記帳アイコンに置き換え)

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
- [x] **パスキー登録ボタンは出ない**: パスキーは未実装のため「パスキーを登録する」ボタンを撤去した (実装時に戻す)。最終ステップのボタンは生体認証を有効にするものだけが出る
  - 自動化: manual（最終ステップの表示を目視で確認する）
  - 2026-08-22 macOS (Debug、カタログの biometric) でボタンが1つだけなことを確認

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
