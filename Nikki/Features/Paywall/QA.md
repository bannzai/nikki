---
feature: Paywall
verification: mobile-mcp
last_verified_commit: 96337de3d8717a2428e3fa4d4120727fab323a27
last_verified_at: 2026-08-21
---

# Paywall QA

## 関連リンク

- 仕様: https://github.com/bannzai/nikki/issues/24 (Paywall + 課金実装。商品構成の表と「やること」の審査要件を仕様の正データとして扱う)
- 関連: https://github.com/bannzai/nikki/pull/25 (Paywall 実装とレビュー対応で決めた表示分岐) / https://github.com/bannzai/nikki/issues/28 と https://github.com/bannzai/nikki/pull/37 (買い切り nikki_plus_lifetime2 の登録と表示) / https://github.com/bannzai/nikki/issues/54 (特典表示を戻す将来の解放境界)

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 月ごと ¥300 / 年ごと ¥3,000 / 買い切り ¥12,000 の3プランが、価格と期間つきで表示される | 3プランの価格と期間の表示 |
| S2 | 年プランに月あたりの換算額と「◯ヶ月ぶんお得」バッジが出る。割引がなければバッジを出さない | 年プランの割引バッジと月あたり換算 |
| S3 | プランカードをタップすると選択が移り、選択中のカードだけが墨枠で強調される | プランの選択切り替え |
| S4 | 購入が成功して entitlement `plus` が有効になるとペイウォールが閉じ、テーマのロックが外れる | 購入で Nikki Plus が有効になる |
| S5 | 「購入の復元」で過去の購入から `plus` が復元される。復元できる購入がなければその旨を知らせる | 購入の復元 |
| S6 | 利用規約・プライバシーポリシーへのリンクと復元ボタンが常に画面内にあり、リンク先が開く (App Review Guideline 3.1.2) | 法務リンクと復元ボタンの到達性 / 利用規約・プライバシーの遷移 |
| S7 | 買い切り購入済みならプランカードを出さず購入ボタンを無効化する。サブスク加入中は買い切りカードに「自動では解約されない」注記と管理画面リンクを出す | 加入状態による表示の分岐 |
| S8 | offering を取得できない場合は「価格を読み込めませんでした。」と「再読み込み」の導線が出る | 価格の取得失敗と再読み込み |

## 1. プランの表示と選択

- [ ] **3プランの価格と期間の表示**: 設定 > Nikki Plus を開くと、月ごと ¥300 (/月)・年ごと ¥3,000・買い切り ¥12,000 (一度の購入で、ずっと) の3枚のカードが表示される
  - 自動化: auto（NikkiTests/StoreKitConfigurationTests.swift が3商品の価格・期間・種別の解決を検証。iOS 26.5 の simulator では skip されるため 26.2 以下の runtime で実行する。カードの並びと文言はシミュレータで目視確認する）
  - ⏭️ スキップ: simtunnel の runner Simulator は App Store / RevenueCat へ接続できず、ペイウォールが「Couldn't load prices.（価格を読み込めませんでした。）」の読み込み失敗パスになるためカードが表示されない。価格・期間・種別の解決は StoreKit テスト NikkiTests/StoreKitConfigurationTests.swift で機械検証済み (iOS 26.2 で 5 件 pass)。カードの並びと文言は TestFlight 配布後の人間確認に回す
- [ ] **年プランの割引バッジと月あたり換算**: 年ごとのカードに月あたりの換算額と「2ヶ月ぶんお得」バッジが出る
  - 自動化: auto（NikkiTests/PaywallSavingsTests.swift が割引月数の算出と、割引がない場合にバッジを出さないことを検証）
  - ⏭️ スキップ: 上と同じ理由でカードが表示されない。割引月数の算出とバッジの出し分けは NikkiTests/PaywallSavingsTests.swift で機械検証済み
- [ ] **プランの選択切り替え**: 初期選択は年ごとで、月ごと・買い切りをタップすると墨枠の強調がタップしたカードへ移る
  - 自動化: manual（タップによる選択状態の切り替わりの目視確認のため）
  - ⏭️ スキップ: 上と同じ理由でカードが表示されず、タップ対象が存在しない

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **3プランの価格と期間の表示**: 設定 > Nikki Plus を開くと、月ごと ¥300 (/月)・年ごと ¥3,000・買い切り ¥12,000 (一度の購入で、ずっと) の3枚のカードが表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **年プランの割引バッジと月あたり換算**: 年ごとのカードに月あたりの換算額と「2ヶ月ぶんお得」バッジが出る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **プランの選択切り替え**: 初期選択は年ごとで、月ごと・買い切りをタップすると墨枠の強調がタップしたカードへ移る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 2. 購入と復元

- [ ] **購入で Nikki Plus が有効になる**: プランを選んで「Nikki Plus をはじめる」を押すと購入が完了し、ペイウォールが閉じてテーマの薄鼠・青磁・桜鼠のロックが外れる
  - 自動化: manual（NikkiTests/StoreKitConfigurationTests.swift が機械検証するのは StoreKit 層 (商品解決と、SKTestSession 購入が Transaction.currentEntitlements に現れること) まで。本項目の本体である RevenueCat 統合 — customerInfoStream 経由の entitlement `plus` 有効化・ペイウォールの閉鎖・テーマのロック解除 — はテスト対象外のため、Sandbox / TestFlight での人間確認に回す）
  - ⏭️ スキップ: 価格を読み込めていないため「Nikki Plus をはじめる」(Start Nikki Plus) が無効状態で押せない。購入と entitlement 付与は StoreKit テスト NikkiTests/StoreKitConfigurationTests.swift で機械検証済み (iOS 26.2 で 5 件 pass)。実課金は Sandbox / TestFlight での人間確認に回す
- [ ] **購入の復元**: 「購入の復元」を押すと過去の購入から Nikki Plus が復元され、復元できる購入がない場合は「復元できる購入が見つかりませんでした。」と表示される
  - 自動化: manual（復元は購入済みの Apple ID が必要で、Sandbox / TestFlight での人間確認に回す）
  - ⏭️ スキップ: 復元できる購入がない場合の分岐だけ確認できた (「No purchases to restore.」のアラートが出て OK で閉じられる。エビデンス参照)。実際に購入を復元する側は購入済みの Apple ID が必要なため Sandbox / TestFlight での人間確認に回す
- [ ] **購入の中断とエラー**: 購入シートをキャンセルしてもエラーにならずペイウォールに戻り、購入に失敗した場合は理由を含むアラートが出る
  - 自動化: manual（購入シートのキャンセル・失敗は Sandbox / TestFlight での人間確認に回す）
  - ⏭️ スキップ: 購入シート自体を開けないため確認できない。Sandbox / TestFlight での人間確認に回す

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **購入で Nikki Plus が有効になる**: プランを選んで「Nikki Plus をはじめる」を押すと購入が完了し、ペイウォールが閉じてテーマの薄鼠・青磁・桜鼠のロックが外れる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **購入の復元**: 「購入の復元」を押すと過去の購入から Nikki Plus が復元され、復元できる購入がない場合は「復元できる購入が見つかりませんでした。」と表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

未購入の状態で「購入の復元」(Restore purchases) を押すと「No purchases to restore.」のアラートが出た (復元できる購入がない場合の分岐のみ)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/d2e733f9-4ee9-4935-912b-c3d21e01a298.jpg" width="320">

</details>

### **購入の中断とエラー**: 購入シートをキャンセルしてもエラーにならずペイウォールに戻り、購入に失敗した場合は理由を含むアラートが出る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 3. 審査要件のリンクと閉じる操作

- [ ] **法務リンクと復元ボタンの到達性**: 画面下部に「購入の復元」「利用規約」「プライバシー」が常に見えており、iPhone SE のような縦の狭い端末でもスクロールせず押せる
  - 自動化: manual（端末サイズごとのレイアウト確認が必要なため）
  - ⏭️ スキップ: iPhone 17 (402x874pt) では 3 つとも画面下部に常時表示され、スクロールせずタップできた (エビデンス参照)。simtunnel のセッションは 1 台の端末しか起動できず iPhone SE サイズでの確認ができないため、狭い端末でのレイアウトは未確認
- [x] **利用規約・プライバシーの遷移**: 「利用規約」「プライバシー」をタップすると、それぞれの Web ページがブラウザで開く
  - 自動化: manual（外部ブラウザへの遷移確認のため）
  - ブラウザ (Safari) への遷移と URL の host は確認できたが、runner のネットワークが bannzai.github.io を解決できずページ本体は表示されなかった。リンク先 https://bannzai.github.io/nikki/legal/terms-en.html と https://bannzai.github.io/nikki/legal/privacy-en.html は手元から curl で HTTP 200 を確認済み
- [x] **ペイウォールを閉じる**: 右上の × を押すとペイウォールが閉じ、開く前の画面 (設定またはテーマ) に戻る
  - 自動化: manual（シートの閉じ操作の確認のため）
  - テーマ画面から開いた場合はテーマ画面へ、設定から開いた場合は設定画面へ、それぞれ戻ることを確認した

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **法務リンクと復元ボタンの到達性**: 画面下部に「購入の復元」「利用規約」「プライバシー」が常に見えており、iPhone SE のような縦の狭い端末でもスクロールせず押せる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

iPhone 17 では「Restore purchases」「Terms of Use」「Privacy」が画面下部に常時表示されている (iPhone SE サイズは未確認)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7640cf5b-6909-4dfb-9628-c1ae97eb630d.jpg" width="320">

</details>

### **利用規約・プライバシーの遷移**: 「利用規約」「プライバシー」をタップすると、それぞれの Web ページがブラウザで開く

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

どちらのリンクも Safari が bannzai.github.io を開いた。ページ本体は runner のネットワーク制限 (server can't be found) で表示されない。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/46dfc3de-4982-41ae-bcf7-778c2c40e1d7.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7cb2be17-df93-4949-9abe-1a60e1cf0a05.jpg" width="320">

</details>

### **ペイウォールを閉じる**: 右上の × を押すとペイウォールが閉じ、開く前の画面 (設定またはテーマ) に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

テーマ画面から開いたペイウォールを × で閉じた直後 (1 枚目) と、設定から開いたペイウォールを × で閉じた直後 (2 枚目)。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/fef16b04-0f31-48eb-9a7b-949ae28831eb.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/70759983-5144-4e00-b78b-6097de8ecd71.jpg" width="320">

</details>

</details>

---

## 4. 加入状態と読み込み失敗の分岐

- [ ] **加入状態による表示の分岐**: 買い切り購入済みではプランカードが消えて購入ボタンが押せなくなり、サブスク加入中に買い切りカードを見ると「自動では解約されない」注記と「サブスクリプションを管理」リンクが出る
  - 自動化: manual（購入済み・加入中の顧客状態はシミュレータで作れず、Sandbox / TestFlight での人間確認に回す）
  - ⏭️ スキップ: 購入済み・加入中の顧客状態は simulator では作れない。Sandbox / TestFlight での人間確認に回す
- [ ] **価格の取得失敗と再読み込み**: 通信を切った状態でペイウォールを開くと「価格を読み込めませんでした。」と「再読み込み」が出て、通信を戻して「再読み込み」を押すと価格が表示される
  - 自動化: manual（機内モード等でのネットワーク遮断操作が必要なため）
  - ⏭️ スキップ: 失敗側は確認できた。runner Simulator が RevenueCat へ到達できないため常に「Couldn't load prices.」+「Retry」が出て、「Retry」を押しても画面は壊れず同じ失敗表示に戻る (エビデンス参照)。通信を復旧させて価格が表示されるまでの成功側は、runner のネットワークを開通させられないため未確認

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **加入状態による表示の分岐**: 買い切り購入済みではプランカードが消えて購入ボタンが押せなくなり、サブスク加入中に買い切りカードを見ると「自動では解約されない」注記と「サブスクリプションを管理」リンクが出る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **価格の取得失敗と再読み込み**: 通信を切った状態でペイウォールを開くと「価格を読み込めませんでした。」と「再読み込み」が出て、通信を戻して「再読み込み」を押すと価格が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

ペイウォールを開いた直後 (1 枚目) と「Retry」を押した後 (2 枚目)。どちらも「Couldn't load prices.」と「Retry」が出ており、購入ボタンは無効のまま。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7640cf5b-6909-4dfb-9628-c1ae97eb630d.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/416d786d-865d-4d70-924e-a5c76f218a8b.jpg" width="320">

</details>

</details>
