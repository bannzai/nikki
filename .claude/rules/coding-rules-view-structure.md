---
paths:
  - "Nikki/Features/**/*.swift"
---

# コーディングルール（View - 構造）

このドキュメントは、SwiftUI の View に関する構造面のコーディングルールを定義します。

（memberwise initializer を優先する原則はグローバル規約 `swift-memberwise-initializer` を参照。ここでは Nikki / SwiftUI 固有の補足のみ書きます）

## Feature構造とディレクトリ構成

### 各Featureは独立したディレクトリに配置する

- 機能ごとに `Nikki/Features/{FeatureName}/` ディレクトリを作成
- 例: `Features/Home/`, `Features/Editor/`, `Features/Templates/`, `Features/Settings/`

### エントリーポイントの命名規則

- 各Featureのエントリーポイントは、Viewである限り `{FeatureName}Page` で統一（`View` サフィックスは使わない）
- Sheet形式でも `{FeatureName}Page` とする（`{FeatureName}Sheet` は使わない）
- 例: `HomePage`, `EditorPage`, `SettingsPage`, `ThemePage`, `TemplateListPage`, `TemplateVariablePage`

### コンポーネント（サブビュー）の配置と命名

- `{Feature}PageBody` 以外の private struct は、`Nikki/Features/{FeatureName}/Components/` ディレクトリに配置
- コンポーネント名は `{FeatureName}{ComponentName}` の形式で命名（Feature名をprefixとして付ける）
- ファイル名もコンポーネント名と同じにする
- 例: `Features/Paywall/Components/PaywallPlanCard.swift`

### 良い例：Feature構造

```
Features/
├── Home/
│   ├── HomePage.swift            # エントリーポイント（共通シャーシ）
│   └── Components/
│       ├── HomeListBody.swift    # Feature名が prefix、ファイル名=型名
│       └── HomeCalendarBody.swift
├── Editor/
│   ├── EditorPage.swift          # エントリーポイント
│   └── Components/
│       └── EditorParagraphBlock.swift
└── Settings/
    └── SettingsPage.swift        # エントリーポイント
```

```swift
// Features/Home/HomePage.swift
struct HomePage: View {  // ✅ {FeatureName}Page
    var body: some View {
        // ...
        HomeListBody(entries: entries)  // ✅ Feature名が prefix
    }
}

// Features/Home/Components/HomeListBody.swift
struct HomeListBody: View {  // ✅ Feature名が prefix
    // ...
}
```

## Body パターン

### いつ使うか

- エントリーポイントの `body` が分岐や複数モードで肥大化する場合、本体を `{Feature}{Role}Body` の struct に切り出す
  - 例: `HomePage` は選択モードに応じて `HomeListBody` / `HomeCalendarBody` を切り替える
- 単純な画面では Body を作らず、直接 Page に `body` を実装する
- **（非同期データ取得を導入した時）** エントリーポイントで非同期のデータ取得が必要になった場合、取得を親 View で解決し、取得成功時に `{Feature}Body` を表示する形にする
  - 現在 Nikki は非同期データ取得層（Firestore 等）を未導入。導入時にこのパターンを適用する

## 状態管理

### @State には private をつけない

- `@State` は memberwise initializer やカスタム init から初期値を渡せるように、`private` を付けない
  - テストやプレビューで初期状態を差し込めるようにするため

### 状態はコンポーネントに閉じる

- コールバック（onSuccess, onError, onSave, onComplete など）は極力書かない
- そのコンポーネントや View 内部で処理を完結させる
- どうしても書く必要がある場合はコメントに理由を残す
- 補足: Nikki の現状は画面が振る舞いを持たないスタブ段階で、`onNewEntry` / `onSelect` / `onStart` などのコールバックを多用している。実データ層・画面遷移を配線する段階で、各画面内に処理を閉じる方向へ見直す

#### コールバックを使わない例

良い例（保存も dismiss も画面内で完結）:
```swift
struct SomeSheetView: View {
    @Environment(\.dismiss) var dismiss
    @State var title: String

    var body: some View {
        Button("Save") {
            save()
            dismiss()  // 画面内で完結
        }
    }

    private func save() {
        // 保存処理
    }
}
```

悪い例（onSave コールバックで呼び出し側に処理を押し出す）:
```swift
struct SomeSheetView: View {
    let onSave: () -> Void  // ❌ コールバック
    // ...
}
```

## イニシャライザ

- View でも memberwise initializer を優先する（グローバル規約 `swift-memberwise-initializer` 参照）。ここでの補足は以下:
  - `@State var` も memberwise initializer の対象になる。`@State` の初期値を別の引数から導出したいなど、条件付き初期化が必要な場合に限りカスタム init を書き、その理由をコメントに残す
  - memberwise initializer に使用されるプロパティを struct のすぐ下に書く。その他の internal / private なプロパティをその下に書く
- **init に全てのフィールドをパラメータとして受け取ることを許容する**
  - テストやプレビューでのデータ作成を容易にするため、全フィールドを init のパラメータとして追加してよい
  - 主にテスト・プレビューでのみ使用するパラメータには、その旨をコメントで明記する
