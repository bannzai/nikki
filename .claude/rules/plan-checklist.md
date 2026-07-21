---
paths:
  - ".plans/*.md"
---

# Plan ファイルチェックリスト

Plan mode でプランファイルを作成する際、以下のチェックリストをプランファイル末尾に追記すること。

前提スタック: SwiftUI（iOS / iPadOS / macOS 対応、deployment target iOS 18）。
将来導入予定: SwiftData + CloudKit（永続化・同期、README / issue #1）。現時点でテスト・多言語化・課金・Analytics は未導入。

## ルール

- 変更対象に応じて該当セクションのみ含める
- チェック項目は `- [ ]` 形式で記載
- プランには必ず変更対象ファイルごとに具体的な実装コード提案（コードブロック）を含めること

## チェックリストテンプレート

以下をプランファイル末尾に追記する。

---

## チェックリスト

### 実装内容
- [ ] 変更対象ファイルごとに具体的なコード提案をコードブロックで記載している
- [ ] 既存コードのパターン・構成（`Nikki/Features/**`, `Nikki/DesignSystem/**`, `Nikki/Models/**`）を確認し、同じパターンで実装している
- [ ] 変更範囲が必要最小限であること

### ビルド
- [ ] `xcodebuild build -project Nikki.xcodeproj -scheme Nikki -destination 'platform=iOS Simulator,name=<起動中のシミュレータ>'` が成功する（ログ全文を `./tmp` に保存し warning / error を grep で検査）

### UI（画面変更がある場合）
- [ ] `/ios-simulator`（`/sim-manager`）でプロジェクト用シミュレータを起動し、`/verify-ui-mobile-mcp` 等で実機挙動を目視確認（スクリーンショット取得）

### 共通
- [ ] エラーメッセージはそのまま表示（加工・プレフィックス除去なし）

---

## 導入時に追加するセクション

以下の機能を Nikki に導入した段階で、対応するチェック項目・ルールファイルを追加する（Focus から再移植する）:

- **SwiftData（永続化・スキーマ変更）**: 新規プロパティはプリミティブ型の Optional で宣言 / origin/main スキーマからのマイグレーション検証
- **多言語化**: `Text` / `String(localized:)` を英文で記述し `// ja:` コメントを付与 / 翻訳ファイルの整備（`localization-guidelines.md` を再移植）
- **テスト**: ユニットテスト・スナップショット・E2E の実行（`testing-guidelines.md` を再移植）
- **Analytics**: イベント名は制限文字数以内・ハードコード・ボタン押下と処理成功の両方
- **フォーマッター**: `swift-format` 等を導入した場合、新規・編集ファイルへの適用を必須にする
