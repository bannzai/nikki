---
paths:
  - "Nikki/Features/**/*.swift"
  - "Nikki/DesignSystem/**/*.swift"
---

# SwiftUI Component Design Guide - 悪い例と例外パターン

このドキュメントでは、コンポーネント設計の悪い例と、原則の例外パターンを説明します。

## 悪い例：ドメインデータを UI 要素に抽象化する

```swift
// ❌ 日記の行を UI プリミティブに分解して受け取るドメインコンポーネント
struct HomeEntryRow: View {
    let day: Int          // ❌ 日付を Int で抽象化
    let title: String     // ❌ タイトルを String で抽象化
    let excerpt: String   // ❌ 抜粋を String で抽象化
    let showsSeparator: Bool

    var body: some View {
        HStack {
            Text("\(day)")
            VStack {
                Text(title)
                Text(excerpt)
            }
        }
    }
}

// 使用側も複雑になる
ForEach(entries) { entry in
    HomeEntryRow(
        day: SampleData.calendar.component(.day, from: entry.date),  // ❌ 抽出
        title: entry.title,       // ❌ 抽出
        excerpt: entry.excerpt,   // ❌ 抽出
        showsSeparator: true
    )
}
```

### この悪い例の問題点

1. `JournalEntry` が持つ情報（date, blocks 由来の excerpt など）を毎回呼び出し側で抽出する必要がある
2. 新しい表示要素が必要になるたびに引数が増える
3. コンポーネントが「JournalEntry からどう値を取り出すか」を呼び出し側に押し付けている
4. コードの意図が不明確で、何を表示しているのか分かりづらい

`entry: JournalEntry` をそのまま渡せば、これらの問題は起きません。

## 原則の例外：Enum Argument パターン

基本的には具体的な型を個別のコンポーネントで受け取るべきですが、**挙動が完全に同じで型だけが異なる場合**に限り、enum argument で型を受け取ることを許容します。

### 例外が許容される条件

1. **挙動が完全に同じ**: 表示内容やロジックに違いがない
2. **型安全性を保つ**: enum の associated value で具体的な型を保持する
3. **プロパティ名を明確にする**: 抽象的な命名（`itemID`, `itemName`）を避ける

### 良い例：Enum Argument

```swift
struct BlockEditSheetView: View {
    enum Argument {
        case heading(id: UUID, level: Int, text: String)
        case paragraph(id: UUID, text: String)
    }

    let argument: Argument

    var body: some View {
        Form {
            switch argument {
            case let .heading(_, level, text):
                Text("Heading H\(level)")
                Text(text)
            case let .paragraph(_, text):
                Text(text)
            }
            // 以降の編集フォームの挙動は同じ
        }
    }
}
```

### この例外が有効なケース

- **モーダルやシート**: 表示内容や挙動が同じで、データ型だけが異なる場合
- **編集画面**: 複数の型で編集フォームのレイアウトや挙動が完全に同じ場合

### この例外を使うべきでないケース

- **リスト行**: それぞれのコンポーネントを作成した方が良い
- **カード表示**: 表示内容が異なる場合は個別コンポーネント
- **詳細画面**: 各エンティティ固有の情報が多い場合

## （SwiftData `@Model` 導入時）モデルの設計

enum argument を使う場合でも、SwiftData モデルは具体的なプロパティを持つべきです（現在 Nikki の Model は値型のため、導入時に適用する）：

```swift
// ✅ 良い例：具体的なプロパティ
@Model
final class Block {
    var headingLevel: Int?
    var paragraphText: String?
    // ...
}

// ❌ 悪い例：抽象的なプロパティ
@Model
final class Block {
    var kind: BlockKind  // ❌ 型情報を失う
    var value: String    // ❌ 何の値か不明
    // ...
}
```

## まとめ

- **具体的な型を渡す**ことを基本とする（ドメインを表す Feature コンポーネント）
- **UI要素を抽象化しない**（String, Color, UUID等）
- **Slot-based Layout**の考え方を活用する
- **Genericsは本当に必要な場合のみ**使用する
- **類似レイアウトはコメントで明記**して、開発者が参照できるようにする
- **原則の例外**: 挙動が完全に同じ場合のみ enum argument を許容する
- **プロパティ名は実態を明確にする**
- **デザインシステムの `Ink*` プリミティブは対象外**（`title: String` 等を受け取ってよい）
