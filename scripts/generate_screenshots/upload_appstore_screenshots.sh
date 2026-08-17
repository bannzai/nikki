#!/bin/bash
#
# upload_appstore_screenshots.sh
#
# fastlane deliver で fastlane/screenshots を App Store Connect にアップロードするスクリプト。
# iOS (iPhone 6.9インチ / iPad 13インチ) と macOS (2880x1800) は ASC 上のプラットフォームが
# 別のため、deliver を2回に分けて実行する。メタデータ・バイナリには触れない(スクショのみ)。
#
# 認証は環境変数の App Store Connect API キーを使う:
#   ASC_API_KEY_ID / ASC_API_KEY_ISSUER_ID / ASC_API_KEY_P8_BASE64
#
# 【使い方】
# $ ./scripts/generate_screenshots/upload_appstore_screenshots.sh [ios|osx|all]
#
# 引数:
#   $1: アップロード対象プラットフォーム(省略時 all)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$SCRIPT_DIR/../.."

TARGET=${1:-all}
APP_IDENTIFIER="com.bannzai.Nikki"

# secret を空値で使わないよう、書き込み前に非空を確認する。
[ -n "${ASC_API_KEY_ID:-}" ] || { echo "Error: ASC_API_KEY_ID is empty" >&2; exit 1; }
[ -n "${ASC_API_KEY_ISSUER_ID:-}" ] || { echo "Error: ASC_API_KEY_ISSUER_ID is empty" >&2; exit 1; }
[ -n "${ASC_API_KEY_P8_BASE64:-}" ] || { echo "Error: ASC_API_KEY_P8_BASE64 is empty" >&2; exit 1; }

# API キー JSON はリポジトリ外の一時ファイルに作り、終了時に必ず消す(秘匿情報を作業ツリーに残さない)。
API_KEY_JSON=$(mktemp -t nikki-asc-api-key)
trap 'rm -f "$API_KEY_JSON"' EXIT
jq -n \
    --arg key_id "$ASC_API_KEY_ID" \
    --arg issuer_id "$ASC_API_KEY_ISSUER_ID" \
    --arg key "$(echo "$ASC_API_KEY_P8_BASE64" | base64 -d)" \
    '{key_id: $key_id, issuer_id: $issuer_id, key: $key, in_house: false}' > "$API_KEY_JSON"

# deliver は screenshots_path 配下のロケールディレクトリだけを見るため、
# iOS 実行時に fastlane/screenshots/macos が誤って混ざることはない(逆も同様)。
if [ "$TARGET" = "ios" ] || [ "$TARGET" = "all" ]; then
    echo "==== Uploading iOS screenshots (iPhone 6.9 / iPad 13) ===="
    fastlane deliver \
        --api_key_path "$API_KEY_JSON" \
        --app_identifier "$APP_IDENTIFIER" \
        --platform ios \
        --screenshots_path fastlane/screenshots \
        --skip_binary_upload \
        --skip_metadata \
        --skip_app_version_update \
        --overwrite_screenshots \
        --run_precheck_before_submit false \
        --force
fi

if [ "$TARGET" = "osx" ] || [ "$TARGET" = "all" ]; then
    echo "==== Uploading macOS screenshots (2880x1800) ===="
    fastlane deliver \
        --api_key_path "$API_KEY_JSON" \
        --app_identifier "$APP_IDENTIFIER" \
        --platform osx \
        --screenshots_path fastlane/screenshots/macos \
        --skip_binary_upload \
        --skip_metadata \
        --skip_app_version_update \
        --overwrite_screenshots \
        --run_precheck_before_submit false \
        --force
fi

echo "==== Upload completed ===="
