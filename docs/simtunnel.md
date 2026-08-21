---
title: simtunnel (リモート iOS Simulator)
---

# simtunnel でリモート iOS Simulator 上の Nikki を動かす

GitHub Actions の macOS Runner 上で iOS Simulator を起動し、Tailscale (tailnet) 越しにローカルから操作・スクリーンショット取得する経路。ローカル Mac のリソースを使わずに動作確認 (QA・ローカライズ確認) を行うために使う。仕組み・設計・制約の SSOT は https://github.com/bannzai/simtunnel の PROJECT.md。

## 構成

- caller workflow: `.github/workflows/simulator-session.yml` (`workflow_dispatch` のみ)
  - `build` job: `Nikki.xcodeproj` の `Nikki` scheme を Simulator 向け Debug でビルドし、`Nikki.app` を artifact `simulator-app` に上げる。LicenseList の BuildToolPlugin の信頼確認を省くために `-skipPackagePluginValidation` が必要なため、simtunnel 側の `build_project` 入力ではなく caller 側でビルドする (Makefile の `ios` ターゲットと同じ理由)
  - `session` job: `bannzai/simtunnel` の reusable workflow `session.yml` (commit SHA 固定) を呼び、Simulator 起動 → artifact の `.app` を install / launch → WebDriverAgent 起動 → tailnet 参加までを行う
- 認証: Tailscale の OIDC (workload identity federation)。長期シークレットは持たず、リポジトリの Actions secrets `TS_OIDC_CLIENT_ID` / `TS_OIDC_AUDIENCE` (識別子) を参照する

## 初回セットアップ (リポジトリ管理者)

1. Tailscale 側で、このリポジトリの OIDC subject を許可する trust credential が発行済みであることを確認する (手順は simtunnel PROJECT.md「Tailscale セットアップ手順」)
2. Actions secrets を登録する。値が空のまま実行すると空値で上書きされるため、登録前に非空を確認する

   ```sh
   [ -n "$TS_OIDC_CLIENT_ID" ] || { echo "TS_OIDC_CLIENT_ID is empty" >&2; exit 1; }
   [ -n "$TS_OIDC_AUDIENCE" ] || { echo "TS_OIDC_AUDIENCE is empty" >&2; exit 1; }
   gh secret set TS_OIDC_CLIENT_ID -R bannzai/nikki --body "$TS_OIDC_CLIENT_ID"
   gh secret set TS_OIDC_AUDIENCE -R bannzai/nikki --body "$TS_OIDC_AUDIENCE"
   ```

## セッションの起動・操作・終了

操作する Mac が tailnet に接続済みであることが前提。

```sh
# 起動 (検証したいブランチを --ref で指定する。省略すると main がビルドされる)
simtunnel up nikki --ref <branch> --wait

# スクリーンショット (MJPEG ストリームから 1 フレーム取得)
simtunnel screenshot nikki ./tmp/screenshot.png

# ブラウザで見る・操作する
simtunnel preview nikki

# AI agent (mobile-mcp 互換) から操作する場合は .mcp.json を書き込んでからセッションを開始する
simtunnel mcp-config nikki . --name mobile

# 終了 (放置しても duration_minutes で自動終了する)
simtunnel down nikki
```

`simtunnel` は bannzai/simtunnel の `local/simtunnel` CLI。このリポジトリの作業ディレクトリで実行すれば対象リポジトリは自動で解決される (別ディレクトリからは `SIMTUNNEL_REPO=bannzai/nikki` を付ける)。CLI を使わない場合は `gh workflow run simulator-session.yml -R bannzai/nikki -f session=nikki` で dispatch し、tailnet 上の `simtunnel-nikki` (`:8100` WebDriverAgent / `:9100` MJPEG) を直接叩く。

## 制約

- Debug ビルドは開発用ストアを使うため CloudKit 同期は行われない。Simulator には署名なしの `.app` を入れる
- runner の Simulator は英語ロケール。日本語 UI を確認する時は、Simulator の設定アプリから端末言語を切り替えるのではなく、アプリを `-AppleLanguages (ja) -AppleLocale ja_JP` の起動引数付きで起動してアプリプロセスの表示言語だけを ja にする。設定アプリでの端末言語切り替えは SpringBoard を再起動させ、その巻き添えで WDA (XCUITest runner) が落ち、session workflow が全 WDA の無応答を検知してセッションごと終了させてしまう。起動引数は WDA の `POST /session/<sid>/wda/apps/launch` の `arguments` で渡す (`ios-wda.sh launch` は bundleId しか送らないため直接 POST する)。この経路では OS 側の UI (システムダイアログ・キーボード・App Store の通貨) は英語 / US のまま
- 所要時間の目安: ビルド + セッション準備で 15 分程度。macOS runner の並列上限 (Free プランで 5) はアカウント全体で共有するため、使い終わったら `down` する
- public リポジトリのため Actions のログ・artifact (スクリーンショット含む) は公開される
- Maestro / XCUITest / `xcrun simctl` を伴う検証はローカルからリモート Simulator に対して実行できない。ローカルの Simulator で行う
