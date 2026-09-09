---
paths:
  - "Nikki/Features/**/*.swift"
  - "Nikki/DesignSystem/**/*.swift"
---

# コンポーネント設計: enum argument の例外

基本原則は `component-design-slotbased.md` を参照する。

- 表示内容・ロジック・挙動が完全に同じで型だけが異なる場合に限り、enum argument を許容する
- associated value で具体的な型を保持し、プロパティ名は値の実態を明確にする
- 同じフォームを使うモーダル・シート・編集画面が適用候補になる
- リスト行は個別コンポーネントを優先する。表示内容が異なるカードや、エンティティ固有の情報が多い詳細画面も個別にする
- SwiftData `@Model` 導入時も、モデルには `headingLevel` / `paragraphText` のように具体的なプロパティを持たせる。enum argument を理由に、意味が不明な `kind` / `value` へまとめない
