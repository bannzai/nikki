---
feature: Editor
verification: mobile-mcp
last_verified_commit: 855091612c23cb04624a1c144f5b6c6ea50097e9
last_verified_at: 2026-08-25
---

# Editor QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、実装の挙動をもとに項目を起こしている)
- 関連: 新規作成の流れ (日記を作ってからエディタで書き出しを決める) https://github.com/bannzai/nikki/issues/50
- 関連: ノートが2冊以上のときのエディタからの切り替え導線 https://github.com/bannzai/nikki/issues/58
- 関連: 設定「文字の大きさ」などの導線の配線 https://github.com/bannzai/nikki/issues/14
- 関連: 紙色テーマの実画面への適用 https://github.com/bannzai/nikki/issues/73
- 関連: markdown ブロックの装飾表示 (見出し・チェックリスト・画像・details) https://github.com/bannzai/nikki/issues/88
- 補足: 選択ツールバー(1j)・ブロックの並び替え(1k)は、DEBUG ビルドのデザインカタログでだけ表示できる静的な画面で、製品の導線からは到達しない。エディタ本文のブロック装飾表示は issue #88 で実装済みで、「4. ブロックの装飾表示と操作」で QA する
- 補足: タイトル欄は廃止した (日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめをわかりにくくしていたため)。過去に入力されたタイトルは、その日記をエディタで開いたときに本文先頭の H1 見出しへ移して残す

## 1. 執筆と保存

- [x] **開いたらすぐ本文を書ける**: エディタにタイトル欄はなく、開くと本文末尾の空の段落にフォーカスが当たる(日記の続きを書く位置。macOS の入力欄はフォーカスで本文を全選択するため、文字のあるブロックには当てない)。本文が空のときはプレースホルダ(「ここに本文を書く…」)が出る
  - 自動化: manual（開いた直後のフォーカス・プレースホルダと入力の反映を実操作で確認する）
  - 2026-08-22 (旧 TextEditor 実装) ローカル iOS Simulator で、新規日記(テンプレートなし)を開くとプレースホルダが出てキーボードが上がり、そのまま本文を入力できた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/771e0761-6dfa-4f52-9f55-abf3043875a9.png)
  - 2026-08-23 ブロック装飾表示 (issue #88) 後、simtunnel リモート iOS Simulator で、新規日記を開くとキーボードが上がり末尾の空の段落にキャレットが出て、そのまま本文を入力できた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/9bcea095-549e-42b7-9c5b-707187e83468.jpg)。本文が空の日記のプレースホルダはブロック実装後は未検証 (新規日記は既定テンプレートの見出しから始まり本文が空にならないため。表示条件は旧実装と同じ「本文が完全に空の時のみ」)
- [x] **過去のタイトルは本文の見出しへ移る**: タイトル付きの古い日記を開くと、タイトルが本文先頭の「# タイトル」見出しに移って表示され、内容は失われない
  - 自動化: NikkiTests/JournalEntryTests.swift (mergeTitleIntoBodyMarkdown) + manual（開いた直後の本文先頭を目視で確認する）
  - 2026-08-22 macOS (Debug、カタログの entryList) でタイトル「梅雨明け」の日記を開くと、本文先頭が「# 梅雨明け」になった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/c7fc112d-35c2-49af-aa6b-d6e2406d14f6.png)
- [x] **日本語入力の変換中テキストが消えない**: 日本語 IME でひらがなを続けて入力しても、変換中 (未確定) のテキストが入力途中で消えない。確定した文字も残る (issue #86 の再発確認)
  - 自動化: manual（IME の変換中状態はプログラム入力では作れず、実キーボード入力での確認が必要なため）
  - 2026-08-22 macOS (Debug) で日本語入力ソースからローマ字で「kakikukeko」を 1.2 秒間隔で入力し、変換中の「かきくけこ」が全文字保持された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/d7071786-3b64-41ab-921f-8d0647cb7072.png)。修正前ビルドでは同じ操作で変換中テキストが全て消えることを再現済み (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/86f3c71e-9c30-487d-814b-a4960896f6dc.png)
  - 2026-08-22 ローカル iOS Simulator のかなキーボードで「かたなはま」を 2 秒前後の間隔で入力し、変換中テキストが全文字保持された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/980a7c16-1a28-459f-b7f6-410fc16cb34e.png)。ローカル simulator を使ったのは、修正前後のローカルビルドを `xcrun simctl install` で差し替えて比較し、日本語キーボードの有効化 (`simctl spawn defaults write`) も必要な、ローカルの simctl を伴う手順のため (ios-simulator skill Phase 1 のローカルに倒す条件に該当)
  - 2026-08-23 ブロック装飾表示 (issue #88) 後、macOS (Debug) で日本語入力ソースから「kakikuke」を入力し、変換中の「かきくけ」が下線付きで保持され、確定した文字が末尾の段落に入った (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/18bc6743-65dc-43ff-8131-c573758baf6b.png)。iOS のかなキーボードでの再確認は未実施 (編集の書き込み先は @State のブロック列のままで、@Model への書き込みは旧実装と同じ編集の切れ目のみ)
- [x] **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る
  - 自動化: manual（日付の表記を目視で確認する）
  - 2026-08-22 ローカル iOS Simulator (日本語) で「8月22日 土曜日」
- [x] **閉じるとホームに反映される**: 左上の閉じるボタンでホームへ戻ると、その日記の行が本文の抜粋で表示される (タイトルのない日記は空のタイトル行を出さない)
  - 自動化: manual（画面をまたいだ反映を目視で確認する）
  - 2026-08-22 ローカル iOS Simulator で、閉じた直後のホームに本文の抜粋だけの行が出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/9501fb65-25a9-40fd-93c6-12ce758b1c53.png)
  - 2026-08-22 編集中の本文を @State に持つ変更 (issue #86) 後も、iOS で「かたなはま」を確定して閉じた直後のホームに抜粋が出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/961222cf-0103-465c-809d-3d78fd7773fb.png)。macOS でも同様に反映された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/91031702-4f76-4e4b-9dce-91d7e98254cb.png)
- [x] **アプリを終了しても書いた内容が残る**: 書いた直後にアプリを終了して起動し直し、同じ日記を開くと本文が残っている
  - 自動化: manual（アプリの終了と再起動をまたいだ永続化を実操作で確認する）
  - 2026-08-22 ローカル iOS Simulator で、terminate → 再起動後もホームに本文の抜粋が残っていた
  - 2026-08-22 macOS (Debug) で、エディタに「cmdq test body」を入力して開いたまま ⌘Q → 再起動すると、ホームに本文が残っていた (エディタ表示中のアプリ終了は willTerminateNotification 経由の書き戻し。 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/a5040e50-02ff-4b9e-a64b-f05285e8dc95.png)

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

---

## 4. ブロックの装飾表示と操作

(issue #88 でエディタ本文をブロック単位の装飾表示に変更。エビデンスの日付はすべて 2026-08-23、iOS は simtunnel リモート iOS Simulator、macOS は Debug ビルド + カタログの entryList)

- [x] **markdown ブロックが装飾表示される**: 本文の見出し(#〜###)・チェックリスト(- [ ] / - [x])・画像(&lt;img&gt;)・折りたたみ(&lt;details&gt;)が、生の記法ではなく装飾された見た目(見出しの書体 / チェックボックス / 45°ストライプのプレースホルダ / 枠線カード)で表示される
  - 自動化: NikkiTests/BlockMarkdownTests.swift (パース) + manual（描画は目視で確認する）
  - macOS でサンプル日記の全ブロック種が装飾表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/5836c8d8-e0bf-47f4-97de-b294d3478467.png)
  - iOS で入力した記法が再表示時に img プレースホルダ・details カードとして表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/1e088d02-1628-4c23-bcd8-2f0aeb5d8bb5.jpg)
  - 2026-08-25 D&D 並び替えの revert (issue #105、コミット 8550916) 後に再確認。macOS (署名なし Debug + カタログ entryList) で全ブロック種がハンドル無しで導入前の書き出し位置に表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/d58d19f8-29d4-4ee1-b14e-deee992d71fc.png)。iOS (simtunnel リモート iOS Simulator) でも見出し・段落・チェックリストがハンドル無しで表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/c9e7dddd-6809-4f75-807b-d3fb53749289.jpg)
- [x] **↑↓ でキャレットが行の間を移動できる**: 折り返しのある段落で、↑↓ キーがキャレットを表示行の間で移動させる (issue #105 の revert で回復した挙動。D&D 導入中は移動できなかった)
  - 自動化: manual（ハードウェアキーボードの矢印キー入力とキャレット位置の目視確認が必要なため）
  - 2026-08-25 macOS (署名なし Debug) で、2行に折り返した段落の1行目にキャレットを置き (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/e57358db-9593-4dbe-8749-170961569383.png)、↓ で2行目末尾へ移動してそこに「ok」が入力され (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/4c8505a4-6038-48f9-9c09-9ead541bb78e.png)、↑ で1行目中央へ戻ってそこに「up」が入力された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/9161ac54-972b-4414-a92b-d855b02106df.png)
  - iOS はハードウェアキーボード接続時のみ該当する操作のため未検証 (ソフトウェアキーボードに矢印キーが無い)
- [x] **チェックのタップで完了が切り替わり保存される**: チェックボックスをタップすると即座に完了(墨地+白チェック、打ち消し線+灰) / 未完了が切り替わり、閉じて開き直しても状態が残る(markdown へ - [x] / - [ ] として書き戻される)
  - 自動化: NikkiTests/BlockEditingTests.swift (togglesChecklistItemDone) + manual
  - macOS で切り替えの即時反映 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/8f338314-392c-438e-aaa1-5332fddbf051.png) と開き直し後の保持 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/abecee74-a207-47a6-bd05-46d845f44f64.png) を確認
  - iOS でタップした項目が打ち消し線+灰になり (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/c8ea81ef-7d0f-4f88-92e7-03a6a209bd29.jpg)、開き直しても保持された
- [x] **details のタップで開閉し保存される**: details カードをタップするとシェブロンが ▶ / ▼ に切り替わり、markdown の open 属性として書き戻される (open が先頭以外の位置の属性でも重複させずに付け外しされる)
  - 自動化: NikkiTests/BlockEditingTests.swift (togglesDetailsOpen / togglesDetailsOpenAttributeAtAnyPosition) + manual
  - macOS (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/5a427ab6-64d3-470f-8adc-daa393ade4a5.png) と iOS (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/d5c5ffe1-725c-4eeb-b920-916e7f3b8410.jpg) で開閉を確認
  - レビュー対応 (details/img のタグ名境界・open 属性の大文字と引用符対応・アクセシビリティ表示) 後の最終ツリー (9dbb3c0) でも macOS で再確認: タップで ▶→▼ (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260824/d3037137-cb83-4ab5-bbad-9d453c6a1eab.png)、閉じて開き直しても ▼ のまま (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260824/931f02e7-0d33-49cd-92e5-d6c640a2b8fc.png)、再タップで ▶ に戻った (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260824/48d35617-01ff-48c0-a355-f3611a9ec13d.png)。パーサの変更点自体は BlockMarkdownTests / BlockEditingTests (計 71 件 pass) で担保し、iOS は同一コードのため再スクリーンショットは省略
- [x] **記法を打ち終えるとその場でブロックに変わる**: 段落に「- [ ] 」「- [x] 」「# 」〜「### 」を打ち終えると、その場でチェックリスト・見出しに変わり、続きを入力できる位置へフォーカスが移る
  - 自動化: NikkiTests/BlockEditingTests.swift (convertsMarkdownPrefix / movesFieldAfterConversion) + manual
  - iOS で「- [ ] 」がチェックボックスに変わり (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/a3b0bc42-6e45-4e4b-9b7f-79ab1b8573da.jpg)、「# 」が見出しに変わって続きが見出しの書体で入力できた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/15a62765-7011-48d7-b941-362fe5961236.jpg)
  - macOS でも「- [ ] 」がチェックボックスに変わり、続けて打った文字がそのまま項目の本文に入った (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/0dd538b2-b494-4f24-8180-124cfbd6ee28.png)。初回実装では変換直後にフォーカスが失われて入力が消えており、フォーカス移動を次の runloop に遅らせて解消した
  - フォーカス移動の遅延後、iOS でも変換 → 続きの入力 → Return での項目追加が変わらず動くことを再確認した (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/2f58680e-c00c-49f6-8068-ec8e563474c2.jpg)
  - macOS で「- [x] 」からの変換直後も入力欄が出て、続けて項目名を入力できた (完了項目は本文が空・入力中の間は TextField のまま出す。 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260824/cad3d43e-eee5-4797-bb6a-eea0f36e2f4e.png)
- [x] **中間保存の後に元へ戻した編集も保存される**: 本文を編集してアプリをバックグラウンドへ移した後 (中間保存)、開いた時点の内容へ手で戻して閉じると、戻した状態が保存される
  - 自動化: manual（バックグラウンド移行をまたいだ書き戻しの基準更新を実操作で確認する）
  - macOS で「XTEST」を入力 → 他アプリへ切り替え (中間保存) → 戻って削除 → 閉じて開き直すと、XTEST が残っていない元の内容に戻っていた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260824/9bef589d-e285-427e-840f-853d62b04d91.png)
- [x] **Return でブロック・項目が増える**: 段落・見出しで Return すると次の段落へ移り、チェックリスト項目で Return すると次の項目が増え、空の項目で Return するとリストから抜けて段落に戻る
  - 自動化: NikkiTests/BlockEditingTests.swift (splitsBlockByNewline / insertsChecklistItemAfterItem / exitsChecklistFromEmptyItem / splitsChecklistAtEmptyMiddleItem) + manual
  - iOS で段落→チェックリスト2項目→空項目で脱出→見出し、の一連の入力ができた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/15a62765-7011-48d7-b941-362fe5961236.jpg)
  - macOS で段落の Return で次の段落へ移れた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/f8ffdd1d-2de8-42a2-a280-1baeaf2c795b.png)。チェックリスト項目の Return で次の項目が増えた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/0dd538b2-b494-4f24-8180-124cfbd6ee28.png)
- [x] **チェックボックスはボックスの外側少しまでタップできる**: 見た目は 19pt のまま、ボックスの周囲までタップの当たり判定が広がっている
  - 自動化: manual（ボックスの外側をクリック・タップして切り替わることを確認する）
  - macOS でボックス右外側のクリックで切り替わった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/0b9cb9dd-c8ed-46fb-a792-9fec7a75b57e.png)
  - iOS でもボックス右外側のタップで切り替わった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260823/5c0da118-591d-4f79-8ad3-72b748e826cc.jpg)
- 補足 (既知の制限):
  - img・details ブロックはエディタから削除できない (テキストの編集経路が無いため)。削除導線は別途扱う
  - 完了したチェック項目の文字は編集できない (チェックを外してから編集する)。入力欄 (TextField) は打ち消し線を描画できないため、完了項目は静的な文字で描画している
  - 改行を含まない貼り付け (1行だけの記法) は、その場では変わらず、次に開いたときにブロックとして表示される (複数行の貼り付けは issue #100 でその場でブロックに変わる。「5. コピーと貼り付け」参照)
  - macOS で行の途中で Return しても、カーソル以降は次のブロックへ移らない (Return が onSubmit として届き、SwiftUI の TextField からキャレット位置を取得できないため末尾扱いになる)。iOS は改行がキャレット位置に入るため、その位置でブロックが分かれる
  - インデントされた記法の行 (「    - [ ] 」等) はブロックにせず段落のまま表示・保存する (ブロックに変換すると書き戻しでインデントが失われるため)
  - details カードの VoiceOver は開閉状態を accessibilityValue で読み上げる実装を入れたが、実機の読み上げは未検証

---

## 5. コピーと貼り付け

(issue #100 でブロックのコピーと markdown 貼り付けの復元を追加。エビデンスは 2026-08-25、macOS は署名なし Debug ビルドを直接起動、iOS は simtunnel リモート iOS Simulator で確認)

- [x] **ブロックのメニューからコピーできる**: ブロックの長押し (iOS) / 右クリック (macOS) で「コピー」「すべてコピー」のメニューが出て、コピーでそのブロック、すべてコピーで本文全体 (空のブロックを除く) がペーストボードに入る
  - 自動化: manual（メニュー表示とコピー実行を実操作で確認する）
  - macOS でチェックボックス上の右クリックでメニューが出て (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/90b89be5-eda6-4fc8-9643-57072dc03ed2.png)、コピーで `- [ ] 麦茶のパック\n- [x] 蚊取り線香`、すべてコピーで本文全体の markdown が pbpaste で取れた
  - 2026-08-25 D&D 並び替えの revert (issue #105、コミット 8550916) 後に iOS (simtunnel) で再確認。チェックリスト項目の長押しで Copy All を含むメニューが表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/3f25882b-edd7-4d98-9edf-b7041415399a.jpg)
  - iOS でチェックリストの長押しで Copy / Copy All のメニューが出て (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/48c97ba3-4a19-4c9e-80fc-7ef5e0f6b37f.jpg)、Copy で `- [ ] Barley tea\n- [x] Mosquito coil`、Copy All で本文全体の markdown が WDA getPasteboard で取れた。iOS は見出し・段落・空の段落の行でも長押しでメニューが出る (macOS と違い OS のテキストメニューに取られない)。テキスト編集の吹き出し (Paste 等) はタップで別途出て共存する (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/924e6e39-95d2-4e32-927f-37ffa7db5c08.jpg)。長押しメニュー表示後もチェックボックスのタップ切り替えは正常 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/15c3ae9f-893a-4cea-96a5-863e80858583.jpg)
  - 補足: macOS の見出し・段落は入力欄が行の全幅を占め、その上の右クリックは OS のテキスト編集メニューになる (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/86c9276d-29e3-4661-9b5a-853cff0b6fdf.png)。ドラッグハンドル経由の単体コピー導線は issue #105 の D&D revert でハンドルごと無くなったため、macOS の見出し・段落は単体コピーに到達できない (本文全体は余白の「すべてコピー」で到達できる。下の既知の制限を参照)
- [x] **本文の余白のメニューからすべてコピーできる**: ブロックの外 (本文の下の余白) の長押し / 右クリックで「すべてコピー」が出る。テキストのブロックしか無い日記でも macOS でコピーに到達できる
  - 自動化: manual
  - macOS で余白の右クリックにメニューが出て (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/932ffb6c-3e71-49d6-a818-fe25adb00178.png)、見出しだけの日記の markdown (`# 2026年8月25日`) が pbpaste で取れた
- [x] **コピーは markdown とリッチテキストの2表現で入る**: プレーンテキストは `## ` / `- [ ] ` の記法付き markdown、リッチテキスト (RTF) は見出しサイズ (h1 22pt / h2 18pt / h3 16pt)・チェックボックス記号 (☐/☑)・完了項目の打ち消し線が付く
  - 自動化: NikkiTests/EditorBlockCopyTests.swift (リッチテキスト表現) + manual（ペーストボードの中身を機械検証する）
  - macOS で `clipboard info` に RTF と plain text の両方が載り、RTF ダンプに ☐/☑ と \strike、fs30/fs36/fs44 (15/18/22pt) を確認した
- [x] **リッチテキスト対応アプリへスタイル付きで貼れる**: TextEdit 等へ貼ると見出しが大きく太く、チェックリストが ☐/☑ と打ち消し線付きで貼られる
  - 自動化: manual
  - macOS の TextEdit へ「すべてコピー」を貼り、h1/h2 のサイズ・☐ 麦茶のパック・☑ 蚊取り線香 (打ち消し線) が反映された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/2dad7476-8a1e-44f2-bced-0ddba12ea92b.png)
  - iOS のリッチテキスト対応アプリへの貼り付けは未検証 (simtunnel の Simulator にリッチテキスト対応のペースト先アプリが無いため)。RTF の生成は iOS / macOS 共通コード (EditorBlockCopy) で、内容は NikkiTests/EditorBlockCopyTests.swift と macOS の実ペーストで担保
- [x] **markdown の複数行を貼り付けるとブロックに復元される**: 見出し・チェックリストの記法を含む複数行を段落へ貼ると、その場で見出し・チェックリスト (チェック状態付き) のブロックに変わる。チェックリスト項目への貼り付けも記法を剥がして完了状態ごと項目になる
  - 自動化: NikkiTests/BlockEditingTests.swift (pastesMarkdownIntoParagraph / keepsFirstBlockOnPasteWithoutSyntax / keepsPastedEmptyLinesAsEmptyParagraphs / pastesChecklistMarkdownIntoChecklistItem) + manual
  - macOS で新規日記へ markdown を貼り、h2・チェックリスト (未完了/完了+打ち消し線)・段落に即時復元された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/fd93f6d1-7138-4122-991f-ab716ec69fa1.png)
  - macOS で「すべてコピー」した内容を別の日記へ貼り、h1/h2・チェック状態・段落が復元された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/7d7320aa-d81d-4822-bc87-3ba4180014f7.png)
  - iOS で空の段落へ OS のペースト (タップ → Paste) で markdown を貼り、h2・チェックリスト (チェック状態・打ち消し線付き)・段落に即時復元された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/d533ae7f-5b6a-4e47-9d19-e3ffc0047e96.jpg)
  - レビュー対応で先頭行の解釈判定を「新しく入った行だけを解釈する」方式へ作り直した後 (e1b6262)、macOS で同じ貼り付けを再確認し、h2・未完了/完了のチェックリストに復元された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/5f36124d-83b3-46b9-988d-25388bd78855.png)
- [x] **元からあった行は Return・部分的な貼り付けで markdown として解釈されない**: 記法を含む本文の途中で Return しても、カーソル前後の既存の行は段落のまま分かれる。既存の行の末尾へ複数行を貼り付けたときも、先頭行 (既存の文字が残る行) は段落のままで、新しく入った行だけが見出し・チェックリストになる
  - 自動化: NikkiTests/BlockEditingTests.swift (keepsTextAfterCaretOnReturn / keepsExistingFirstLineOnAppendPaste / keepsExistingChecklistItemTextOnAppendPaste) + manual（iOS は Return が Binding に改行として入り macOS の onSubmit と経路が違うため、実機での確認が必要）
  - iOS (simtunnel、e1b6262 以降のビルド) で段落「x# Topic」の途中で Return すると「x#」「Topic」の段落に分かれ、どちらも見出しにならなかった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/5c83ab4b-2997-4c4c-bd35-ad8d5f7b4c4f.jpg)
  - iOS で段落「Topic」の末尾へ `# tail\n# inserted` を貼り付けると、先頭行は段落「Topic # tail」のまま、新しく入った行だけが H1「inserted」になった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/afd98b1e-347b-4ae1-af2f-6cdc1b459e40.jpg)
- 補足 (既知の制限):
  - リッチテキストの書体はアプリ同梱の Zen Kaku Gothic ではなくシステムフォント (ペースト先の端末に同梱フォントが無いため)
  - 貼り付けた markdown の空行 (ブロック区切り) は編集中は空の段落として見え、閉じるときに落ちる
  - macOS の余白メニューはカーソル位置ではなく本文エリアの下寄りに表示されることがある (SwiftUI の contextMenu の表示位置仕様)
  - macOS の見出し・段落はブロック単体のコピーに到達できない (入力欄上の右クリックが OS のテキスト編集メニューになるため。ハンドル右クリックの導線は issue #105 の D&D revert で無くなった)。本文全体は余白の「すべてコピー」で取れる
