---
feature: Settings
verification: mobile-mcp
last_verified_commit: 96337de3d8717a2428e3fa4d4120727fab323a27
last_verified_at: 2026-08-21
---

# Settings QA

## 関連リンク

- 仕様: 仕様なし QA (「仕様・期待挙動」欄を持つ issue が存在しないため、コードの実挙動を正として項目を書いている)
- 関連: https://github.com/bannzai/nikki/issues/14 (設定各行の遷移・設定値の永続化・パスキー表示の実装)
- 関連: https://github.com/bannzai/nikki/issues/46 (すべての日記を削除して欲しい)
- 関連: https://github.com/bannzai/nikki/pull/49 (設定に「すべての日記を削除」を追加)
- 関連: https://github.com/bannzai/nikki/pull/59 (ノート管理導線の追加)

## 1. 設定項目の表示

- [x] **各行が現在値を表示する**: ノート (冊数)・自動ロック (秒数)・テーマ・文字の大きさ・Nikki Plus (加入状態) の各行に、いま設定されている値が表示される
  - 自動化: manual（表示の目視確認）
  - ノート「1 notebook」・自動ロック「30 seconds」・テーマ「Cream」・文字の大きさ「Standard」・Nikki Plus「Not subscribed」が表示された
- [x] **既定のノートはノートが2冊以上のときだけ出る**: ノートが1冊のときは「既定のノート」の行が出ず、2冊以上に増やすと行が現れて選択中のノート名が表示される
  - 自動化: manual（ノートを増減させながらの表示確認）
  - ノート 1 冊では行が無く、2 冊目 (Travel log) を作ると「Default notebook / Blank page」の行が現れた
- [x] **パスキーは未登録として表示される**: 「パスキー」の行が「未登録」と表示され、遷移先がないためタップしても画面が変わらない
  - 自動化: manual（登録フロー未実装のため表示のみの確認）
  - 「Passkey / Not registered」と表示され、タップしても画面は変わらなかった

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **各行が現在値を表示する**: ノート (冊数)・自動ロック (秒数)・テーマ・文字の大きさ・Nikki Plus (加入状態) の各行に、いま設定されている値が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/3b75750e-4f9f-4d96-8020-b2269e5bf1fb.jpg" width="320">

</details>

### **既定のノートはノートが2冊以上のときだけ出る**: ノートが1冊のときは「既定のノート」の行が出ず、2冊以上に増やすと行が現れて選択中のノート名が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

1 冊のとき (1 枚目) は「Notebooks」の下がすぐ「Auto-lock」で、2 冊にすると (2 枚目) 間に「Default notebook / Blank page」が現れる。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/3b75750e-4f9f-4d96-8020-b2269e5bf1fb.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0252bf8e-1022-4ec4-b4d2-4168b35398b0.jpg" width="320">

</details>

### **パスキーは未登録として表示される**: 「パスキー」の行が「未登録」と表示され、遷移先がないためタップしても画面が変わらない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

タップ後のスクリーンショット。画面は設定のまま変わらない。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/d28495a5-a169-4f7e-849c-bdeacccae300.jpg" width="320">

</details>

</details>

---

## 2. 設定値の変更と永続化

- [x] **自動ロックの秒数を選べる**: 「自動ロック」をタップすると秒数の選択肢が出て、選んだ値が行に反映される
  - 自動化: manual（確認ダイアログの操作を伴うため）
  - 5 / 10 / 30 / 60 秒の選択肢が出て、60 秒を選ぶと行が「60 seconds」になった
- [x] **文字の大きさを選べる**: 「文字の大きさ」で選んだ大きさが行に反映され、日記の本文の文字サイズが変わる
  - 自動化: manual（本文表示の目視確認を伴うため）
  - Small / Standard / Large の選択肢が出て、Large を選ぶと行が「Large」になり、エディタの本文も大きくなった
- [x] **Face ID で解除を切り替えられる**: 「Face ID で解除」のトグルを切り替えると状態が変わり、オフの間は自動ロックが発動しない
  - 自動化: manual（自動ロックの発動有無を待って確認するため）
  - トグルのオン・オフの切り替えを確認した。オフのまま自動ロックを 60 秒に設定し、2 分以上無操作の間を挟んでもロック画面は出なかった (Simulator の時計で 6:43 → 6:45 の間)
- [x] **変更が再起動後も残る**: 上記を変更してアプリを終了・再起動すると、変更後の値が表示される
  - 自動化: manual（アプリの終了・再起動を伴う確認のため）
  - 自動ロック 60 秒・文字の大きさ Large・Face ID オフ・ノート 2 冊が、terminate → launch 後も維持されていた

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **自動ロックの秒数を選べる**: 「自動ロック」をタップすると秒数の選択肢が出て、選んだ値が行に反映される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0909c300-0f75-4132-a9ac-927c3d00768f.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/b5abc497-8a96-46bf-bb7d-149b0e1fa2cb.jpg" width="320">

</details>

### **文字の大きさを選べる**: 「文字の大きさ」で選んだ大きさが行に反映され、日記の本文の文字サイズが変わる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

選択肢 (1 枚目)、行への反映 (2 枚目)、同じ日記の本文が Standard のとき (3 枚目) と Large のとき (4 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0baaef7c-73b9-401c-bec4-a506ea6fe483.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/b5abc497-8a96-46bf-bb7d-149b0e1fa2cb.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/9beb84a6-61e6-43e3-9a9c-dfece704ab87.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/1894d7f3-c5af-46fc-84cb-f1325dc11a1d.jpg" width="320">

</details>

### **Face ID で解除を切り替えられる**: 「Face ID で解除」のトグルを切り替えると状態が変わり、オフの間は自動ロックが発動しない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

オンにした直後 (1 枚目) と、オフに戻して再起動した後 (2 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/aaf8e394-17ec-4714-b913-0d97852dfa3a.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/3e4b16aa-3190-4466-bbe3-648d01ca88a0.jpg" width="320">

</details>

### **変更が再起動後も残る**: 上記を変更してアプリを終了・再起動すると、変更後の値が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/96188209-2a66-4f56-888a-d805668b5d99.jpg" width="320">

</details>

</details>

---

## 3. 他画面への導線

- [x] **各行から対応する画面へ遷移する**: ノート・既定のノート・テーマ・アーカイブ済み・オープンソースライセンスの各行から、それぞれの画面へ遷移して戻ってこられる
  - 自動化: manual（画面遷移の目視確認）
- [x] **Nikki Plus からペイウォールが開く**: 「Nikki Plus」の行からペイウォールがシートで開き、閉じると設定画面に戻る
  - 自動化: manual（シートの開閉操作を伴うため）
- [x] **戻るボタンで設定を閉じられる**: ナビゲーションバーの戻るボタンで設定画面を閉じ、元の画面に戻る
  - 自動化: manual（画面遷移の目視確認）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **各行から対応する画面へ遷移する**: ノート・既定のノート・テーマ・アーカイブ済み・オープンソースライセンスの各行から、それぞれの画面へ遷移して戻ってこられる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

既定のノート (1 枚目)、テーマ (2 枚目)、アーカイブ済み (3 枚目)、オープンソースライセンス (4 枚目)。ノート画面は 2 冊目の作成で到達を確認し、いずれも戻るボタンで設定へ戻れた。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/6cc3d899-199b-4b56-b96f-c03171974304.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7f937d41-6344-42f5-be63-c50d9f59c834.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7b0924ee-d8a5-4dc1-adf2-aebb841e1d99.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/878bc501-f1ba-4e21-a06b-d0c1d1a29374.jpg" width="320">

</details>

### **Nikki Plus からペイウォールが開く**: 「Nikki Plus」の行からペイウォールがシートで開き、閉じると設定画面に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

「Nikki Plus」の行から開いたペイウォール (1 枚目) と、× で閉じて戻った設定画面 (2 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/d168cef6-0049-4414-9a1a-e3256f82bb03.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/70759983-5144-4e00-b78b-6097de8ecd71.jpg" width="320">

</details>

### **戻るボタンで設定を閉じられる**: ナビゲーションバーの戻るボタンで設定画面を閉じ、元の画面に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

設定の戻るボタンでホームへ戻ったところ。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/253ee654-a66a-44f6-8df3-620ad8f5a50b.jpg" width="320">

</details>

</details>

---

## 4. データの書き出しと削除

- [x] **Markdown の保存先を選べる**: 「Markdown で書き出す」からファイルの保存画面が開き、保存すると Nikki.md が書き出される。キャンセルしても設定画面が壊れない
  - 自動化: manual（OS のファイル保存画面の操作を伴うため）
  - 保存画面で「Save as Nikki」の状態で「On My iPhone」へ保存でき、保存後は設定画面へ戻った。Files アプリで 392 バイトのファイルが確認できた。キャンセル時の挙動は本バッチでは未確認
- [x] **書き出した内容が日記と一致する**: 書き出したファイルに、日付見出しと本文が古い順で並んでいる
  - 自動化: auto（NikkiTests/JournalEntryTests.swift）
  - Files アプリのプレビューで、`# 2026-08-21 <タイトル>` の見出しと本文が `---` 区切りで 4 件並び、ホームの新しい順とは逆 (= 古い順) であることを確認した。アーカイブ済みの日記も書き出しに含まれる
- [x] **すべての日記を削除できる**: 「すべての日記を削除」で確認ダイアログが出て、実行するとアーカイブ済みを含む日記が全件消え、ノートは残る
  - 自動化: auto（NikkiTests/JournalEntryTests.swift。削除の実行結果を検証。確認ダイアログの表示は目視）
  - 確認ダイアログ「This deletes every entry, including archived ones. This cannot be undone.」が出て、実行するとホームが空状態になり、アーカイブ一覧も空状態になった。ノートは 2 冊のまま残った

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **Markdown の保存先を選べる**: 「Markdown で書き出す」からファイルの保存画面が開き、保存すると Nikki.md が書き出される。キャンセルしても設定画面が壊れない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

保存画面 (1 枚目)、保存後に戻った設定画面 (2 枚目)、Files アプリで確認したファイル (3 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/6734d054-83ad-4634-b259-fa64a2a01f6f.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/58eee103-831a-4a64-86c4-6dfab42316e2.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/d3148eb7-7051-45cf-9786-22d2b53c66ba.jpg" width="320">

</details>

### **書き出した内容が日記と一致する**: 書き出したファイルに、日付見出しと本文が古い順で並んでいる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

Files アプリのプレビューで開いた書き出し結果。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/6db6a5dd-97e4-48c7-87d9-a9060e340491.jpg" width="320">

</details>

### **すべての日記を削除できる**: 「すべての日記を削除」で確認ダイアログが出て、実行するとアーカイブ済みを含む日記が全件消え、ノートは残る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

確認ダイアログ (1 枚目)、実行後にノートが 2 冊のまま残った設定画面 (2 枚目)、空になったホーム (3 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/ebde8c14-e587-42cc-9ee0-7511c1dbc309.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/09c92868-3ef4-4170-8292-0d5c70efee7e.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/c3443d67-fd00-46b7-9f5d-efedb4909696.jpg" width="320">

</details>

</details>
