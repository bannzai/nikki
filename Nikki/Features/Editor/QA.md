---
feature: Editor
verification: mobile-mcp
last_verified_commit: 2f8b4ab97dc9113a82b5f76671c2de80fc1f55e5
last_verified_at: 2026-08-22
---

# Editor QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、実装の挙動をもとに項目を起こしている)
- 関連: 新規作成の流れ (日記を作ってからエディタで書き出しを決める) https://github.com/bannzai/nikki/issues/50
- 関連: ノートが2冊以上のときのエディタからの切り替え導線 https://github.com/bannzai/nikki/issues/58
- 関連: 設定「文字の大きさ」などの導線の配線 https://github.com/bannzai/nikki/issues/14
- 関連: 紙色テーマの実画面への適用 https://github.com/bannzai/nikki/issues/73
- 補足: 執筆中のキャレット・選択ツールバー・ブロックの並び替えは、DEBUG ビルドのデザインカタログでだけ表示できる静的な画面で、製品の導線からは到達しない。エディタで書ける実体は markdown の本文欄のため、装飾表示は QA 項目に含めない
- 補足: タイトル欄は廃止した (日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめをわかりにくくしていたため)。過去に入力されたタイトルは、その日記をエディタで開いたときに本文先頭の H1 見出しへ移して残す

## 1. 執筆と保存

- [x] **開いたらすぐ本文を書ける**: エディタにタイトル欄はなく、開くと本文欄にフォーカスが当たり、本文が空のときはプレースホルダ(「ここに本文を書く…」)が出る。本文は markdown の記法をそのままの文字として書ける
  - 自動化: manual（開いた直後のフォーカス・プレースホルダと入力の反映を実操作で確認する）
  - 2026-08-22 ローカル iOS Simulator で、新規日記(テンプレートなし)を開くとプレースホルダが出てキーボードが上がり、そのまま本文を入力できた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/771e0761-6dfa-4f52-9f55-abf3043875a9.png)
- [x] **過去のタイトルは本文の見出しへ移る**: タイトル付きの古い日記を開くと、タイトルが本文先頭の「# タイトル」見出しに移って表示され、内容は失われない
  - 自動化: NikkiTests/JournalEntryTests.swift (mergeTitleIntoBodyMarkdown) + manual（開いた直後の本文先頭を目視で確認する）
  - 2026-08-22 macOS (Debug、カタログの entryList) でタイトル「梅雨明け」の日記を開くと、本文先頭が「# 梅雨明け」になった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/c7fc112d-35c2-49af-aa6b-d6e2406d14f6.png)
- [x] **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る
  - 自動化: manual（日付の表記を目視で確認する）
  - 2026-08-22 ローカル iOS Simulator (日本語) で「8月22日 土曜日」
- [x] **閉じるとホームに反映される**: 左上の閉じるボタンでホームへ戻ると、その日記の行が本文の抜粋で表示される (タイトルのない日記は空のタイトル行を出さない)
  - 自動化: manual（画面をまたいだ反映を目視で確認する）
  - 2026-08-22 ローカル iOS Simulator で、閉じた直後のホームに本文の抜粋だけの行が出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/9501fb65-25a9-40fd-93c6-12ce758b1c53.png)
- [x] **アプリを終了しても書いた内容が残る**: 書いた直後にアプリを終了して起動し直し、同じ日記を開くと本文が残っている
  - 自動化: manual（アプリの終了と再起動をまたいだ永続化を実操作で確認する）
  - 2026-08-22 ローカル iOS Simulator で、terminate → 再起動後もホームに本文の抜粋が残っていた

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cc03d133-fc9a-4b76-bc95-039e85cc262c.jpg" width="320">

</details>

### **閉じるとホームに反映される**: 左上の閉じるボタンでホームへ戻ると、その日記の行が本文の抜粋で表示される

<details><summary>動作確認スクショ</summary>

（タイトル欄の廃止に伴い旧エビデンスを撤去。PR 作成時の run-qa で再取得する）

</details>

</details>

---

## 2. 文字の大きさの反映

- [x] **設定の文字の大きさが本文に効く**: 設定で文字の大きさを「小」「標準」「大」に変えると、エディタの本文の文字サイズがそれぞれ変わる
  - 自動化: manual（3段階の見た目の違いを目視で比較する）
  - 同じ本文で Standard / Large / Small を往復し、本文の文字サイズと折り返し位置が変わった (1 枚目 Large、2 枚目 Small)
  - (タイトル欄の廃止に伴い「タイトルの大きさは変わらない」項目は削除した)

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **設定の文字の大きさが本文に効く**: 設定で文字の大きさを「小」「標準」「大」に変えると、エディタの本文の文字サイズがそれぞれ変わる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0a274fa7-dff4-4a6b-85e5-0e3a5236cf14.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/ec5a95f2-e319-4cd5-bfdd-b5076f8e1079.jpg" width="320">

</details>

</details>

---

## 3. テンプレートの切り替え導線

(issue #82 で「ノート」から「テンプレート」へ用語と導線を変更。旧仕様〔2冊以上のときだけ「ノート」を表示〕の項目と記録は置き換えた)

- [x] **テンプレート一覧へ進める**: エディタの右上に「テンプレート」が出て(テンプレートが1件だけでも出る)、押すとテンプレート一覧が開く
  - 自動化: manual（画面上部の表示と遷移を実操作で確認する）
  - テンプレートが既定の1件だけの状態でも右上に「Template」が出て、押すと一覧が開いた
- [x] **選択中のテンプレートにチェックが付く**: テンプレート一覧で、いま日記に使われているテンプレート(新規日記なら既定の {{date}} テンプレート)にチェックが付いている
  - 自動化: manual（一覧のチェック表示を目視で確認する）
  - 新規日記では既定の「Blank page」にチェックが付き、「Morning notes」を選ぶとチェックが移った
- [x] **テンプレートを選ぶと書き出しが入れ替わる**: テンプレート一覧で別のテンプレートを選んでエディタへ戻ると、本文がそのテンプレートの書き出し全文(先頭の # 見出しも含む)に置き換わっている
  - 自動化: manual（戻った直後のエディタの中身を目視で確認する）+ NikkiTests/JournalEntryTests.swift (replace)
  - タイトル欄の廃止後は見出し行も本文に入る。2026-08-22 ローカル iOS Simulator で、新規日記の本文が「# 2026年8月22日」で始まることを確認 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/79caf481-a2b4-467a-8f7f-7cb9acaae2c5.png)

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **テンプレート一覧へ進める**: エディタの右上に「テンプレート」が出て(テンプレートが1件だけでも出る)、押すとテンプレート一覧が開く

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-22**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/8fae462b-1b92-4e2c-b25c-ac52f6041bb3.jpg" width="320">

</details>

### **選択中のテンプレートにチェックが付く**: テンプレート一覧で、いま日記に使われているテンプレートにチェックが付いている

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-22** (1件時: Blank page にチェック / 2件時: 選んだ Morning notes にチェック)
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/91e65c42-e0f5-4821-8797-54f4223b934b.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/3f50f191-a32c-4663-a0af-7315c69e01ab.jpg" width="320">

</details>

### **テンプレートを選ぶと書き出しが入れ替わる**: テンプレート一覧で別のテンプレートを選んでエディタへ戻ると、本文がそのテンプレートの書き出しに置き換わっている

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-22**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/0bb9b67b-595f-45f9-950b-0e810467de19.jpg" width="320">

</details>

</details>
