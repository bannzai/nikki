#!/bin/bash
#
# generate_duo_screenshots.sh
#
# 折りたたみ端末 iPhone Duo 用の App Store スクリーンショット (外側ディスプレイ・内側ディスプレイ) を、
# 既存の撮影テスト (NikkiUITests/AppStoreScreenshotSnapshotUITests) を iPhone Duo の simulator で動かして生成する。
# 作り方は appstore-screenshot-builder skill の references/iphone-duo.md (SwiftUI の節) に従う。
#
#   1. iPhone Duo の simulator (appstore_screenshot_env.sh の DUO_SIM_NAME) を用意して起動する
#   2. 撮影テストを Duo 向けにビルドする (build_appstore_screenshots.sh duo)
#   3. 閉じた姿勢 (外側ディスプレイ) で撮影テストを実行し、XCTAttachment の画像を {言語}/outer/{ページ}.png に置く
#   4. 開いた姿勢 (内側ディスプレイ) で撮影テストを実行し、テストがページを表示するたびに
#      ホスト側で `xcrun simctl io <UDID> screenshot --display=primary-1` を撮って {言語}/inner/{ページ}.png に置く
#      (内側は XCTest の API では仕様の寸法で撮れないため。テストとの同期は撮影テストのコメントを参照)
#   5. alpha を落とし、verify_duo_screenshots.sh で寸法・alpha・枚数を機械検証する
#   6. simulator を閉じた姿勢に戻す (simulator の停止は呼び出し側で `xcrun simctl shutdown <UDID>` を行う)
#
# 内側ディスプレイは横向き (2853x2007 px) で作る。開いた姿勢の simulator は向きが landscapeRight になり、
# simctl が回転なしで 2853x2007 を返すため (references/iphone-duo.md「決めること」)。
#
# 出力先は fastlane deliver が読まない DUO_OUTPUT_DIR (scripts/generate_screenshots/artifacts/duo/{言語}/{outer|inner}/{ページ}.png)。
# deliver は画像の px 寸法で表示クラスを判定し、Duo の寸法を受け付けず、fastlane/screenshots/ に置くと
# アップロード全体が止まるため (references/iphone-duo.md「アップロード経路」)。App Store Connect への上げ方は README「iPhone Duo」。
#
# 【使い方】
# $ ./scripts/generate_screenshots/generate_duo_screenshots.sh [-l LANGUAGES] [-n PAGES] [--display outer|inner|both] [--skip-build]
#
# オプション:
#   -l LANGUAGES : 撮影する言語(カンマ区切り。例 "ja"。省略時 ja,en)
#   -n PAGES     : 撮影するページ番号(カンマ区切り。例 "1,3"。省略時 全6ページ)
#   --display    : outer / inner / both (省略時 both)。機械検証は両方が揃う both の時だけ行う
#   --skip-build : build-for-testing を省略する(ビルド済みで再撮影だけしたい時)
#
# 環境変数:
#   DUO_POSE_SH : 姿勢を切り替えるスクリプト (既定: ~/.claude/skills/ios-simulator/scripts/duo-pose.sh)
#
# 前提:
#   - Xcode 27.1 以降と iOS 27.1 のランタイム (iPhone Duo の simulator はそれ以降にしか無い)
#   - ImageMagick (magick)、jq
#   - duo-pose.sh が Device Hub のウィンドウをアクセシビリティ API で操作するため、ローカルの Mac で実行する
#     (リモートの simulator では姿勢を切り替えられない)
#
# 【終了コード】
#   0: 生成と機械検証がすべて成功
#   1: 失敗 (撮影の失敗・機械検証の NG を含む)
#   2: 引数不正
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$SCRIPT_DIR/../.."

source scripts/generate_screenshots/appstore_screenshot_env.sh

LANGUAGES="ja,en"
PAGES="1,2,3,4,5,6"
DISPLAY_TARGET="both"
SKIP_BUILD=false
DUO_POSE_SH="${DUO_POSE_SH:-$HOME/.claude/skills/ios-simulator/scripts/duo-pose.sh}"

while [ $# -gt 0 ]; do
    case "$1" in
        -l) LANGUAGES=$2; shift 2 ;;
        -n) PAGES=$2; shift 2 ;;
        --display) DISPLAY_TARGET=$2; shift 2 ;;
        --skip-build) SKIP_BUILD=true; shift ;;
        *) echo "Error: 不明なオプション: $1" >&2; exit 2 ;;
    esac
done

# 撮影テスト側のフィルタで空になり「1枚も生成されないのに成功扱い」になる値を、実行前に弾く
# (generate_appstore_screenshots.sh と同じ「カンマだけで分割」の規則)。
validate_csv() {
    local label=$1
    local raw=$2
    local allowed=$3
    local item ok
    IFS=',' read -ra items <<< "$raw"
    if [ "${#items[@]}" -eq 0 ]; then
        echo "Error: ${label}が1つも指定されていません: '$raw'" >&2
        exit 2
    fi
    for item in "${items[@]}"; do
        ok=false
        for candidate in $allowed; do
            if [ "$item" = "$candidate" ]; then
                ok=true
            fi
        done
        if [ "$ok" = false ]; then
            echo "Error: 不明な${label}: '$item' ($allowed のカンマ区切り)" >&2
            exit 2
        fi
    done
}
validate_csv "言語" "$LANGUAGES" "ja en"
validate_csv "ページ番号" "$PAGES" "1 2 3 4 5 6"
case "$DISPLAY_TARGET" in
    outer | inner | both) ;;
    *) echo "Error: --display は outer / inner / both のどれかを指定してください: $DISPLAY_TARGET" >&2; exit 2 ;;
esac

if [ ! -f "$DUO_POSE_SH" ]; then
    echo "Error: 姿勢を切り替えるスクリプトがありません: $DUO_POSE_SH (ios-simulator skill の duo-pose.sh)" >&2
    exit 1
fi

# simulator を用意して起動する (既に起動済みなら simctl boot が失敗するだけなので無視する)。
DUO_UDID=$(ensure_simulator "$DUO_SIM_NAME" "$DUO_SIM_DEVICE_TYPE" "$DUO_SIM_RUNTIME")
echo "==== iPhone Duo simulator: $DUO_UDID ($DUO_SIM_NAME) ===="
xcrun simctl boot "$DUO_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$DUO_UDID" -b
# 撮影の再現性のため、他のデバイスと同じくライト外観に揃える (撮影テスト側でも設定するが、
# ホスト側で撮る内側ディスプレイは OS の外観がそのまま写るため、ここでも揃える)。
xcrun simctl ui "$DUO_UDID" appearance light

# 姿勢を切り替える。起動直後は有効なディスプレイを判定できず STATUS=ERROR になることがあるため、
# 間をおいて再試行する (references/iphone-duo.md の SwiftUI の節 3 番)。
set_pose() {
    local pose=$1
    local attempt
    for attempt in 1 2 3 4 5; do
        if bash "$DUO_POSE_SH" set --udid "$DUO_UDID" "$pose"; then
            # 切り替えの直後は描画が追いつかないことがあるため、少し待ってから撮る (ios-simulator skill Phase 2)。
            sleep 5
            return 0
        fi
        echo "姿勢の切り替えに失敗しました (${attempt} 回目)。待ってから再試行します" >&2
        sleep 5
    done
    echo "Error: 姿勢を ${pose} に切り替えられませんでした" >&2
    return 1
}

# 終了時は外側ディスプレイ (閉じた姿勢) に戻す。
trap 'bash "$DUO_POSE_SH" set --udid "$DUO_UDID" closed > /dev/null 2>&1 || true' EXIT

if [ "$SKIP_BUILD" = false ]; then
    ./scripts/generate_screenshots/build_appstore_screenshots.sh duo
fi

# 撮影テストの attachment 名 (AppStoreScreenshot---appstore{N}---{lang}---0) から
# 出力先 ({DUO_OUTPUT_DIR}/{fastlane の言語}/{outer|inner}/{N}.png) を返す。
output_path_for_attachment() {
    local attachment_name=$1
    local display=$2
    local page language
    page=$(echo "$attachment_name" | awk -F'---' '{print $2}' | sed 's/appstore//')
    language=$(echo "$attachment_name" | awk -F'---' '{print $3}')
    if [ -z "$page" ] || [ -z "$language" ]; then
        echo "Error: 想定外の attachment 名: $attachment_name" >&2
        return 1
    fi
    echo "$DUO_OUTPUT_DIR/$(map_language_to_fastlane "$language")/${display}/${page}.png"
}

# alpha を落として出力先に置く (simctl の画像は hasAlpha: yes になり、App Store は alpha 付きを受け付けないため)。
place_png() {
    local source=$1
    local destination=$2
    mkdir -p "$(dirname "$destination")"
    magick "$source" -alpha remove -alpha off "$destination"
    echo "Placed: $destination"
}

# 今回撮る言語・ページの前回の画像を消す (撮影に失敗したページを前回の画像で補ったまま機械検証を通さないため)。
# 引数: $1 outer / inner
remove_previous_outputs() {
    local display=$1
    local language page
    for language in $(echo "$LANGUAGES" | tr ',' ' '); do
        for page in $(echo "$PAGES" | tr ',' ' '); do
            rm -f "$DUO_OUTPUT_DIR/$(map_language_to_fastlane "$language")/${display}/${page}.png"
        done
    done
}

# 撮影に失敗したディスプレイ。失敗しても他方の撮影を続け、最後に 1 つでもあれば exit 1 にする。
failed_displays=()

# 外側ディスプレイ: 閉じた姿勢で撮影テストを実行し、XCTAttachment の画像を置く。
generate_outer() {
    set_pose closed
    remove_previous_outputs outer
    if ! ./scripts/generate_screenshots/run_appstore_screenshots.sh duo-outer "$LANGUAGES" "$PAGES"; then
        failed_displays+=("outer")
    fi
    local raw_dir="$ARTIFACTS_DIR/raw/duo-outer"
    if [ ! -f "$raw_dir/manifest.json" ]; then
        echo "Error: attachment を取り出せませんでした: $raw_dir/manifest.json" >&2
        failed_displays+=("outer")
        return 0
    fi
    jq -r '.[] | .attachments[] | "\(.exportedFileName)\t\(.suggestedHumanReadableName)"' "$raw_dir/manifest.json" |
        while IFS=$'\t' read -r exported_file suggested_name; do
            place_png "$raw_dir/$exported_file" "$(output_path_for_attachment "${suggested_name%%.png*}" outer)"
        done
}

# 内側ディスプレイ: 開いた姿勢で撮影テストを実行し、テストが書く {name}.ready を見てホスト側で撮る。
generate_inner() {
    set_pose open
    remove_previous_outputs inner
    local capture_dir
    capture_dir="$(pwd)/$ARTIFACTS_DIR/raw/duo-inner-capture"
    rm -rf "$capture_dir"
    mkdir -p "$capture_dir"

    # テストの {name}.ready を待って内側ディスプレイを撮り、{name}.done で撮り終えたことをテストに伝える。
    (
        while [ ! -e "$capture_dir/.stop" ]; do
            for ready_file in "$capture_dir"/*.ready; do
                if [ -e "$ready_file" ]; then
                    name=$(basename "$ready_file" .ready)
                    xcrun simctl io "$DUO_UDID" screenshot --display=primary-1 "$capture_dir/$name.png" > /dev/null
                    place_png "$capture_dir/$name.png" "$(output_path_for_attachment "$name" inner)"
                    mv "$ready_file" "$capture_dir/$name.taken"
                    touch "$capture_dir/$name.done"
                fi
            done
            sleep 0.2
        done
    ) &
    local capture_loop_pid=$!

    if ! SNAPSHOT_HOST_CAPTURE_DIR="$capture_dir" ./scripts/generate_screenshots/run_appstore_screenshots.sh duo-inner "$LANGUAGES" "$PAGES"; then
        failed_displays+=("inner")
    fi

    touch "$capture_dir/.stop"
    if ! wait "$capture_loop_pid"; then
        failed_displays+=("inner")
    fi
}

if [ "$DISPLAY_TARGET" != "inner" ]; then
    generate_outer
fi
if [ "$DISPLAY_TARGET" != "outer" ]; then
    generate_inner
fi

if [ "$DISPLAY_TARGET" = "both" ]; then
    fastlane_languages=$(echo "$LANGUAGES" | tr ',' '\n' | while read -r language; do map_language_to_fastlane "$language"; done | paste -sd, -)
    ./scripts/generate_screenshots/verify_duo_screenshots.sh "$DUO_OUTPUT_DIR" "$fastlane_languages" "$PAGES"
fi

echo "==== 出力先: $(pwd)/$DUO_OUTPUT_DIR ===="

if [ "${#failed_displays[@]}" -gt 0 ]; then
    echo "Error: 撮影に失敗したディスプレイがあります: ${failed_displays[*]}" >&2
    exit 1
fi
