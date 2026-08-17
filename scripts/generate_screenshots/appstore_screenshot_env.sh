#!/bin/bash
#
# appstore_screenshot_env.sh
#
# App Store スクリーンショット生成用の環境変数と共通関数を定義するスクリプト。
# 他のスクリプトから source して使用する。
#
# 【使い方】
# $ source scripts/generate_screenshots/appstore_screenshot_env.sh
#

export SCREENSHOT_PROJECT="Nikki.xcodeproj"
export SCREENSHOT_SCHEME="Nikki"

# 撮影用シミュレータ。App Store Connect の必須サイズに一致するネイティブ解像度の機種を使う。
# 他の作業と奪い合いにならないよう専用名で作成する(ensure_simulator が冪等に作成する)。
export IPHONE_SIM_NAME="Nikki-AppStore-iPhone16ProMax"
export IPHONE_SIM_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max"
export IPAD_SIM_NAME="Nikki-AppStore-iPadPro13M4"
export IPAD_SIM_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB"
# 撮影結果の再現性のため OS バージョンを固定する。インストールされていない場合は
# ensure_simulator がエラーを出すので、その時はこの値を手元のランタイムに合わせて更新する。
export SIM_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-5"

# ビルド成果物と生成画像の置き場所(すべて gitignore 対象)。
export DERIVED_DATA_IOS="tmp/DerivedData-screenshots"
export DERIVED_DATA_MAC="tmp/DerivedData-screenshots-mac"
export ARTIFACTS_DIR="scripts/generate_screenshots/artifacts"

# App Store Connect が要求するピクセルサイズ(検証に使う)。
# iphone: 6.9インチ / ipad: 13インチ / mac: 2880x1800。
expected_size() {
    case "$1" in
        iphone) echo "1320x2868" ;;
        ipad) echo "2064x2752" ;;
        mac) echo "2880x1800" ;;
        *) echo "unknown" ;;
    esac
}

# 撮影言語コードを fastlane のディレクトリ名(App Store Connect のロケール)にマッピングする。
map_language_to_fastlane() {
    case "$1" in
        ja) echo "ja" ;;
        en) echo "en-US" ;;
        *) echo "$1" ;;
    esac
}

# 指定した名前の撮影用シミュレータを冪等に用意し、UDID を出力する。
# 既存端末は SIM_RUNTIME のデバイス一覧からだけ探す(旧ランタイムの同名端末を再利用すると
# 固定 OS での再現性が失われるため。SIM_RUNTIME 更新時は新ランタイムで作り直される)。
# Usage: ensure_simulator <名前> <デバイスタイプID>
ensure_simulator() {
    local name=$1
    local device_type=$2
    local udid
    udid=$(xcrun simctl list devices --json | jq -r --arg name "$name" --arg runtime "$SIM_RUNTIME" '.devices[$runtime] // [] | .[] | select(.name == $name and .isAvailable) | .udid' | head -1)
    if [ -z "$udid" ]; then
        udid=$(xcrun simctl create "$name" "$device_type" "$SIM_RUNTIME")
    fi
    echo "$udid"
}

# PNG のピクセルサイズが期待値と一致するか検証する。不一致なら異常終了する。
# Usage: verify_png_size <PNGパス> <device(iphone|ipad|mac)>
verify_png_size() {
    local png=$1
    local device=$2
    local actual
    actual=$(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w"x"h}')
    if [ "$actual" != "$(expected_size "$device")" ]; then
        echo "Error: $png のサイズが $actual (期待: $(expected_size "$device"))" >&2
        return 1
    fi
}
