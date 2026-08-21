---
feature: Templates
verification: mobile-mcp
last_verified_commit: 96337de3d8717a2428e3fa4d4120727fab323a27
last_verified_at: 2026-08-21
---

# Templates QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、実装の挙動をもとに項目を起こしている)
- 関連: 書き出しをノート単位で持たせる方針 (テンプレート単体ではなくノートに紐づける) https://github.com/bannzai/nikki/issues/56
- 関連: ノートの書き出しを編集する導線 https://github.com/bannzai/nikki/issues/58
- 関連: 書き出しを選ぶタイミングを日記の作成後にする変更 https://github.com/bannzai/nikki/issues/50
- 補足: 変数を1つずつ入力してから日記を作るボトムシートは、DEBUG ビルドのデザインカタログでだけ表示できる画面で、製品の導線からは到達しない。実際の書き出しの差し込みは、日記の新規作成時とノートの選び直しの時に自動で行われる

## 1. 書き出しの差し込み

- [x] **今日の日付が差し込まれる**: 書き出しに {{date}} を含むノートで日記を作ると、その位置が日記の日付の表記に置き換わり、二重括弧が残らない
  - 自動化: manual（作成直後のエディタの中身を目視で確認する）
  - 書き出し `# {{date}}` の既定ノートで日記を作ると、タイトルが「August 21, 2026」になり二重括弧は残らなかった
- [x] **先頭の見出しがタイトルになる**: 書き出しの先頭が「# 」で始まる行のとき、その行がタイトル欄に入り、残りが本文欄に入る
  - 自動化: auto（NikkiTests/JournalEntryTests.swift）
  - `# {{date}}` で始まる書き出しの残り (Weather: ... 以降) が本文欄に入った
- [x] **書き出しのないノートは白紙で始まる**: 書き出しを空にしたノートで日記を作ると、タイトルも本文も空のまま開く
  - 自動化: manual（書き出しを空にしたノートを作って作成結果を目視で確認する）
  - 書き出しを空にしたノート「Blank start」を既定にして日記を作ると、タイトルは placeholder の「Title」、本文も空だった
- [x] **ノートを選び直しても差し込まれる**: エディタからノートを選び直すと、選んだノートの書き出しが同じように差し込まれ、{{date}} はその日記の日付になる
  - 自動化: manual（ノート切り替え後のエディタの中身を目視で確認する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **今日の日付が差し込まれる**: 書き出しに {{date}} を含むノートで日記を作ると、その位置が日記の日付の表記に置き換わり、二重括弧が残らない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cc03d133-fc9a-4b76-bc95-039e85cc262c.jpg" width="320">

</details>

### **先頭の見出しがタイトルになる**: 書き出しの先頭が「# 」で始まる行のとき、その行がタイトル欄に入り、残りが本文欄に入る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7ba25627-6005-4d7d-a892-9a4779d5d5ff.jpg" width="320">

</details>

### **書き出しのないノートは白紙で始まる**: 書き出しを空にしたノートで日記を作ると、タイトルも本文も空のまま開く

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/9da44aca-7342-4830-89d9-b5c7eedc994e.jpg" width="320">

</details>

### **ノートを選び直しても差し込まれる**: エディタからノートを選び直すと、選んだノートの書き出しが同じように差し込まれ、{{date}} はその日記の日付になる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7ba25627-6005-4d7d-a892-9a4779d5d5ff.jpg" width="320">

</details>

</details>

---

## 2. 未対応の変数の扱い

- [x] **日付以外の変数はそのまま残る**: 書き出しに {{weather}} のような変数を書いたノートで日記を作ると、その部分は二重括弧のまま本文に残り、上書きして書き換えられる
  - 自動化: auto（NikkiTests/TemplateVariableFieldTests.swift）
  - `{{weather}}` は二重括弧のまま本文に残り、その後ろに文字を追記して書き換えられた
- [x] **空白入りの変数も同じ扱いになる**: {{ weather }} のように括弧の内側に空白があっても、{{weather}} と同じ扱いになる
  - 自動化: auto（NikkiTests/TemplateVariableFieldTests.swift）
  - 同じ書き出しに置いた `{{ weather }}` も `{{weather}}` と同じくそのまま本文に残った

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **日付以外の変数はそのまま残る**: 書き出しに {{weather}} のような変数を書いたノートで日記を作ると、その部分は二重括弧のまま本文に残り、上書きして書き換えられる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/a579803e-ba9d-4570-be15-8f38457b2635.jpg" width="320">

</details>

### **空白入りの変数も同じ扱いになる**: {{ weather }} のように括弧の内側に空白があっても、{{weather}} と同じ扱いになる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7ba25627-6005-4d7d-a892-9a4779d5d5ff.jpg" width="320">

</details>

</details>
