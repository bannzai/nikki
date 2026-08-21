---
feature: Editor
verification: mobile-mcp
last_verified_commit: 96337de3d8717a2428e3fa4d4120727fab323a27
last_verified_at: 2026-08-21
---

# Editor QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、実装の挙動をもとに項目を起こしている)
- 関連: 新規作成の流れ (日記を作ってからエディタで書き出しを決める) https://github.com/bannzai/nikki/issues/50
- 関連: ノートが2冊以上のときのエディタからの切り替え導線 https://github.com/bannzai/nikki/issues/58
- 関連: 設定「文字の大きさ」などの導線の配線 https://github.com/bannzai/nikki/issues/14
- 関連: 紙色テーマの実画面への適用 https://github.com/bannzai/nikki/issues/73
- 補足: 執筆中のキャレット・選択ツールバー・ブロックの並び替えは、DEBUG ビルドのデザインカタログでだけ表示できる静的な画面で、製品の導線からは到達しない。エディタで書ける実体はタイトル欄と markdown の本文欄のため、装飾表示は QA 項目に含めない

## 1. 執筆と保存

- [x] **タイトルと本文を書ける**: タイトル欄と本文欄にそれぞれ入力でき、本文は markdown の記法をそのままの文字として書ける
  - 自動化: manual（キーボード入力と表示の反映を実操作で確認する）
  - 本文に `**bold**` `_italic_` を入力しても、装飾されずそのままの文字として残った
- [x] **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る
  - 自動化: manual（日付の表記を目視で確認する）
  - 英語表示で「Friday, August 21」(確認日 2026-08-21 の UTC 日付)
- [x] **閉じるとホームに反映される**: 左上の閉じるボタンでホームへ戻ると、その日記の行が書いたタイトルと抜粋で表示される
  - 自動化: manual（画面をまたいだ反映を目視で確認する）
- [x] **アプリを終了しても書いた内容が残る**: 書いた直後にアプリを終了して起動し直し、同じ日記を開くとタイトル・本文が残っている
  - 自動化: manual（アプリの終了と再起動をまたいだ永続化を実操作で確認する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **タイトルと本文を書ける**: タイトル欄と本文欄にそれぞれ入力でき、本文は markdown の記法をそのままの文字として書ける

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/93f64265-702f-4c92-b062-9017129f074d.jpg" width="320">

</details>

### **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cc03d133-fc9a-4b76-bc95-039e85cc262c.jpg" width="320">

</details>

### **閉じるとホームに反映される**: 左上の閉じるボタンでホームへ戻ると、その日記の行が書いたタイトルと抜粋で表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/8ecd5908-24a7-4c20-9604-fd06da8e44e5.jpg" width="320">

</details>

### **アプリを終了しても書いた内容が残る**: 書いた直後にアプリを終了して起動し直し、同じ日記を開くとタイトル・本文が残っている

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/b63052a1-c4bd-4d31-a991-bca303949291.jpg" width="320">

</details>

</details>

---

## 2. 文字の大きさの反映

- [x] **設定の文字の大きさが本文に効く**: 設定で文字の大きさを「小」「標準」「大」に変えると、エディタの本文の文字サイズがそれぞれ変わる
  - 自動化: manual（3段階の見た目の違いを目視で比較する）
  - 同じ本文で Standard / Large / Small を往復し、本文の文字サイズと折り返し位置が変わった (1 枚目 Large、2 枚目 Small)
- [x] **タイトルの大きさは変わらない**: 文字の大きさを変えてもタイトル欄の文字サイズは変わらない
  - 自動化: manual（本文との対比を目視で確認する）
  - Large / Small のどちらでもタイトル「August 21, 2026 river walk」の文字サイズと折り返しは同じだった

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **設定の文字の大きさが本文に効く**: 設定で文字の大きさを「小」「標準」「大」に変えると、エディタの本文の文字サイズがそれぞれ変わる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0a274fa7-dff4-4a6b-85e5-0e3a5236cf14.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/ec5a95f2-e319-4cd5-bfdd-b5076f8e1079.jpg" width="320">

</details>

### **タイトルの大きさは変わらない**: 文字の大きさを変えてもタイトル欄の文字サイズは変わらない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/ec5a95f2-e319-4cd5-bfdd-b5076f8e1079.jpg" width="320">

</details>

</details>

---

## 3. ノートの切り替え導線

- [x] **ノートが1冊のときは何も出ない**: ノートが1冊しかない間は、エディタの右上に「ノート」が出ない
  - 自動化: manual（ノートの冊数を変えて画面上部を目視で確認する）
- [x] **2冊以上でノート一覧へ進める**: ノートを2冊以上にすると右上に「ノート」が出て、押すとノート一覧が開く
  - 自動化: manual（ノート作成後のエディタ再表示を実操作で確認する）
- [x] **ノートを選ぶと書き出しが入れ替わる**: ノート一覧でノートを選んでエディタへ戻ると、本文がそのノートの書き出しに置き換わっている
  - 自動化: manual（戻った直後のエディタの中身を目視で確認する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ノートが1冊のときは何も出ない**: ノートが1冊しかない間は、エディタの右上に「ノート」が出ない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/f6f721d7-5f28-4513-a3f3-a3487d881ada.jpg" width="320">

</details>

### **2冊以上でノート一覧へ進める**: ノートを2冊以上にすると右上に「ノート」が出て、押すとノート一覧が開く

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7bd9516b-f879-4587-a63b-4e18ddcc1a59.jpg" width="320">

</details>

### **ノートを選ぶと書き出しが入れ替わる**: ノート一覧でノートを選んでエディタへ戻ると、本文がそのノートの書き出しに置き換わっている

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7ba25627-6005-4d7d-a892-9a4779d5d5ff.jpg" width="320">

</details>

</details>
