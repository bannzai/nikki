---
feature: Theme
verification: mobile-mcp
last_verified_commit: 96337de3d8717a2428e3fa4d4120727fab323a27
last_verified_at: 2026-08-21
---

# Theme QA

## 関連リンク

- 仕様: https://github.com/bannzai/nikki/issues/73 (紙色テーマを実画面に適用する。「やること」「完了条件」を仕様の正データとして扱う)
- 関連: https://github.com/bannzai/nikki/pull/25 (紙色プリセットを Plus 限定にする解放境界の実装) / https://github.com/bannzai/nikki/issues/54 (背景画像を含む将来の解放境界)

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | テーマで紙色を変えると、ホーム・エディタなどの実画面の紙地に即時反映され、アプリを再起動しても維持される | 実画面への反映と再起動後の維持 |
| S2 | 紙色プリセットは白・生成が無料で、薄鼠・青磁・桜鼠は Nikki Plus 限定としてロックアイコンが付く | Plus 限定プリセットのロック表示 |
| S3 | ロックされたプリセットをタップしても選択は変わらず、ペイウォールが開く | ロックされたプリセットのタップでペイウォールが開く |
| S4 | Plus 失効中は保存値を残したまま無料の既定「生成」へ倒れ、再加入すると元の選択に戻る | Plus 失効時に無料の紙色へ倒れる |
| S5 | 濃い紙色でも文字・カード・セパレータのコントラストが破綻しない | 濃い紙色でのコントラスト |

## 1. 紙色の選択とプレビュー

- [x] **既定の選択状態**: 設定 > テーマ を開くと「生成」が選択状態 (墨枠 + チェック) で、プレビューカードの地とページの紙地が生成色になっている
  - 自動化: manual（画面の描画と選択表示の目視確認のため）
  - 英語ロケールの Simulator で確認。プリセット名は 白 = White / 生成 = Cream / 薄鼠 = Ash / 青磁 = Celadon / 桜鼠 = Sakura で表示される
- [x] **無料プリセットの切り替え**: 「白」をタップすると選択が白へ移り、プレビューカードとページの紙地が即座に白へ変わる
  - 自動化: manual（タップ操作と即時反映の目視確認のため）
- [x] **実画面への反映と再起動後の維持**: テーマを変更してホーム・エディタへ戻ると紙地が選んだ色になり、アプリを再起動しても同じ色が維持される
  - 自動化: manual（アプリの再起動をまたぐ永続化の確認のため）
- [x] **背景画像セクションの表示**: 「背景画像」は「なし」がチェック付きで選択されており、「写真から選ぶ」はまだ何も起きない (画像選択は issue #54 で実装予定)
  - 自動化: manual（未実装の導線が行き止まりにならないことの目視確認のため）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **既定の選択状態**: 設定 > テーマ を開くと「生成」が選択状態 (墨枠 + チェック) で、プレビューカードの地とページの紙地が生成色になっている

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7f937d41-6344-42f5-be63-c50d9f59c834.jpg" width="320">

</details>

### **無料プリセットの切り替え**: 「白」をタップすると選択が白へ移り、プレビューカードとページの紙地が即座に白へ変わる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/b9cdfb7e-566a-48b3-a43e-f4f44c1f68e2.jpg" width="320">

</details>

### **実画面への反映と再起動後の維持**: テーマを変更してホーム・エディタへ戻ると紙地が選んだ色になり、アプリを再起動しても同じ色が維持される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

白に変更した直後のホームとエディタ、そして terminate → launch 後のホーム。いずれも紙地が白のまま維持されている。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/27b4e3a1-1809-4167-a617-0c0b56a1dbcc.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/53a2f2c4-bb59-424d-b0ed-b72a2c840b9b.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/2c47f2cc-585f-461d-bab2-b7d15da112ab.jpg" width="320">

</details>

### **背景画像セクションの表示**: 「背景画像」は「なし」がチェック付きで選択されており、「写真から選ぶ」はまだ何も起きない (画像選択は issue #54 で実装予定)

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

「なし」(None) にチェックが付いた状態。「写真から選ぶ」(Choose from Photos) をタップしても画面は変わらず、行き止まりのクラッシュや空のシートも出ない (2 枚目はタップ後)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7f937d41-6344-42f5-be63-c50d9f59c834.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/0362d3ed-8d66-4ff7-b542-03ea84d62098.jpg" width="320">

</details>

</details>

---

## 2. Nikki Plus 限定プリセットのロック導線

- [x] **Plus 限定プリセットのロック表示**: 未加入の状態で薄鼠・青磁・桜鼠のスウォッチに錠前アイコンが付き、白・生成には付かない
  - 自動化: auto（NikkiTests/ThemePlusGateTests.swift が無料と Plus 限定の境界を検証。錠前の描画自体はシミュレータで目視確認する）
- [x] **ロックされたプリセットのタップでペイウォールが開く**: 錠前付きスウォッチをタップすると選択は「生成」のまま変わらず、Nikki Plus のペイウォールがシートで開く
  - 自動化: manual（タップからシート表示までの導線の確認のため）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **Plus 限定プリセットのロック表示**: 未加入の状態で薄鼠・青磁・桜鼠のスウォッチに錠前アイコンが付き、白・生成には付かない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7f937d41-6344-42f5-be63-c50d9f59c834.jpg" width="320">

</details>

### **ロックされたプリセットのタップでペイウォールが開く**: 錠前付きスウォッチをタップすると選択は「生成」のまま変わらず、Nikki Plus のペイウォールがシートで開く

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

錠前付きスウォッチ (青磁 / Celadon) をタップするとペイウォールがシートで開き、閉じるとテーマ画面へ戻って選択は「生成」(Cream) のまま変わらなかった。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7640cf5b-6909-4dfb-9628-c1ae97eb630d.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/fef16b04-0f31-48eb-9a7b-949ae28831eb.jpg" width="320">

</details>

</details>

---

## 3. Plus 加入状態による紙色のフォールバック

- [ ] **Plus 失効時に無料の紙色へ倒れる**: Plus 限定の紙色を選んだ状態で加入が切れると、テーマ画面の選択表示・プレビュー・実画面の紙地がいずれも「生成」に戻る
  - 自動化: auto（NikkiTests/ThemePlusGateTests.swift。実際の失効状態はシミュレータで作れないため、画面表示への反映は Sandbox / TestFlight での人間確認に回す）
  - ⏭️ スキップ: Plus 加入・失効の顧客状態は simulator では作れない。加入境界のロジックは NikkiTests/ThemePlusGateTests.swift で機械検証済みで、画面表示への反映は TestFlight 配布後の人間確認に回す
- [ ] **再加入で元の選択に戻る**: 失効後に再加入すると、失効前に選んでいた Plus 限定の紙色が選び直さずに復帰する
  - 自動化: auto（NikkiTests/ThemePlusGateTests.swift が保存値を書き換えないことを検証。実際の再加入は Sandbox / TestFlight での人間確認に回す）
  - ⏭️ スキップ: 再加入の顧客状態は simulator では作れない。保存値を書き換えないことは NikkiTests/ThemePlusGateTests.swift で機械検証済み
- [ ] **濃い紙色でのコントラスト**: 薄鼠・青磁・桜鼠を選んだ状態でホーム・エディタを見ても、本文・見出し・セパレータ・カードの境界が沈まず読める
  - 自動化: manual（コントラストの破綻はスクリーンショットの目視でしか判定できないため）
  - ⏭️ スキップ: 薄鼠・青磁・桜鼠は Plus 限定で、未加入の simulator では選択できない (タップするとペイウォールが開く)。Plus 加入後の TestFlight 人間確認に回す

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **Plus 失効時に無料の紙色へ倒れる**: Plus 限定の紙色を選んだ状態で加入が切れると、テーマ画面の選択表示・プレビュー・実画面の紙地がいずれも「生成」に戻る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **再加入で元の選択に戻る**: 失効後に再加入すると、失効前に選んでいた Plus 限定の紙色が選び直さずに復帰する

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **濃い紙色でのコントラスト**: 薄鼠・青磁・桜鼠を選んだ状態でホーム・エディタを見ても、本文・見出し・セパレータ・カードの境界が沈まず読める

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>
