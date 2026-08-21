---
feature: License
verification: mobile-mcp
last_verified_commit: 96337de3d8717a2428e3fa4d4120727fab323a27
last_verified_at: 2026-08-21
---

# License QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、コードの実挙動を正として項目を書いている)
- 関連: https://github.com/bannzai/nikki/pull/39 (OSS ライセンス一覧表示を追加)
- 関連: https://github.com/bannzai/nikki/issues/5 (公開前やることリスト: iOS / iPadOS / macOS)

## 1. ライセンス一覧

- [x] **設定から一覧を開ける**: 設定の「オープンソースライセンス」から一覧画面へ遷移し、戻るボタンで設定へ戻れる
  - 自動化: manual（画面遷移の目視確認）
  - 設定の該当行は英語ロケールでは「Open source licenses」と表示される
- [x] **同梱物がすべて並ぶ**: 依存ライブラリに加えて、同梱フォント Zen Kaku Gothic New が一覧に表示される
  - 自動化: manual（一覧の目視確認）
  - LicenseList / purchases-ios-spm / Zen Kaku Gothic New の 3 件が並ぶ

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **設定から一覧を開ける**: 設定の「オープンソースライセンス」から一覧画面へ遷移し、戻るボタンで設定へ戻れる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

設定から遷移した一覧 (1 枚目) と、戻るボタンで戻った設定画面 (2 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/878bc501-f1ba-4e21-a06b-d0c1d1a29374.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/14220d0d-c64d-4ac3-8a60-93a9585f5f94.jpg" width="320">

</details>

### **同梱物がすべて並ぶ**: 依存ライブラリに加えて、同梱フォント Zen Kaku Gothic New が一覧に表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/878bc501-f1ba-4e21-a06b-d0c1d1a29374.jpg" width="320">

</details>

</details>

---

## 2. ライセンス本文

- [x] **行をタップすると本文が開く**: 一覧の行をタップするとライブラリ名がタイトルの画面に遷移し、ライセンス本文が表示される
  - 自動化: manual（画面遷移の目視確認。自動ロックのジェスチャに行タップが奪われる不具合が起きうる箇所のため毎回確認する）
  - Zen Kaku Gothic New の行をタップして SIL Open Font License 1.1 の本文が表示された。行タップが自動ロックのジェスチャに奪われる事象は起きなかった
- [x] **本文から戻れる**: 戻るボタンで一覧へ戻り、別の行の本文も同様に開ける
  - 自動化: manual（画面遷移の目視確認）
  - Zen Kaku Gothic New の本文から戻った後、LicenseList の行をタップして MIT License の本文が開いた

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **行をタップすると本文が開く**: 一覧の行をタップするとライブラリ名がタイトルの画面に遷移し、ライセンス本文が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/b9c51bf9-4945-4631-9158-721d374c09b4.jpg" width="320">

</details>

### **本文から戻れる**: 戻るボタンで一覧へ戻り、別の行の本文も同様に開ける

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

戻った後に別の行 (LicenseList) を開いたところ。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cb9390e9-3444-44d4-b645-a12a0c5bc62d.jpg" width="320">

</details>

</details>
