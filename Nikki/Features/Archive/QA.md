---
feature: Archive
verification: mobile-mcp
last_verified_commit: d98adda51bb84172361270215c3648563c4899ea
last_verified_at: 2026-08-21
---

# Archive QA

## 関連リンク

- 仕様: 仕様なし QA (要望 issue https://github.com/bannzai/nikki/issues/42 は「日記をアーカイブできる機能が欲しい。削除でなくて良い」のみで、期待挙動を定義した正データがないため、実装済みの挙動を QA 項目の基準にする)
- 関連: https://github.com/bannzai/nikki/pull/43 (アーカイブ機能の実装) / https://github.com/bannzai/nikki/pull/44 (macOS の右クリックと行の余白でメニューが開かなかった不具合の修正) / https://github.com/bannzai/nikki/issues/45 (コンテキストメニューを XCUITest で自動検証する)

## 1. ホームからのアーカイブ

- [x] **コンテキストメニューからアーカイブする**: ホームの日記行を長押し (iOS) してコンテキストメニューを開いて「アーカイブ」を選ぶと、その行がホームの一覧から消える
  - 自動化: manual（NikkiUITests/ContextMenuUITests.swift はメニュー表示のみ検証し、CI (.github/workflows/test.yml) は -only-testing:NikkiTests のため UI テスト自体が実行されない。アーカイブ実行と一覧の変化はシミュレータで目視確認する）
  - iOS Simulator の長押しで確認した
- [x] **行の余白でもメニューが開く**: タイトルが短い日記でも、テキストが載っていない行の余白で長押し (iOS) してコンテキストメニューを開ける
  - 自動化: manual（NikkiUITests/ContextMenuUITests.swift はメニュー表示のみ検証し、CI (.github/workflows/test.yml) は -only-testing:NikkiTests のため UI テスト自体が実行されない。シミュレータで目視確認する）
  - 抜粋のない行の右下 (テキストが載っていない余白) を長押ししてメニューが開くことを確認した
- [x] **アーカイブ結果が再起動後も残る**: アーカイブした直後にアプリを終了して起動し直しても、その日記はホームに戻らずアーカイブされたままになっている
  - 自動化: manual（アプリの再起動をまたぐ永続化の確認のため）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **コンテキストメニューからアーカイブする**: ホームの日記行を長押し (iOS) してコンテキストメニューを開いて「アーカイブ」を選ぶと、その行がホームの一覧から消える

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

長押しで「Archive」メニューが開き、選ぶとその行 (抜粋のない「August 21, 2026」) がホームの一覧から消えて 4 件 → 3 件になった。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/c8ef20be-5073-432b-a7e8-d6a3be5a1c2d.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/e15c0600-4e8d-46df-886f-858b9010b08b.jpg" width="320">

</details>

### **行の余白でもメニューが開く**: タイトルが短い日記でも、テキストが載っていない行の余白で長押し (iOS) してコンテキストメニューを開ける

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

タイトルだけで抜粋がない行の、テキストが載っていない右下の余白を長押ししてメニューが開いた。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/c8ef20be-5073-432b-a7e8-d6a3be5a1c2d.jpg" width="320">

</details>

### **アーカイブ結果が再起動後も残る**: アーカイブした直後にアプリを終了して起動し直しても、その日記はホームに戻らずアーカイブされたままになっている

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

terminate → launch 後もホームは 3 件のままで、アーカイブした行は戻っていない。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/1176d329-8577-4e48-80a2-f447e0a1a8c7.jpg" width="320">

</details>

</details>

---

## 2. アーカイブ一覧の表示

- [x] **アーカイブした日記の一覧**: 設定 > アーカイブした日記 を開くと、アーカイブ済みの日記だけが月見出し + 日付・タイトル・抜粋の行で表示される
  - 自動化: manual（一覧のレイアウトの目視確認のため）
  - 設定の該当行は英語ロケールでは「Archived entries」と表示される。確認時の一覧は 1 件で、アーカイブ済みだけが表示されることと行のレイアウトを確認した
- [ ] **アーカイブ一覧の複数件の並び順**: アーカイブが複数件・複数月あるとき、ホームと同じ月まとめで新しい順に並ぶ
  - 自動化: manual（複数件・複数月のアーカイブを用意して目視で確認する）
  - ⏭️ スキップ: 確認時のアーカイブは 1 件のみで、UI から過去日の日記を作れず複数月のデータも用意できない。複数件のデータができた時点の QA で確認する
- [x] **一覧から日記を開く**: 一覧の行をタップするとその日記のエディタが開き、戻るとアーカイブ一覧に戻る
  - 自動化: manual（画面遷移と復帰の確認のため）
- [x] **空状態**: アーカイブした日記が1件もないときは「アーカイブした日記はありません。」と、長押しでアーカイブできる旨の案内 (iOS) が表示される
  - 自動化: manual（プラットフォームごとに案内文が切り替わるため目視確認する）
  - iOS では「No archived entries.」と「Press and hold an entry on Home to tuck it away here.」(長押しの案内) が表示された

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **アーカイブした日記の一覧**: 設定 > アーカイブした日記 を開くと、アーカイブ済みの日記だけが月見出し + 日付・タイトル・抜粋の行で表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/7b0924ee-d8a5-4dc1-adf2-aebb841e1d99.jpg" width="320">

</details>

### **一覧から日記を開く**: 一覧の行をタップするとその日記のエディタが開き、戻るとアーカイブ一覧に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/9beb84a6-61e6-43e3-9a9c-dfece704ab87.jpg" width="320">

</details>

### **空状態**: アーカイブした日記が1件もないときは「アーカイブした日記はありません。」と、長押しでアーカイブできる旨の案内 (iOS) が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/9dd02032-9120-4e39-9d7d-dc867bdc145e.jpg" width="320">

</details>

### **アーカイブ一覧の複数件の並び順**: アーカイブが複数件・複数月あるとき、ホームと同じ月まとめで新しい順に並ぶ

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 3. アーカイブから戻す

- [x] **アーカイブから戻す**: アーカイブ一覧の行を長押し (iOS) してコンテキストメニューを開いて「アーカイブから戻す」を選ぶと、その行が一覧から消え、ホームの日付順の元の位置に戻る
  - 自動化: manual（一覧とホームの両方の変化を追う操作のため）
  - メニュー項目は英語ロケールでは「Unarchive」と表示される
- [x] **最後の1件を戻すと空状態になる**: アーカイブが1件だけの状態でそれを戻すと、一覧が空状態の表示に切り替わる
  - 自動化: manual（空状態への切り替わりの目視確認のため）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **アーカイブから戻す**: アーカイブ一覧の行を長押し (iOS) してコンテキストメニューを開いて「アーカイブから戻す」を選ぶと、その行が一覧から消え、ホームの日付順の元の位置に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**

長押しで「Unarchive」メニューが開き、選ぶと一覧から消えてホームの日付順の位置 (最後尾) に戻った。

<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/04ca4444-0211-4ff1-8a1c-a4001da5b509.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/253ee654-a66a-44f6-8df3-620ad8f5a50b.jpg" width="320">

</details>

### **最後の1件を戻すと空状態になる**: アーカイブが1件だけの状態でそれを戻すと、一覧が空状態の表示に切り替わる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-21**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/nikki/20260821/9dd02032-9120-4e39-9d7d-dc867bdc145e.jpg" width="320">

</details>

</details>

---

## 4. macOS の操作経路

- [ ] **macOS の右クリックでアーカイブを操作できる**: macOS でホームの日記行・アーカイブ一覧の行を右クリックするとコンテキストメニューが開き、「アーカイブ」「アーカイブから戻す」を実行できる。空状態の案内文も右クリックの案内になる
  - 自動化: manual（macOS ビルドでのマウス操作を伴うため）
  - ⏭️ スキップ: 本 QA は iOS Simulator (simtunnel) のみで実施。macOS はローカル macOS ビルドでの確認に回す

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **macOS の右クリックでアーカイブを操作できる**: macOS でホームの日記行・アーカイブ一覧の行を右クリックするとコンテキストメニューが開き、「アーカイブ」「アーカイブから戻す」を実行できる。空状態の案内文も右クリックの案内になる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>
