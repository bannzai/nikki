#!/bin/bash
#
# generate_appstore_screenshots.sh
#
# App Store スクリーンショット生成のメインオーケストレーションスクリプト。
# ビルド → 撮影テスト実行 → xcresult 抽出 → fastlane 形式への整理、を一括で行う。
#
# 【使い方】
# $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh [-d DEVICE] [-l LANGUAGES] [-n PAGES] [--skip-build]
#
# オプション:
#   -d DEVICE    : iphone | ipad | mac | all (省略時 all)
#   -l LANGUAGES : 撮影する言語(カンマ区切り。例 "ja"。省略時 ja,en)
#   -n PAGES     : 撮影するページ番号(カンマ区切り。例 "1,3"。省略時 全6ページ)
#   --skip-build : build-for-testing を省略する(ビルド済みで再撮影だけしたい時)
#
# 例:
#   全デバイス・全言語・全ページ: ./scripts/generate_screenshots/generate_appstore_screenshots.sh
#   iPhone の ja のページ1だけ:   ./scripts/generate_screenshots/generate_appstore_screenshots.sh -d iphone -l ja -n 1
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$SCRIPT_DIR/../.."

DEVICE="all"
LANGUAGES=""
PAGES=""
SKIP_BUILD=false

while [ $# -gt 0 ]; do
    case "$1" in
        -d) DEVICE=$2; shift 2 ;;
        -l) LANGUAGES=$2; shift 2 ;;
        -n) PAGES=$2; shift 2 ;;
        --skip-build) SKIP_BUILD=true; shift ;;
        *) echo "Error: 不明なオプション: $1" >&2; exit 1 ;;
    esac
done

# 未対応の値は撮影テスト側のフィルタで空になり「1枚も生成されないのに成功扱い」になるため、
# 実行前に検証して弾く。
case "$DEVICE" in
    all | iphone | ipad | mac) ;;
    *) echo "Error: 不明な device: $DEVICE (iphone | ipad | mac | all)" >&2; exit 1 ;;
esac
# 撮影テスト側と同じ「カンマだけで分割」の規則で検査する(空白区切りは1つの無効値として弾く)。
# 空要素("ja,"、","等)も弾き、選択結果が空のまま撮影 0 回で成功扱いにならないようにする。
validate_csv() {
    local label=$1
    local raw=$2
    local allowed=$3
    local rest=$raw
    local item
    local ok
    local count=0
    # 「カンマだけで分割」の規則で先頭から 1 要素ずつ切り出す(末尾が "," で終わる場合の空要素も検査する)。
    # 空白を含む要素は 1 つの無効値として扱い、許可リストと完全一致する要素だけを数える。
    while :; do
        item=${rest%%,*}
        ok=false
        for candidate in $allowed; do
            if [ "$item" = "$candidate" ]; then
                ok=true
            fi
        done
        if [ "$ok" = false ]; then
            echo "Error: 不明な${label}: '$item' ($allowed のカンマ区切り)" >&2
            exit 1
        fi
        count=$((count + 1))
        case "$rest" in
            *,*) rest=${rest#*,} ;;
            *) break ;;
        esac
    done
    if [ "$count" -eq 0 ]; then
        echo "Error: ${label}が1つも指定されていません: '$raw'" >&2
        exit 1
    fi
}
if [ -n "$LANGUAGES" ]; then
    validate_csv "言語" "$LANGUAGES" "ja en"
fi
if [ -n "$PAGES" ]; then
    validate_csv "ページ番号" "$PAGES" "1 2 3 4 5 6"
fi

if [ "$DEVICE" = "all" ]; then
    DEVICES=(iphone ipad mac)
else
    DEVICES=("$DEVICE")
fi

if [ "$SKIP_BUILD" = false ]; then
    NEEDS_IOS=false
    NEEDS_MAC=false
    for device in "${DEVICES[@]}"; do
        case "$device" in
            iphone | ipad) NEEDS_IOS=true ;;
            mac) NEEDS_MAC=true ;;
        esac
    done
    if [ "$NEEDS_IOS" = true ] && [ "$NEEDS_MAC" = true ]; then
        ./scripts/generate_screenshots/build_appstore_screenshots.sh all
    elif [ "$NEEDS_IOS" = true ]; then
        ./scripts/generate_screenshots/build_appstore_screenshots.sh ios
    elif [ "$NEEDS_MAC" = true ]; then
        ./scripts/generate_screenshots/build_appstore_screenshots.sh mac
    fi
fi

for device in "${DEVICES[@]}"; do
    ./scripts/generate_screenshots/run_appstore_screenshots.sh "$device" "$LANGUAGES" "$PAGES"
    ./scripts/generate_screenshots/organize_appstore_screenshots.sh "$device"
done

echo "==== Generate completed ===="
echo "fastlane/screenshots/ 配下を確認してください"
