#!/bin/bash
#
# run_appstore_screenshots.sh
#
# 事前ビルド済みの撮影テストを test-without-building で実行し、xcresult から
# スクリーンショットを抽出して artifacts/raw/{device}/ に置くスクリプト。
#
# 【使い方】
# $ ./scripts/generate_screenshots/run_appstore_screenshots.sh <device> [LANGUAGES] [PAGES]
#
# 引数:
#   $1: device - iphone | ipad | mac | duo-outer | duo-inner
#   $2: LANGUAGES - 撮影する言語(カンマ区切り。省略時は ja,en の全言語)
#   $3: PAGES - 撮影するページ番号(カンマ区切り。省略時は全6ページ)
#
# 言語・ページの絞り込みは TEST_RUNNER_ プレフィックス機構でテストランナープロセスに
# SNAPSHOT_LANGUAGES / SNAPSHOT_PAGES として引き渡す。
#
# duo-outer / duo-inner は generate_duo_screenshots.sh から呼ぶ (simulator の姿勢の切り替えは呼び出し側が行う)。
# 撮影するキャンバス (duoOuter / duoInner) を SNAPSHOT_CANVAS として渡し、
# 環境変数 SNAPSHOT_HOST_CAPTURE_DIR があれば SNAPSHOT_HOST_CAPTURE_DIR としてテストに渡す
# (内側ディスプレイをホスト側で撮るための同期用。AppStoreScreenshotSnapshotUITests を参照)。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$SCRIPT_DIR/../.."

source scripts/generate_screenshots/appstore_screenshot_env.sh

DEVICE=$1
LANGUAGES=${2:-""}
PAGES=${3:-""}

# 撮影テストは通常の xcodebuild test に混ざらないよう SNAPSHOT_ENABLED が無ければスキップするため、
# パイプラインからだけ明示的に有効化する。
export TEST_RUNNER_SNAPSHOT_ENABLED=1
if [ -n "$LANGUAGES" ]; then
    export TEST_RUNNER_SNAPSHOT_LANGUAGES="$LANGUAGES"
fi
if [ -n "$PAGES" ]; then
    export TEST_RUNNER_SNAPSHOT_PAGES="$PAGES"
fi

# xcodebuild の既定では simulator の clone でテストを実行する。iPhone Duo の clone は閉じた姿勢で起動し、
# 元の simulator を開いた姿勢にしても反映されないため、Duo では clone を使わせない
# (appstore-screenshot-builder skill の references/iphone-duo.md の SwiftUI の節 2 番)。
PARALLEL_TESTING_OPTIONS=()

case "$DEVICE" in
    iphone)
        UDID=$(ensure_simulator "$IPHONE_SIM_NAME" "$IPHONE_SIM_DEVICE_TYPE")
        DESTINATION="platform=iOS Simulator,id=$UDID"
        ONLY_TESTING="NikkiUITests/AppStoreScreenshotSnapshotUITests/testSnapshot"
        DERIVED_DATA="$DERIVED_DATA_IOS"
        ;;
    ipad)
        UDID=$(ensure_simulator "$IPAD_SIM_NAME" "$IPAD_SIM_DEVICE_TYPE")
        DESTINATION="platform=iOS Simulator,id=$UDID"
        ONLY_TESTING="NikkiUITests/AppStoreScreenshotSnapshotUITests/testSnapshot"
        DERIVED_DATA="$DERIVED_DATA_IOS"
        ;;
    mac)
        DESTINATION="platform=macOS"
        ONLY_TESTING="NikkiTests/AppStoreScreenshotRenderTests/testRenderMacScreenshots"
        DERIVED_DATA="$DERIVED_DATA_MAC"
        ;;
    duo-outer | duo-inner)
        UDID=$(ensure_simulator "$DUO_SIM_NAME" "$DUO_SIM_DEVICE_TYPE" "$DUO_SIM_RUNTIME")
        DESTINATION="platform=iOS Simulator,id=$UDID"
        ONLY_TESTING="NikkiUITests/AppStoreScreenshotSnapshotUITests/testSnapshot"
        DERIVED_DATA="$DERIVED_DATA_DUO"
        PARALLEL_TESTING_OPTIONS=(-parallel-testing-enabled NO)
        if [ "$DEVICE" = "duo-outer" ]; then
            export TEST_RUNNER_SNAPSHOT_CANVAS="duoOuter"
        else
            export TEST_RUNNER_SNAPSHOT_CANVAS="duoInner"
        fi
        if [ -n "${SNAPSHOT_HOST_CAPTURE_DIR:-}" ]; then
            export TEST_RUNNER_SNAPSHOT_HOST_CAPTURE_DIR="$SNAPSHOT_HOST_CAPTURE_DIR"
        fi
        ;;
    *)
        echo "Error: 不明な device: $DEVICE (iphone | ipad | mac | duo-outer | duo-inner)" >&2
        exit 1
        ;;
esac

RESULT_BUNDLE="$ARTIFACTS_DIR/raw/$DEVICE.xcresult"
RAW_DIR="$ARTIFACTS_DIR/raw/$DEVICE"

# xcodebuild は既存の xcresult があると失敗するため毎回消す(冪等)。
rm -rf "$RESULT_BUNDLE" "$RAW_DIR"
mkdir -p "$RAW_DIR"

# 生成世代の指紋は撮影開始時点で確定して撮影結果と一緒に保存する
# (organize 時に再計算すると、撮影後にソースを変えた場合に古い画像へ新しい世代が付くため)。
screenshot_source_fingerprint > "$RAW_DIR/.generation"

echo "==== Running snapshot test on $DEVICE ===="
xcodebuild test-without-building \
    -project "$SCREENSHOT_PROJECT" \
    -scheme "$SCREENSHOT_SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:"$ONLY_TESTING" \
    -resultBundlePath "$RESULT_BUNDLE" \
    -derivedDataPath "$DERIVED_DATA" \
    ${PARALLEL_TESTING_OPTIONS[@]+"${PARALLEL_TESTING_OPTIONS[@]}"}

echo "==== Exporting attachments ===="
xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$RAW_DIR"

echo "==== Run completed: $RAW_DIR ===="
