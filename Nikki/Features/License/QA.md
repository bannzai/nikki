---
feature: License
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# License QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、コードの実挙動を正として項目を書いている)
- 関連: https://github.com/bannzai/nikki/pull/39 (OSS ライセンス一覧表示を追加)
- 関連: https://github.com/bannzai/nikki/issues/5 (公開前やることリスト: iOS / iPadOS / macOS)

## 1. ライセンス一覧

- [ ] **設定から一覧を開ける**: 設定の「オープンソースライセンス」から一覧画面へ遷移し、戻るボタンで設定へ戻れる
  - 自動化: manual（画面遷移の目視確認）
- [ ] **同梱物がすべて並ぶ**: 依存ライブラリに加えて、同梱フォント Zen Kaku Gothic New が一覧に表示される
  - 自動化: manual（一覧の目視確認）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **設定から一覧を開ける**: 設定の「オープンソースライセンス」から一覧画面へ遷移し、戻るボタンで設定へ戻れる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **同梱物がすべて並ぶ**: 依存ライブラリに加えて、同梱フォント Zen Kaku Gothic New が一覧に表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 2. ライセンス本文

- [ ] **行をタップすると本文が開く**: 一覧の行をタップするとライブラリ名がタイトルの画面に遷移し、ライセンス本文が表示される
  - 自動化: manual（画面遷移の目視確認。自動ロックのジェスチャに行タップが奪われる不具合が起きうる箇所のため毎回確認する）
- [ ] **本文から戻れる**: 戻るボタンで一覧へ戻り、別の行の本文も同様に開ける
  - 自動化: manual（画面遷移の目視確認）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **行をタップすると本文が開く**: 一覧の行をタップするとライブラリ名がタイトルの画面に遷移し、ライセンス本文が表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **本文から戻れる**: 戻るボタンで一覧へ戻り、別の行の本文も同様に開ける

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>
