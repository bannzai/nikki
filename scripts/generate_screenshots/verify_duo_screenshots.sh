#!/bin/bash
#
# verify_duo_screenshots.sh
#
# generate_duo_screenshots.sh が出力した iPhone Duo 用の App Store スクリーンショットを機械検証する。
# 指定した言語 × ページのすべてについて、次の 2 枚が揃っているかを確かめる。
#   - 外側ディスプレイ: {言語}/outer/{ページ}.png が 1398x2034 px で alpha なし
#   - 内側ディスプレイ: {言語}/inner/{ページ}.png が 2853x2007 px で alpha なし
# 寸法は Apple の「Screenshot specifications」の iPhone Duo の節
# (https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)。
# 内側は横向き (2853x2007) で作る (理由は generate_duo_screenshots.sh のヘッダー)。
# 1 つでも欠け・寸法違い・alpha ありがあれば [NG] を出して exit 1 で終わる。
#
# 【使い方】
# $ ./scripts/generate_screenshots/verify_duo_screenshots.sh <出力ディレクトリ> <言語のカンマ区切り> <ページ番号のカンマ区切り>
#
# 例:
#   $ ./scripts/generate_screenshots/verify_duo_screenshots.sh scripts/generate_screenshots/artifacts/duo "ja,en-US" "1,2,3,4,5,6"
#
# 言語は fastlane のディレクトリ名 (map_language_to_fastlane の変換後。例: en-US) で渡す。
#
# 【終了コード】
#   0: すべて OK
#   1: NG あり
#   2: 引数不正
#
set -euo pipefail

OUTPUT_DIR="${1:-}"
LANGUAGES="${2:-}"
PAGES="${3:-}"

if [ -z "$OUTPUT_DIR" ] || [ -z "$LANGUAGES" ] || [ -z "$PAGES" ]; then
    echo "Usage: $0 <出力ディレクトリ> <言語のカンマ区切り> <ページ番号のカンマ区切り>" >&2
    exit 2
fi

ng_count=0
ok_count=0

# 1 枚の PNG が期待する寸法で alpha なしかを検査し、NG なら理由を表示して数える。
# 引数: $1 ファイルパス, $2 期待する幅, $3 期待する高さ
check_png() {
    local file=$1
    local expected_width=$2
    local expected_height=$3

    if [ ! -f "$file" ]; then
        echo "[NG] ファイルが無い: $file"
        ng_count=$((ng_count + 1))
        return
    fi

    local sips_output width height has_alpha
    # 壊れた PNG で sips が失敗しても set -e で止めず、NG として数えて残りの検査を続ける。
    if ! sips_output=$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$file" 2>&1); then
        echo "[NG] $file: 画像として読めない (sips: $sips_output)"
        ng_count=$((ng_count + 1))
        return
    fi
    width=$(echo "$sips_output" | awk '/pixelWidth/ {print $2}')
    height=$(echo "$sips_output" | awk '/pixelHeight/ {print $2}')
    has_alpha=$(echo "$sips_output" | awk '/hasAlpha/ {print $2}')

    if [ "$width" = "$expected_width" ] && [ "$height" = "$expected_height" ] && [ "$has_alpha" = "no" ]; then
        ok_count=$((ok_count + 1))
    else
        echo "[NG] $file: ${width}x${height} hasAlpha=${has_alpha} (期待: ${expected_width}x${expected_height} hasAlpha=no)"
        ng_count=$((ng_count + 1))
    fi
}

IFS=',' read -ra language_list <<< "$LANGUAGES"
IFS=',' read -ra page_list <<< "$PAGES"

for language in "${language_list[@]}"; do
    for page in "${page_list[@]}"; do
        check_png "$OUTPUT_DIR/$language/outer/${page}.png" 1398 2034
        check_png "$OUTPUT_DIR/$language/inner/${page}.png" 2853 2007
    done
done

echo "検証結果: OK ${ok_count} / 期待 $((${#language_list[@]} * ${#page_list[@]} * 2)) 枚 (${#language_list[@]} 言語 × ${#page_list[@]} ページ × 外側・内側), NG ${ng_count} 件"

if [ "$ng_count" -gt 0 ]; then
    exit 1
fi
