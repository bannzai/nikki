---
paths:
  - "Nikki/Features/**/*.swift"
  - "Nikki/DesignSystem/**/*.swift"
---

# コーディングルール（View - UI記述）

このドキュメントは、SwiftUI の View に関するUI記述のコーディングルールを定義します。

（UI 変更後のスクリーンショット検証はグローバル規約 `ui-change-screenshot-verification` を参照。ここでは重複させません）

## UIの記述

### Viewは構造体で定義する

- View は `var someView: some View` のようにプロパティで宣言しない
- 必ず `struct SomeView: View` のように構造体で定義する（`private var header: some View` のような computed property でのサブビュー宣言も禁止。ViewModifier の `body(content:)` や `View` extension のモディファイア関数はこの規約の対象外）

### .padding

- 意味なく `.padding(.top)` / `.bottom` / `.leading` / `.trailing` の単辺だけを使うのは避け、対称に効かせたい箇所は `.vertical` / `.horizontal` でレイアウトを整える
- ただしデザイン上、非対称な余白が必要な箇所（見出し下の余白、セパレータの leading インセットなど）では単辺指定を使ってよい。単辺指定は「対称化できるのに単辺にしている」ものだけを避ける

### Section header

- **SwiftUI の `Section` の header に置く `Text` には `.textCase(nil)` を追加する**
- `Section` はデフォルトで header の `Text` を大文字に変換する（`.textCase(.uppercase)` が自動適用される）
- 文字列をそのまま表示するため、`.textCase(nil)` で大文字変換を無効化する

### alert/confirmationDialog/sheet の命名

- alert / confirmationDialog / sheet の表示状態に使うプロパティ名は、`{usecase|feature name}{Alert|ConfirmationDialog|Sheet}IsPresented` のように命名する
- 例: `deleteConfirmationDialogIsPresented`, `paywallSheetIsPresented`

## enum と View

- **enum に表示用の文字列やアイコンを返すプロパティは持たせない**
- `var label: String` や `var systemImage: String` のような表示ロジックは enum ではなく View に書く
- enum は純粋なデータ型として定義し、表示に関するロジックは使用側（View）で switch 文を使って判定する
- 例外: enum の説明文を生成する場合でも、View 内で switch 文を使って判定する

## Slot-based Layout

- コンポーネント設計は Slot-based Layout の原則に従う（詳細は `component-design-slotbased.md` / `component-design-examples.md`）
- **ドメインを表す Feature コンポーネント**では、UI 要素（String, Color, UUID 等）を抽象化して渡さず、具体的な型（`JournalEntry`, `Block`, `JournalTemplate` 等）をそのまま渡す
- 異なる型には個別のコンポーネントを作成する
- 例外: 挙動が完全に同じで型だけが異なる場合、enum argument で型を受け取ることを許容する（プロパティ名は実態がわかるように省略せず宣言する）
- 補足: `Nikki/DesignSystem/` の `Ink*` コンポーネントは SwiftUI 標準の `Button` / `Label` と同様の汎用プリミティブであり、`title: String` などのプリミティブを受け取ってよい。上のルールはドメインデータを扱う Feature コンポーネントを対象とする

## `.disabled()` と `.onTapGesture` の組み合わせの禁止

- toolbar, ToolbarItem, Menu などのフレームワーク固有の挙動がある箇所では `.disabled()` + `.onTapGesture` パターンを使用しない。代わりに、Button の action 内に全てのロジック（条件分岐含む）を記述する

### 悪い例

```swift
Button {
    doSomething()
}
.disabled(!hasPremium)
.onTapGesture {
    if !hasPremium {
        showPaywall = true
    }
}
```

### 良い例

```swift
Button {
    if !hasPremium {
        showPaywall = true
    } else {
        doSomething()
    }
} label: { ... }
```
