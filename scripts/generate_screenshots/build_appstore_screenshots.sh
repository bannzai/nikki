#!/bin/bash
#
# build_appstore_screenshots.sh
#
# App Store スクリーンショット撮影テストを build-for-testing で事前ビルドするスクリプト。
# iphone / ipad は同じ iphonesimulator ビルドを共有し、mac は macOS ビルドを行う。
#
# 【使い方】
# $ ./scripts/generate_screenshots/build_appstore_screenshots.sh [ios|mac|all]
#
# 引数:
#   $1: ビルド対象(省略時 all)。ios = iPhone/iPad 共用のシミュレータビルド、mac = macOS ビルド
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$SCRIPT_DIR/../.."

source scripts/generate_screenshots/appstore_screenshot_env.sh

TARGET=${1:-all}

if [ "$TARGET" = "ios" ] || [ "$TARGET" = "all" ]; then
    echo "==== Building for iOS Simulator (iPhone / iPad 共用) ===="
    IPHONE_UDID=$(ensure_simulator "$IPHONE_SIM_NAME" "$IPHONE_SIM_DEVICE_TYPE")
    xcodebuild build-for-testing \
        -project "$SCREENSHOT_PROJECT" \
        -scheme "$SCREENSHOT_SCHEME" \
        -destination "platform=iOS Simulator,id=$IPHONE_UDID" \
        -derivedDataPath "$DERIVED_DATA_IOS" \
        -skipPackagePluginValidation
fi

if [ "$TARGET" = "mac" ] || [ "$TARGET" = "all" ]; then
    echo "==== Building for macOS ===="
    xcodebuild build-for-testing \
        -project "$SCREENSHOT_PROJECT" \
        -scheme "$SCREENSHOT_SCHEME" \
        -destination "platform=macOS" \
        -derivedDataPath "$DERIVED_DATA_MAC" \
        -skipPackagePluginValidation
fi

echo "==== Build completed ===="
