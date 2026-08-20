#!/bin/bash
#
# organize_appstore_screenshots.sh
#
# xcresulttool で抽出したスクリーンショットを fastlane 形式に整理するスクリプト。
# manifest.json の suggestedHumanReadableName
# (例: "AppStoreScreenshot---appstore1---ja---0_0_UUID.png") をパースし、
# ピクセルサイズを検証してから fastlane/screenshots に配置する。
#
# 配置先:
#   iphone / ipad: fastlane/screenshots/ios/{ロケール}/{ページ}_{device}.png
#   mac:           fastlane/screenshots/macos/{ロケール}/{ページ}_{device}.png
#   (deliver は screenshots_path 直下のディレクトリをロケールとして読むため、
#    プラットフォームごとに互いを含まないルートに分ける)
#
# 【使い方】
# $ ./scripts/generate_screenshots/organize_appstore_screenshots.sh <device>
#
# 引数:
#   $1: device - iphone | ipad | mac (artifacts/raw/{device}/ を入力にする)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$SCRIPT_DIR/../.."

source scripts/generate_screenshots/appstore_screenshot_env.sh

DEVICE=$1
RAW_DIR="$ARTIFACTS_DIR/raw/$DEVICE"
MANIFEST="$RAW_DIR/manifest.json"

if [ ! -f "$MANIFEST" ]; then
    echo "Error: manifest.json がありません: $MANIFEST (先に run_appstore_screenshots.sh を実行する)" >&2
    exit 1
fi

case "$DEVICE" in
    iphone | ipad) FASTLANE_BASE="fastlane/screenshots/ios" ;;
    mac) FASTLANE_BASE="fastlane/screenshots/macos" ;;
    *)
        echo "Error: 不明な device: $DEVICE (iphone | ipad | mac)" >&2
        exit 1
        ;;
esac

echo "==== Organizing $DEVICE screenshots to $FASTLANE_BASE ===="

# 部分生成(言語・ページの絞り込み)で撮った分だけを上書きすると、同じデバイスの未選択画像に
# 古い実装の画像が残ったまま全数チェックを通ってしまう。同デバイスの旧出力を先にすべて消し、
# 全数チェックが「今回のコードで生成した一式」だけを数えるようにする(全数生成で再び揃う)。
find "$FASTLANE_BASE" -type f -name "*_${DEVICE}.png" -delete 2>/dev/null || true

# デバイスごとに「どのコードから生成したか」の世代マーカーを残す。
# アップロード側が同一アップロードに含まれるデバイス間 (iphone と ipad 等) で一致を検証し、
# 片方だけ再生成した新旧混在の一式を公開しないようにする。
# 指紋はここで再計算せず、撮影時に run スクリプトが保存したものをコピーする
# (撮影後のソース変更で古い画像へ新しい世代が付かないようにするため)。
if [ ! -f "$RAW_DIR/.generation" ]; then
    echo "Error: 撮影時の世代マーカーがありません: $RAW_DIR/.generation (run_appstore_screenshots.sh から撮り直してください)" >&2
    exit 1
fi
mkdir -p "$FASTLANE_BASE"
cp "$RAW_DIR/.generation" "$FASTLANE_BASE/.generation-$DEVICE"

jq -c '.[] | .attachments[]' "$MANIFEST" | while read -r attachment; do
    exported_file=$(echo "$attachment" | jq -r '.exportedFileName')
    suggested_name=$(echo "$attachment" | jq -r '.suggestedHumanReadableName')
    source_file="$RAW_DIR/$exported_file"
    if [ ! -f "$source_file" ]; then
        echo "Warning: ファイルがありません: $source_file" >&2
        continue
    fi

    # "AppStoreScreenshot---appstore{N}---{lang}---..." をパースする。
    page=$(echo "$suggested_name" | awk -F'---' '{print $2}' | sed 's/appstore//')
    language=$(echo "$suggested_name" | awk -F'---' '{print $3}')
    if [ -z "$page" ] || [ -z "$language" ]; then
        echo "Warning: 想定外の名前形式: $suggested_name" >&2
        continue
    fi

    verify_png_size "$source_file" "$DEVICE"

    output_dir="$FASTLANE_BASE/$(map_language_to_fastlane "$language")"
    mkdir -p "$output_dir"
    cp "$source_file" "$output_dir/${page}_${DEVICE}.png"
    echo "Organized: appstore$page ($language) -> $output_dir/${page}_${DEVICE}.png"
done

echo "==== Organization completed ===="
