<!-- ai-review-config begin -->
<!--
このブロックは自動生成です。直接編集せず、テンプレートを更新してから再生成してください。
内容は AI コードレビュー時の挙動指示であり、コードベース自体への規約ではありません。
-->

## レビュー時の応答スタイル

- 応答は日本語で行う

## レビュー範囲外

以下は自動レビューで指摘しない (別の検出経路があるため):

- コンパイルエラー・型エラー (ローカル/CI のビルドで検出される)
- Lint/フォーマット違反 (リンター・フォーマッターで検出される)
<!-- ai-review-config end -->

## プラットフォーム別の動作確認

Nikki は同一コードで iOS と macOS の両方をビルドする。プラットフォームで挙動が違うことが予想される変更
(コンテキストメニュー・ジェスチャ・キーボードショートカット・ウィンドウ/シートの出し方・`#if os(...)` を含む変更など) は、
ビルドが通っただけで完了とせず、iOS と macOS の両方で実際に動作確認し、それぞれのスクリーンショットを撮って PR に添付する。
片方のプラットフォームで検証できなかった場合は、未検証であることと理由を PR に明記する
(実例: コンテキストメニューが iOS の長押しでは動き、macOS の右クリックでは開けなかった https://github.com/bannzai/nikki/pull/43 )。

## シミュレータでの動作確認は simtunnel を使う

iOS Simulator を使う動作確認・E2E・スクリーンショット撮影は、ローカル Mac の simulator ではなく
simtunnel (GitHub Actions macOS Runner 上のリモート simulator。起動 workflow: `.github/workflows/simulator-session.yml`) を使う。
経路の判断と起動・接続の手順は ios-simulator skill の Phase 1 に従う。
simtunnel が利用できない場合 (Actions 障害・tailnet 未接続等) に限りローカル simulator を代替として使ってよく、
その場合は理由を PR に明記する。
