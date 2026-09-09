---
paths:
  - "Nikki/Features/**/*.swift"
  - "Nikki/DesignSystem/**/*.swift"
---

# コンポーネント設計: Slot-based Layout

- レイアウトは構造を提供し、呼び出し側が View のスロットに内容を渡す
- ドメインを表す Feature コンポーネントには、UI 要素や ID に分解せず具体的な型をそのまま渡す
- 異なる型には個別のコンポーネントを用意する。enum argument を許容する条件は `component-design-examples.md` を参照する
- 類似レイアウトのコンポーネントはコメントで相互参照する
- Generics は高度な共通化が必要な場合に用い、型安全な View のスロットを定義する
- `Nikki/DesignSystem/` の `Ink*` は汎用プリミティブなので、`title: String` 等を受け取ってよい
