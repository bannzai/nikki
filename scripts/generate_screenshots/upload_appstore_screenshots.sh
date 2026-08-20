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

# 未対応の対象名 (mac 等のタイプミス) だと deliver を一度も呼ばずに成功終了してしまうため、
# 認証情報・一時ファイルを扱う前に検証して弾く。
case "$TARGET" in
    ios | osx | all) ;;
    *) echo "Error: 不明な対象: $TARGET (ios | osx | all)" >&2; exit 1 ;;
esac

# secret を空値で使わないよう、書き込み前に非空を確認する。
[ -n "${ASC_API_KEY_ID:-}" ] || { echo "Error: ASC_API_KEY_ID is empty" >&2; exit 1; }
[ -n "${ASC_API_KEY_ISSUER_ID:-}" ] || { echo "Error: ASC_API_KEY_ISSUER_ID is empty" >&2; exit 1; }
[ -n "${ASC_API_KEY_P8_BASE64:-}" ] || { echo "Error: ASC_API_KEY_P8_BASE64 is empty" >&2; exit 1; }

# API キー JSON はリポジトリ外の一時ファイルに作り、終了時に必ず消す(秘匿情報を作業ツリーに残さない)。
# 秘密鍵はプロセス一覧から見える jq の引数に載せず、権限を絞った一時ファイル経由(--rawfile)で渡す。
API_KEY_JSON=$(mktemp -t nikki-asc-api-key)
API_KEY_P8=$(mktemp -t nikki-asc-api-key-p8)
trap 'rm -f "$API_KEY_JSON" "$API_KEY_P8"' EXIT
chmod 600 "$API_KEY_JSON" "$API_KEY_P8"
echo "$ASC_API_KEY_P8_BASE64" | base64 -d > "$API_KEY_P8"
jq -n \
    --arg key_id "$ASC_API_KEY_ID" \
    --arg issuer_id "$ASC_API_KEY_ISSUER_ID" \
    --rawfile key "$API_KEY_P8" \
    '{key_id: $key_id, issuer_id: $issuer_id, key: $key, in_house: false}' > "$API_KEY_JSON"

# --overwrite_screenshots は ASC 上の既存スクリーンショットを置き換えるため、
# 部分生成のままアップロードすると未生成ぶんが公開候補から消える。全数が揃っている時だけ実行する。
# Usage: verify_complete_screenshots <ベースディレクトリ> <device...>
verify_complete_screenshots() {
    local base=$1
    shift
    local missing=0
    for locale in ja en-US; do
        for page in 1 2 3 4 5 6; do
            for device in "$@"; do
                if [ ! -f "$base/$locale/${page}_${device}.png" ]; then
                    echo "Error: $base/$locale/${page}_${device}.png がありません" >&2
                    missing=1
                fi
            done
        done
    done
    if [ "$missing" -ne 0 ]; then
        echo "Error: スクリーンショットが揃っていません。generate_appstore_screenshots.sh で全デバイス・全言語・全ページを生成してから実行してください" >&2
        return 1
    fi
}

# all のときに iOS だけ揃っていて macOS が欠けていると、iOS の deliver 後に失敗して
# ASC の iOS 側だけ更新された状態で止まる。外部状態を変更する前に対象全プラットフォームを検証する。
if [ "$TARGET" = "ios" ] || [ "$TARGET" = "all" ]; then
    verify_complete_screenshots fastlane/screenshots/ios iphone ipad
fi
if [ "$TARGET" = "osx" ] || [ "$TARGET" = "all" ]; then
    verify_complete_screenshots fastlane/screenshots/macos mac
fi

# 同一アップロードに含まれるデバイス同士が同じコード世代から生成されているかを検証する
# (iPhone だけ再生成して古い iPad 画像と混ぜて公開しないため)。
# Usage: verify_same_generation <マーカーファイル...>
verify_same_generation() {
    local reference=""
    local marker
    for marker in "$@"; do
        if [ ! -f "$marker" ]; then
            echo "Error: 生成世代マーカーがありません: $marker (generate_appstore_screenshots.sh で生成し直してください)" >&2
            return 1
        fi
        if [ -z "$reference" ]; then
            reference=$(cat "$marker")
        elif [ "$(cat "$marker")" != "$reference" ]; then
            echo "Error: デバイス間で生成世代が一致しません ($*)。全デバイスを同じコードから生成し直してください" >&2
            return 1
        fi
    done
}

if [ "$TARGET" = "ios" ]; then
    verify_same_generation fastlane/screenshots/ios/.generation-iphone fastlane/screenshots/ios/.generation-ipad
elif [ "$TARGET" = "osx" ]; then
    verify_same_generation fastlane/screenshots/macos/.generation-mac
else
    verify_same_generation fastlane/screenshots/ios/.generation-iphone fastlane/screenshots/ios/.generation-ipad fastlane/screenshots/macos/.generation-mac
fi

if [ "$TARGET" = "ios" ] || [ "$TARGET" = "all" ]; then
    echo "==== Uploading iOS screenshots (iPhone 6.9 / iPad 13) ===="
    fastlane deliver \
        --api_key_path "$API_KEY_JSON" \
        --app_identifier "$APP_IDENTIFIER" \
        --platform ios \
        --screenshots_path fastlane/screenshots/ios \
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
