---
paths:
  - "Nikki/Features/**/*.swift"
  - "Nikki/DesignSystem/**/*.swift"
---

# SwiftUI Component Design Guide - Slot-based Layout

このドキュメントでは、Nikki プロジェクトにおけるコンポーネント設計の原則とベストプラクティスを説明します。

## Slot-based Layoutの原則

SwiftUIの基本思想は**Slot-based Layout**です。これは、コンポーネントが特定の「スロット（slot）」を定義し、そこに子要素やViewを配置する設計パターンです。

### Slot-based Layoutとは

- コンポーネントが「構造」を提供し、呼び出し側が「内容」を提供する
- プリミティブ値（String, Color, Int）ではなく、**View自体**を受け取る
- 柔軟性と再利用性を高めながら、型安全性を保つ

### SwiftUIの標準コンポーネントもSlot-based

SwiftUIの標準コンポーネントは、すべてslot-basedな設計になっています。

```swift
// Labelはtitleスロットとiconスロットを持つ
Label {
    Text("Home")  // titleスロット
} icon: {
    Image(systemName: "house")  // iconスロット
}

// VStackはcontentスロットで子Viewを受け取る
VStack {
    Text("Title")     // contentスロット
    Text("Subtitle")
}
```

Nikki のデザインシステムでも、`InkListSection` は `@ViewBuilder let content` でスロットを受け取ります。

```swift
struct InkListSection<Content: View>: View {
    @ViewBuilder let content: Content
    // content スロットに行 View を並べて使う
}
```

### なぜプリミティブ値を渡すのが悪いのか

UI要素（String, Color, UUID等）を抽象化して**ドメインコンポーネント**に渡すと、以下の問題が発生します：

1. **柔軟性の欠如**: 文字列やカラーだけでは、複雑なUIを表現できない
2. **型安全性の喪失**: `title: String` では、どのエンティティのタイトルか分からない
3. **関心の混在**: コンポーネントが「データの抽出方法」を知る必要がある
4. **拡張性の欠如**: 新しいプロパティが必要になるたびに引数が増える

### Slot-basedアプローチの利点

1. **柔軟性**: 新機能追加時にコンポーネント自体を変更する必要がない
2. **関心の分離**: コンポーネントは内容について知る必要がない
3. **型安全性**: 具体的な型（`JournalEntry`, `Block`）を渡すことで、存在しないプロパティへのアクセスを防ぐ
4. **可読性**: コードの意図が明確になる

## Component分割の原則

### 基本ルール

- **具体的な型を渡す**: ドメインを表す Feature コンポーネントでは、UI 要素や ID を抽象化せず、具体的な型（`JournalEntry`, `Block`, `JournalTemplate` 等）をそのまま渡す
- **個別のコンポーネントを作成**: 異なる型には異なるコンポーネントを用意する
- **類似レイアウトをコメントで明記**: 似たようなレイアウトのコンポーネントがある場合、コメントで相互参照する
- **Genericsは慎重に使用**: 本当に必要な場合のみ Generics で型安全に抽象化する
- **デザインシステムのプリミティブは例外**: `Nikki/DesignSystem/` の `Ink*` コンポーネントは SwiftUI 標準の `Button` / `Label` に相当する汎用プリミティブなので、`title: String` 等を受け取ってよい

### 方法1: 具体的な型を渡す（推奨）

ほとんどの場合、この方法で十分です。

```swift
// 日記1件を表す行コンポーネント
struct HomeEntryRow: View {
    let entry: JournalEntry  // ✅ 具体的な型
    let showsSeparator: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(SampleData.calendar.component(.day, from: entry.date))")  // entry のプロパティを直接使用
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                Text(entry.excerpt)
            }
        }
    }
}

// 使用側
ForEach(entries) { entry in
    HomeEntryRow(entry: entry, showsSeparator: true)  // ✅ 具体的な型を渡す
}
```

### 方法2: Genericsで型安全なSlotを定義する（高度な共通化が必要な場合）

本当に必要な場合のみ、この方法を使用してください。

```swift
struct RowLayout<Indicator: View, Content: View>: View {
    @ViewBuilder let indicator: () -> Indicator  // indicatorスロット
    @ViewBuilder let content: () -> Content      // contentスロット

    var body: some View {
        HStack {
            indicator()  // スロットに渡されたViewを配置
            content()
        }
    }
}
```
