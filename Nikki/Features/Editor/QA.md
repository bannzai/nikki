---
feature: Editor
verification: mobile-mcp
last_verified_commit: bb7fbc19192ed304b9745bcfce9c0121d0f133ee
last_verified_at: 2026-08-26
---

# Editor QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、実装の挙動をもとに項目を起こしている)
- 関連: 新規作成の流れ (日記を作ってからエディタで書き出しを決める) https://github.com/bannzai/nikki/issues/50
- 関連: ノートが2冊以上のときのエディタからの切り替え導線 https://github.com/bannzai/nikki/issues/58
- 関連: 設定「文字の大きさ」などの導線の配線 https://github.com/bannzai/nikki/issues/14
- 関連: 紙色テーマの実画面への適用 https://github.com/bannzai/nikki/issues/73
- 関連: markdown ブロックの装飾表示 (見出し・チェックリスト・画像・details) https://github.com/bannzai/nikki/issues/88
- 関連: エディタを Obsidian 準拠の単一テキストビュー (Live Preview) 方式に作り替える https://github.com/bannzai/nikki/issues/111
- 補足: 選択ツールバー(1j)・ブロックの並び替え(1k)は、DEBUG ビルドのデザインカタログでだけ表示できる静的な画面で、製品の導線からは到達しない。エディタ本文の装飾表示は issue #111 の Live Preview 方式で、「4. Live Preview の装飾表示と操作」で QA する
- 補足: タイトル欄は廃止した (日記にタイトルは必須ではなく、タイトル欄が本文の書きはじめをわかりにくくしていたため)。過去に入力されたタイトルは、その日記をエディタで開いたときに本文先頭の H1 見出しへ移して残す

## 1. 執筆と保存

- [x] **開いたらすぐ本文を書ける**: エディタにタイトル欄はなく、開くと本文末尾の空の行にキャレットが当たる(日記の続きを書く位置。issue #111 の単一テキストビュー化でフォーカス先は「ブロック」から「本文末尾のキャレット」になった)。本文が空のときはプレースホルダ(「ここに本文を書く…」)が出る
  - 自動化: manual（開いた直後のフォーカス・プレースホルダと入力の反映を実操作で確認する）
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、macOS (署名なし Debug + カタログ entryList) で日記を開くと本文末尾の空の行にキャレットが出て、そのまま入力できた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/567d9c09-9af6-4af3-bdf8-2492166d9449.png)。プレースホルダは本文が完全に空の時のみの表示で未検証 (新規日記は既定テンプレートの見出しから始まるため)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、日記を開くとキーボードが上がり本文末尾の空の行にキャレットが出て、そのまま入力できた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c78c4706-db90-4a8b-b0b0-88c40e8c144c.jpg)
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
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、macOS (署名なし Debug) で日本語入力ソースから「kakikuke」を 0.8 秒間隔で入力し、変換中の「かきくけ」が下線付きで全文字保持され、Return での確定後も本文に残った (変換中の行は装飾の引き直し対象から外している。 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/f6a42ef7-acaa-4c92-ae69-6992bdcfbcfa.png)
- [x] **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る
  - 自動化: manual（日付の表記を目視で確認する）
  - 2026-08-22 ローカル iOS Simulator (日本語) で「8月22日 土曜日」
  - 2026-08-25 システムの NavigationBar への移行 (issue #104) 後、simtunnel リモート iOS Simulator (iOS 26) で、日付がナビゲーションバー中央のキャプションとして「8月25日 火曜日」と出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/16b0d4dc-845f-4300-a09f-d36c206a5c97.jpg)
- [x] **戻るとホームに反映される**: 左上の戻るボタン(issue #104 でシステム標準の戻るボタンに移行)または左エッジのスワイプでホームへ戻ると、その日記の行が本文の抜粋で表示される (タイトルのない日記は空のタイトル行を出さない)
  - 自動化: manual（画面をまたいだ反映を目視で確認する）+ NikkiUITests/NavigationSwipeBackUITests.swift (スワイプで戻れること自体の機械検証)
  - 2026-08-22 ローカル iOS Simulator で、閉じた直後のホームに本文の抜粋だけの行が出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/9501fb65-25a9-40fd-93c6-12ce758b1c53.png)
  - 2026-08-22 編集中の本文を @State に持つ変更 (issue #86) 後も、iOS で「かたなはま」を確定して閉じた直後のホームに抜粋が出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/961222cf-0103-465c-809d-3d78fd7773fb.png)。macOS でも同様に反映された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/91031702-4f76-4e4b-9dce-91d7e98254cb.png)
  - 2026-08-25 システムの NavigationBar への移行 (issue #104) 後、simtunnel リモート iOS Simulator (iOS 26) で、エディタから左エッジのスワイプでホームへ戻り、作成した日記の行が一覧に出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/d619de59-47dd-4fa1-94ff-52f8d327b20e.jpg)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、macOS (署名なし Debug) でチェックリスト項目「tesuto」を追加して戻ると、ホームの行の抜粋が更新された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/99b92f5f-a76a-4457-854c-a77af9199fbc.png)。開き直すと追加した項目とチェック状態が保持されていた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/567d9c09-9af6-4af3-bdf8-2492166d9449.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、戻った直後のホームに本文の抜粋が出て (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/a8e02e91-fc59-4a99-9cac-d60e12ddda8b.jpg)、開き直すと完了状態ごと本文が保持されていた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c78c4706-db90-4a8b-b0b0-88c40e8c144c.jpg)
- [x] **アプリを終了しても書いた内容が残る**: 書いた直後にアプリを終了して起動し直し、同じ日記を開くと本文が残っている
  - 自動化: manual（アプリの終了と再起動をまたいだ永続化を実操作で確認する）
  - 2026-08-22 ローカル iOS Simulator で、terminate → 再起動後もホームに本文の抜粋が残っていた
  - 2026-08-22 macOS (Debug) で、エディタに「cmdq test body」を入力して開いたまま ⌘Q → 再起動すると、ホームに本文が残っていた (エディタ表示中のアプリ終了は willTerminateNotification 経由の書き戻し。 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260822/a5040e50-02ff-4b9e-a64b-f05285e8dc95.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後は未再検証 (書き戻しの経路 = onDisappear / scenePhase / willTerminateNotification の commitDraft は変更なしで、編集先が [Block] から markdown 文字列になっただけ)

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **日付が上部に出る**: 画面上部に日記の日付が「7月18日 土曜日」の形式 (英語表示では「Saturday, July 18」) で出る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/cc03d133-fc9a-4b76-bc95-039e85cc262c.jpg" width="320">

</details>

### **戻るとホームに反映される**: 左上の戻るボタン(左向きシェブロン。issue #92 で下向きシェブロンから変更)でホームへ戻ると、その日記の行が本文の抜粋で表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-24** (左向きシェブロンの戻るボタンを確認)
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260824/cc5420d3-8e56-4439-8c22-76dfe69cb3c8.jpg" width="320">

（タイトル欄の廃止に伴う旧エビデンスは撤去済み。ホームへの反映自体は次回 run-qa で再取得する）

</details>

</details>

---

## 2. 文字の大きさの反映

- [x] **設定の文字の大きさが本文に効く**: 設定で文字の大きさを「小」「標準」「大」に変えると、エディタの本文の文字サイズがそれぞれ変わる
  - 自動化: manual（3段階の見た目の違いを目視で比較する）
  - 2026-08-26 単一テキストビュー化 (issue #111) 後は未再検証 (bodyFontSize の反映経路が TextField の .font から EditorTextView の属性適用に変わったため、次回 run-qa で再確認する)
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
  - 2026-08-25 システムの NavigationBar への移行 (issue #104) 後、simtunnel リモート iOS Simulator (iOS 26) で、ナビゲーションバー右端の「テンプレート」から一覧が開いた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260825/cea30166-5fb9-4f07-affd-397d4e8e266e.jpg)
  - 2026-08-26 macOS (ad-hoc 署名の Debug ビルド) でも trailing ボタンを実操作確認。エディタのウィンドウツールバーに日付キャプションと「テンプレート」(.primaryAction) が出てクリックで一覧が開き (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/32d2b47b-9f61-4a72-8c63-6044bda637d9.png, https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/0326038c-3be3-4b3b-adba-e1dcd9423249.png)、作成フォームの右端に「作成」が出た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/8cf7c285-4518-4707-8679-db3463308a2a.png)
- [x] **選択中のテンプレートにチェックが付く**: テンプレート一覧で、いま日記に使われているテンプレート(新規日記なら既定の {{date}} テンプレート)にチェックが付いている
  - 自動化: manual（一覧のチェック表示を目視で確認する）
  - 新規日記では既定の「Blank page」にチェックが付き、「Morning notes」を選ぶとチェックが移った
- [x] **テンプレートを選ぶと書き出しが入れ替わる**: テンプレート一覧で別のテンプレートを選んでエディタへ戻ると、本文がそのテンプレートの書き出し全文(先頭の # 見出しも含む)に置き換わっている
  - 自動化: manual（戻った直後のエディタの中身を目視で確認する）+ NikkiTests/JournalEntryTests.swift (replace)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後は未再検証 (一覧から戻った時の再同期 loadDraftMarkdown の経路が [Block] から markdown 文字列に変わったため、次回 run-qa で再確認する)
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

## 4. Live Preview の装飾表示と操作 (単一テキストビュー)

(issue #111 で本文全体を1つのテキストビューで markdown のまま編集する Live Preview 方式に変更。ソースは常に markdown 文字列で、記法は行単位の装飾として表示する。カーソルのある行では記法がグレーの生テキストで見え、行を離れると隠れて装飾だけになる (Obsidian と同じ)。エビデンスの日付はすべて 2026-08-26、macOS は署名なし Debug + カタログの entryList)

- [x] **markdown 記法が装飾表示される**: 見出し(#〜###)は見出しの書体、チェックリスト(- [ ] / - [x])はチェックボックスと完了項目の打ち消し線+灰色で表示され、記法の文字はカーソルの無い行では見えない
  - 自動化: NikkiTests/EditorMarkdownStylerTests.swift (行単位のスタイル判定・属性適用) + manual（描画は目視で確認する）
  - macOS でサンプル日記の見出し・チェックリスト (完了は打ち消し線+灰)・段落が装飾表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c766ab0e-4f0a-4257-aef8-c69f6d986ae2.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、見出し (# は非表示)・チェックボックス・完了項目の打ち消し線+灰が表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/15760956-fa30-4dc5-87b0-c3a1d73e8087.jpg)
- [x] **カーソルのある行では記法が生で見える (Live Preview)**: キャレットを見出し行に置くと「#」がグレーの生テキストで見え、行を離れると隠れる。チェックリスト行もカーソル行では「- [ ]」が生で見え、チェックボックスは出ない
  - 自動化: NikkiTests/EditorMarkdownStylerTests.swift (editorLineRevealsSyntax) + manual
  - macOS で ⌘↑ でキャレットを見出し行へ置くと「#」がグレーで見え (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/f3e1147d-08b2-482e-852a-3c29fc98884b.png)、行を離れると隠れた (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c766ab0e-4f0a-4257-aef8-c69f6d986ae2.png)
  - 初回実装では、本文が改行で終わる状態で文末 (最終改行の直後) にキャレットがあると、1つ前の行も「カーソル行」と誤判定して記法が生表示のまま残った (iOS の実操作で発覚 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/eb26a38e-8b49-4f71-9ef8-7651e777a274.jpg 、macOS でも再現)。reveal 判定を NSString.lineRange と同じ「キャレットの属する行」に正して解消し、チェックリスト行末の Return 直後にチェックボックス表示へ戻ることを macOS で確認 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/a85773b7-4e37-4257-b6ee-c311ea6c3dbf.png)。回帰テスト caretAfterTrailingNewlineDoesNotRevealPreviousLine を追加。修正後のトグルも再確認 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/3e6d7b75-5773-4bf9-8c1d-40b031560729.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、キャレットを見出し行に置くと「#」がグレーで見え、チェックリスト行はチェックボックス表示のままだった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/15760956-fa30-4dc5-87b0-c3a1d73e8087.jpg)。チェックリスト行末の Return + 次の行への記法入力の後も、元の行はチェックボックス表示のまま残った (回帰確認。 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/42f77ace-37bf-42da-931b-c0b71a89ae0f.jpg)
- [x] **行頭の Backspace で前の行と結合する**: 行頭でバックスペースを押すと前の行 (空行を含む) と結合する。テキストビュー標準の挙動 (issue #111 で解消した不満 1)
  - 自動化: manual（キー入力とキャレット位置の目視確認が必要なため）
  - macOS で段落の行頭のバックスペースで上の空行が消えて詰まり (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c27e44b6-e1bb-4ae7-a3cc-f98b9cc7dbba.png)、続けてバックスペースすると見出し行と結合して段落の文字が見出しの一部になった。⌘Z 2回で両方の操作が元に戻った
  - iOS の行頭バックスペースでの結合は個別には未検証 (単一テキストビュー標準のテキスト削除で、行内の削除は「空のチェック項目のバックスペース」の項で確認済み)
- [x] **行の途中の Return でカーソル以降が次の行へ移る**: 行の途中で Return すると、その位置で行が分かれてカーソル以降の文字が次の行になる (旧実装の既知の制限を解消)
  - 自動化: manual（キャレット位置を伴うキー入力の確認が必要なため）
  - macOS で段落「風が涼しく|なってきたので…」の5文字目で Return すると、「風が涼しく」と「なってきたので…」に分かれ、キャレットが2行目の先頭に来た (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c9e62f36-7d73-4eec-b158-6c17acd50e01.png)。⌘Z で元に戻った
- [x] **チェックのタップで完了が切り替わり保存される**: チェックボックスをタップすると即座に完了(墨地+白チェック、打ち消し線+灰) / 未完了が切り替わり、閉じて開き直しても状態が残る(markdown へ - [x] / - [ ] として書き戻される)
  - 自動化: NikkiTests/EditorMarkdownStylerTests.swift (editorChecklistBoxes) + manual
  - macOS でクリックにより未完了→完了 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/2fa85e92-9da6-44f2-8829-67df6a5d2ddc.png)、再クリックで完了→未完了 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/a49a0dd6-8e60-4b3b-9e8d-c134a818abdc.png) が切り替わった。追加した項目が閉じて開き直しても残ることも確認 (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/567d9c09-9af6-4af3-bdf8-2492166d9449.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、タップで未完了→完了 (打ち消し線+灰) に切り替わり (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/b47fefa8-dde5-43ec-ad0e-f5498b76ffc3.jpg)、閉じて開き直しても保持された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/c78c4706-db90-4a8b-b0b0-88c40e8c144c.jpg)
- [x] **記法を打つとその行が装飾される**: 行に「- [ ] 」「- [x] 」「# 」〜「### 」を打つと、その行が装飾の対象になる。カーソルがその行にある間は記法が生で見え、行を離れるとチェックボックス・見出し表示になる。既存の文の行頭に打ち足しても効く (issue #111 で解消した不満 2)
  - 自動化: NikkiTests/EditorMarkdownStylerTests.swift (editorLineStyle) + manual
  - macOS で「- [ ] tesuto」と入力するとカーソル行では記法がグレーで見え (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/0a314ab7-665c-4dcd-a903-94f6538e6c36.png)、↑で行を離れるとチェックボックス表示になった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/553979bb-9b90-455b-832b-c0431e312668.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、ソフトウェアキーボードで「- [ ] milk」を入力するとカーソル行では記法がグレーで見え、行を離れるとチェックボックス表示になった (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/15760956-fa30-4dc5-87b0-c3a1d73e8087.jpg)
- [x] **完了した項目のテキストも編集できる**: 完了 (打ち消し線) の項目にキャレットを置いてそのまま文字を挿入・削除できる (旧実装の既知の制限を解消)
  - 自動化: manual
  - macOS で完了項目「麦茶のパック」の途中にキャレットを置くと記法「- [x]」が生で見え、そのまま「OK」を挿入できた (挿入した文字にも打ち消し線が継続。 https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/29d7910f-e06a-4ea9-b713-95e7a53ba11d.png)。⌘Z で元に戻した
- [x] **空のチェック項目のバックスペースは記法の文字を普通に削除する**: 「- [ ] 」だけの行でバックスペースを押すと、記法の文字が1文字ずつ消える (Obsidian 実測と同じ。カーソル行では記法が生表示されているため見た目も自然)。ソフトウェアキーボードのバックスペースでも同じに動く設計 (通常のテキスト削除のため)
  - 自動化: manual
  - macOS で「- [ ] 」入力後にバックスペース2回で「- [」が残り、記法の文字が普通に削除された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/530614c1-4941-4548-b41f-39620466939f.png)
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、ソフトウェアキーボード相当の削除 (WDA typeText の backspace) 2回で「- [ ] 」が「- [」になり、記法の文字が普通に削除された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/3ac0a2f8-5523-4ffa-b5da-de9fecf450d2.jpg)。旧実装の既知の制限「ソフトウェアキーボードの ⌫ でチェックボックスを外せない」は解消
- [x] **↑↓・行またぎの選択が自然に動く**: 1つのテキストビューのため、↑↓のキャレット移動・複数行の選択が行やブロックの境界を越えて動く
  - 自動化: manual
  - macOS で本 QA の一連の操作 (⌘↑・↓×2・↑・⌘A の全選択など) がすべて期待どおりに動いた (エビデンスは各項目のスクリーンショット)
- 補足 (既知の制限):
  - img・details の行は、attachment 表示を復元するまでの一時後退として生の HTML 行がモノスペース書体で見える (プレースホルダ・開閉カードの復元は issue #111 の PR 3 で行う)。行として選択・削除はできるようになった (旧実装の「img/details を削除できない」は解消)
  - チェックリスト行の Enter での「- [ ] 」自動継続・空項目の Enter でのリスト脱出・Cmd+Enter / Cmd+L のチェックボックストグルは issue #111 の PR 2 で入れる (本 PR の Return は素の改行)
  - インデントされた記法の行 (「    - [ ] 」等) は装飾せず段落のまま表示・保存する (保存形式のパーサと同じ規則)
  - details の開閉トグルは attachment 復元 (PR 3) まで使えない (open 属性を直接編集はできる)

---

## 5. コピーと貼り付け

(issue #111 の単一テキストビュー化でコピーの導線を変更。ソースが markdown 文字列そのものになったため、テキスト選択のコピーが markdown のコピーになる。エビデンスは 2026-08-26、macOS は署名なし Debug + カタログの entryList)

- [x] **選択してコピーすると markdown が入る**: 本文を選択して ⌘C すると、選択範囲の markdown (記法付きプレーンテキスト) がペーストボードに入る
  - 自動化: manual
  - macOS で ⌘A → ⌘C の結果、`# 梅雨明け` や `- [ ] tesuto` を含む本文全体の markdown が pbpaste で取れた
- [x] **「すべてコピー」で本文全体が2表現で入る**: テキストビューの右クリック (macOS) / 編集メニュー (iOS) の「すべてコピー」で、本文全体 (空のブロックを除く) が markdown とリッチテキスト (RTF: 見出しサイズ・☐/☑・完了の打ち消し線) の2表現でペーストボードに入る
  - 自動化: NikkiTests/EditorBlockCopyTests.swift (リッチテキスト表現) + manual
  - macOS で本文上の右クリックメニューの末尾に「すべてコピー」が出て (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/18c4929c-7b3c-49fe-ae77-a66e6a4fbd96.png)、実行すると本文全体の markdown が pbpaste で取れた
  - 2026-08-26 単一テキストビュー化 (issue #111) 後、simtunnel リモート iOS Simulator (iPhone 17、reveal 判定修正後のビルド) で、キャレット位置のタップで出る編集メニューに「Copy All」が表示された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/27da919d-50bd-46f2-9a7c-7733f5499f5d.jpg)。実行後のペーストボード内容の検証は未実施 (コピー処理は macOS と共通コードで、markdown/RTF の内容はユニットテストと macOS の pbpaste で担保)
- [x] **markdown の貼り付けはソースに残り、表示だけ装飾される**: 記法を含む複数行を貼ると、貼った文字がそのまま markdown ソースに入り、行単位の装飾で表示される。貼り付けで既存の文字が別の種類に変換されることはない (非破壊。行の途中に貼った「##」は見出しにならない = markdown の行頭規則のまま)
  - 自動化: NikkiTests/EditorMarkdownStylerTests.swift (行単位のスタイル判定) + manual
  - macOS で `## 貼り付け見出し\n- [x] 完了アイテム\n平文` を本文末尾 (既存の文の行末) に貼ると、1行目は既存の文と同じ行のため段落のまま、「- [x] 完了アイテム」は打ち消し線付きのチェック項目として即座に装飾された (https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260826/4394863c-5a88-4303-9bf9-2d5355b871c2.png)。⌘Z で貼り付け全体が元に戻った
- 補足 (既知の制限):
  - ブロック単位の「コピー」メニュー (旧実装のブロック長押し / 右クリック) は廃止した。1ブロックだけコピーしたい時はその行を選択して ⌘C する (markdown が入る)
  - リッチテキスト表現が入るのは「すべてコピー」のみ。選択コピーはプレーンテキスト (markdown) のみ
  - リッチテキストの書体はアプリ同梱の Zen Kaku Gothic ではなくシステムフォント (ペースト先の端末に同梱フォントが無いため)
  - CRLF を含む貼り付けは LF に揃えてから挿入する (markdown ソースを LF で保つため)
