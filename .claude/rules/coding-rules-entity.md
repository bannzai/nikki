---
paths:
  - "Nikki/Models/**/*.swift"
---

# コーディングルール（Model/データ層）

このドキュメントは、Model（値型・将来の SwiftData `@Model` 等）やデータ層に関するコーディングルールを定義します。

Nikki の `Nikki/Models/` は現在プレーンな値型（`JournalEntry` / `Block` / `JournalTemplate` / `ChecklistItem` / `SampleData`）で構成されています。README のとおり将来 SwiftData + CloudKit を導入予定のため、SwiftData 固有のルールは「導入時に適用」と明記して残します。

（構造の定義に付けるドキュメントコメント（`///`）はグローバル規約 `document-definitions` を参照。ここでは重複させません）

## 命名規則

### 変数名には通常、動詞（editing, selected等）をつけない

- Feature名やコンテキスト自体がその役割を表しているため、変数名は名詞のみで良い
- 例: 編集画面内では `editingEntry` ではなく `entry`
- 例: 選択状態を表す画面内では `selectedTemplate` ではなく `template`
- どうしても必要な場合はコメントで理由を明記する

### （SwiftData / UserDefaults 導入時）AppStorage のkey名と変数名は一致させる

- `UserDefaults+.swift` 等で定義された key 名と、`@AppStorage` で使用する変数名を同じにする
- 理由: key名と変数名が一致していることで、どの UserDefaults キーを使用しているか一目で分かる
- 現在 Nikki には `@AppStorage` / UserDefaults キー定義はまだ無い。導入時に適用する

## 文字列とローカライゼーション

### （多言語化導入時）永続化されるデータの文字列は翻訳済みのものにする

- SwiftData モデルや同期対象に保存する文字列プロパティは、多言語化の仕組み（`String(localized:)` 等）を通した値にする
- Preview のサンプルデータも同様にする
- 文言は `Nikki/Localizable.xcstrings`（String Catalog）で管理する。キーは英語（開発言語 = en）で書き、日本語は翻訳として持つ。SwiftUI の `Text("...")` 等はそのままキーになり、`String` を受け取る箇所は `String(localized:)` を通す
- 日付の表記は `Date.formatted(localizedPattern:)`（`Nikki/Models/Date+.swift`）で、DateFormatter のパターン自体を String Catalog で言語別に持つ（日本語はデザイン見本の表記を保ち、英語は App Store スクリーンショットの表記に合わせるため）

## プロパティ設計

### 保存側で不要な値をnilにする処理は本質的ではない

- enum やフラグで使用するプロパティが変わる場合、保存側で「使わない方を nil にする」処理は不要
- 保存側はそのままの状態で保存する
- 使用側で enum や flag を switch して適切なプロパティを使用すればよい
- どこまでいっても使用側はプロパティの扱いに注意が必要。保存側で気を遣っても本質的な問題は解決しない
- コメントで使用方法を明記する

### （SwiftData `@Model` 導入時）プロパティ更新はドメインメソッド経由で行い、updatedDateTime を必ず更新する

- SwiftData `@Model` エンティティで外部から更新されるプロパティは `private(set)` にし、ドメインメソッド（セッター）を経由して更新する
- ドメインメソッド内で必ず `updatedDateTime = .now` を更新する
- SwiftData には CoreData の `willSave` のようなモデルレベルのフックが存在しないため、ドメインメソッドで一貫して updatedDateTime を更新する運用で対応する
- `onChange(of:)` 等でエンティティの変更を検知する場合は、個別プロパティではなく `updatedDateTime` を監視する
- 現在 Nikki の Model は値型のため未適用。SwiftData 導入時に適用する

#### 導入時の例

```swift
@Model
final class JournalEntry {
    private(set) var title: String
    private(set) var updatedAt: Date = Date.now

    /// title を更新し、updatedAt も同時に更新する。
    func setTitle(_ title: String) {
        self.title = title
        self.updatedAt = .now
    }
}
```

### enum に表示用の文字列やアイコンを返すプロパティは持たせない

- `var label: String` や `var systemImage: String` のような表示ロジックは enum ではなく View に書く
- enum は純粋なデータ型として定義し、表示に関するロジックは使用側（View）で switch 文を使って判定する
- 例外: enum の説明文を生成する場合でも、View 内で switch 文を使って判定する
