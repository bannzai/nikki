#!/usr/bin/env bash
# =============================================================================
# スクリプト名: asc_apply_submission_settings.sh
# 用途:
#   App Store Connect の提出前設定 (カテゴリ・アプリ価格・年齢制限指定・App Review 連絡先・販売地域) を
#   fastlane/asc_submission_settings.json の定義どおりに API で適用する (issue #71)。
#   各項目は「現状 GET → 差分があれば PATCH/POST → 再 GET で検証」の順で処理し、
#   すでに定義どおりなら書き込まない (冪等)。
# 使い方:
#   bash scripts/asc_apply_submission_settings.sh            # 差分を適用して検証
#   bash scripts/asc_apply_submission_settings.sh --dry-run  # 現状と差分の表示のみ (書き込みなし)
# 環境変数 (必須):
#   ASC_API_KEY_ID / ASC_API_KEY_ISSUER_ID / ASC_API_KEY_P8_BASE64
#   ASC_REVIEW_CONTACT_PHONE : App Review 連絡先の電話番号 (E.164 形式。例: +81XXXXXXXXXX)。
#                              個人の電話番号をリポジトリに含めないため、設定 JSON ではなく環境変数で渡す
# 環境変数 (任意):
#   ASC_API_SH : JWT 付き API ラッパのパス (既定: appstore-in-app-purchase skill の iap_api.sh)
# 終了コード:
#   0 すべて定義どおり (適用済み・検証済み) / 1 検証不一致または API 失敗 / 2 前提条件不足
# 依存コマンド: bash 4+, jq, curl, openssl (ラッパ経由)
# 設計 WHY:
#   - JWT 生成と HTTP ハンドリングは既存 skill のラッパに委ね、本スクリプトは ASC リソースの差分適用だけを持つ
#   - 販売地域は appAvailabilityV2 が未作成だと GET が 404 になるため、404 を「未作成」として全テリトリーで作成する
#   - 審査連絡先は appStoreVersion (iOS / macOS) ごとのリソースなので、PREPARE_FOR_SUBMISSION の全バージョンに適用する
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/fastlane/asc_submission_settings.json"
API="${ASC_API_SH:-$HOME/.claude/skills/appstore-in-app-purchase/scripts/iap_api.sh}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

for cmd in jq bash; do
    command -v "$cmd" >/dev/null || { echo "[NG] $cmd が必要" >&2; exit 2; }
done
[ -r "$API" ] || { echo "[NG] API ラッパが見つからない: $API" >&2; exit 2; }
[ -r "$CONFIG" ] || { echo "[NG] 設定ファイルが見つからない: $CONFIG" >&2; exit 2; }
for v in ASC_API_KEY_ID ASC_API_KEY_ISSUER_ID ASC_API_KEY_P8_BASE64 ASC_REVIEW_CONTACT_PHONE; do
    [ -n "${!v:-}" ] || { echo "[NG] 環境変数 $v が未設定" >&2; exit 2; }
done

APP_ID=$(jq -r '.appId' "$CONFIG")
FAILED=0

api() { bash "$API" "$@"; }
api_allow_404() { IAP_API_ALLOW_404=1 bash "$API" "$@" 2>/dev/null || { [ $? -eq 4 ] && echo '{"data":null}'; }; }
log() { printf '%s\n' "$*"; }
mark_failed() { FAILED=1; if [ $DRY_RUN -eq 1 ]; then log "[DIFF] $*"; else log "[NG] $*"; fi; }

# ---- 1. カテゴリ ----
log "== カテゴリ"
APP_INFO=$(api GET "/v1/apps/$APP_ID/appInfos?fields[appInfos]=state")
# 公開済みと編集中の appInfo が併存する場合があるため、編集対象の state を明示して選ぶ
APP_INFO_ID=$(jq -r '[.data[] | select(.attributes.state == "PREPARE_FOR_SUBMISSION" or .attributes.state == "DEVELOPER_REJECTED" or .attributes.state == "REJECTED" or .attributes.state == "METADATA_REJECTED" or .attributes.state == "WAITING_FOR_REVIEW")] | first | .id // empty' <<<"$APP_INFO")
if [ -z "$APP_INFO_ID" ]; then
    # 編集中の appInfo が無い (公開済みのみ) 場合は、公開済み (READY_FOR_DISTRIBUTION) を対象にする
    APP_INFO_ID=$(jq -r '[.data[] | select(.attributes.state == "READY_FOR_DISTRIBUTION")] | first | .id // empty' <<<"$APP_INFO")
    [ -n "$APP_INFO_ID" ] && log "[WARN] 編集中の appInfo が無いため公開済みの appInfo を対象にする"
fi
if [ -z "$APP_INFO_ID" ]; then
    echo "[NG] 対象の appInfo が見つからない (state 一覧: $(jq -r '[.data[].attributes.state] | join(",")' <<<"$APP_INFO"))" >&2
    exit 1
fi
WANT_PRIMARY=$(jq -r '.categories.primary' "$CONFIG")
WANT_SECONDARY=$(jq -r '.categories.secondary' "$CONFIG")
get_categories() {
    api GET "/v1/appInfos/$APP_INFO_ID?include=primaryCategory,secondaryCategory" \
        | jq -r '[.data.relationships.primaryCategory.data.id // "null", .data.relationships.secondaryCategory.data.id // "null"] | join(" ")'
}
CUR=$(get_categories)
log "現状: primary/secondary = $CUR / 定義: $WANT_PRIMARY $WANT_SECONDARY"
if [ "$CUR" != "$WANT_PRIMARY $WANT_SECONDARY" ] && [ $DRY_RUN -eq 0 ]; then
    api PATCH "/v1/appInfos/$APP_INFO_ID" "$(jq -n --arg id "$APP_INFO_ID" --arg p "$WANT_PRIMARY" --arg s "$WANT_SECONDARY" \
        '{data:{type:"appInfos",id:$id,relationships:{primaryCategory:{data:{type:"appCategories",id:$p}},secondaryCategory:{data:{type:"appCategories",id:$s}}}}}')" >/dev/null
    CUR=$(get_categories)
    log "適用後: $CUR"
fi
[ "$CUR" = "$WANT_PRIMARY $WANT_SECONDARY" ] && log "[OK] カテゴリ" || mark_failed "カテゴリが定義と不一致"

# ---- 2. アプリ価格 ----
log "== アプリ価格"
WANT_TERRITORY=$(jq -r '.price.baseTerritory' "$CONFIG")
WANT_PRICE=$(jq -r '.price.customerPrice' "$CONFIG")
get_price() {
    # 価格スケジュール未作成でも /appPriceSchedule 本体はプレースホルダ (baseTerritory=USA) を返すため、
    # manualPrices の 404 を「未作成」の判定に使う
    local prices
    prices=$(api_allow_404 GET "/v1/appPriceSchedules/$APP_ID/manualPrices?include=appPricePoint&fields[appPricePoints]=customerPrice&fields[appPrices]=startDate,endDate,appPricePoint")
    if [ "$(jq -r '.data' <<<"$prices")" = "null" ]; then
        echo "none"
        return
    fi
    local base price_point
    base=$(api GET "/v1/apps/$APP_ID/appPriceSchedule?include=baseTerritory" | jq -r '.data.relationships.baseTerritory.data.id')
    # 将来の価格変更や過去の期間が複数入り得るため、今日を含む期間 (startDate/endDate が null または今日を跨ぐ) の価格を現在価格とする
    price_point=$(jq -r --arg today "$(date +%Y-%m-%d)" '
        (.included // [] | map(select(.type=="appPricePoints")) | map({key:.id, value:.attributes.customerPrice}) | from_entries) as $pp
        | [.data[] | select((.attributes.startDate == null or .attributes.startDate <= $today) and (.attributes.endDate == null or .attributes.endDate > $today))
           | $pp[.relationships.appPricePoint.data.id]] | first // "null"' <<<"$prices")
    echo "$base $price_point"
}
CUR=$(get_price)
log "現状: baseTerritory/customerPrice = $CUR / 定義: $WANT_TERRITORY $WANT_PRICE"
if [ "$CUR" != "$WANT_TERRITORY $WANT_PRICE" ] && [ $DRY_RUN -eq 0 ]; then
    PRICE_POINT_ID=$(api GET "/v1/apps/$APP_ID/appPricePoints?filter[territory]=$WANT_TERRITORY&limit=200&fields[appPricePoints]=customerPrice" \
        | jq -r --arg p "$WANT_PRICE" '.data[] | select(.attributes.customerPrice==$p) | .id' | head -1)
    [ -n "$PRICE_POINT_ID" ] || { mark_failed "価格 $WANT_PRICE の price point が見つからない"; }
    if [ -n "$PRICE_POINT_ID" ]; then
        api POST "/v1/appPriceSchedules" "$(jq -n --arg app "$APP_ID" --arg t "$WANT_TERRITORY" --arg pp "$PRICE_POINT_ID" \
            '{data:{type:"appPriceSchedules",relationships:{app:{data:{type:"apps",id:$app}},baseTerritory:{data:{type:"territories",id:$t}},manualPrices:{data:[{type:"appPrices",id:"${price-base}"}]}}},
              included:[{type:"appPrices",id:"${price-base}",attributes:{startDate:null},relationships:{appPricePoint:{data:{type:"appPricePoints",id:$pp}}}}]}')" >/dev/null
        CUR=$(get_price)
        log "適用後: $CUR"
    fi
fi
[ "$CUR" = "$WANT_TERRITORY $WANT_PRICE" ] && log "[OK] アプリ価格" || mark_failed "アプリ価格が定義と不一致"

# ---- 3. 年齢制限指定 ----
log "== 年齢制限指定"
WANT_AGE=$(jq -S '.ageRatingDeclaration' "$CONFIG")
# 宣言レコードは appInfo と同じ id とは限らないため、GET で得た自身の id を PATCH に使う
AGE_ID=$(api GET "/v1/appInfos/$APP_INFO_ID/ageRatingDeclaration?fields[ageRatingDeclarations]=kidsAgeBand" | jq -r '.data.id')
get_age() {
    # 定義に含まれるキーだけを比較対象にする (kidsAgeBand / deprecated な ageRatingOverride 等は比較しない)
    api GET "/v1/appInfos/$APP_INFO_ID/ageRatingDeclaration" \
        | jq -S --argjson want "$WANT_AGE" '.data.attributes | with_entries(select(.key as $k | $want | has($k)))'
}
CUR=$(get_age)
if [ "$CUR" != "$WANT_AGE" ]; then
    log "差分 (現状 → 定義):"
    jq -n --argjson cur "$CUR" --argjson want "$WANT_AGE" '$want | to_entries[] | select($cur[.key] != .value) | "  \(.key): \($cur[.key]) → \(.value)"' -r
    if [ $DRY_RUN -eq 0 ]; then
        api PATCH "/v1/ageRatingDeclarations/$AGE_ID" "$(jq -n --arg id "$AGE_ID" --argjson a "$WANT_AGE" \
            '{data:{type:"ageRatingDeclarations",id:$id,attributes:$a}}')" >/dev/null
        CUR=$(get_age)
    fi
else
    log "現状: 定義どおり"
fi
[ "$CUR" = "$WANT_AGE" ] && log "[OK] 年齢制限指定" || mark_failed "年齢制限指定が定義と不一致"

# ---- 4. App Review 連絡先 (iOS / macOS の各バージョン) ----
log "== App Review 連絡先"
WANT_REVIEW=$(jq -S --arg phone "$ASC_REVIEW_CONTACT_PHONE" '.reviewDetail + {contactPhone: $phone}' "$CONFIG")
# ログに電話番号を出さない
mask_phone() { jq -c '.contactPhone |= (if . == null then null else "***" end)'; }
VERSIONS=$(api GET "/v1/apps/$APP_ID/appStoreVersions?filter[appVersionState]=PREPARE_FOR_SUBMISSION&fields[appStoreVersions]=platform,versionString,appStoreReviewDetail&include=appStoreReviewDetail&fields[appStoreReviewDetails]=contactFirstName,contactLastName,contactPhone,contactEmail,demoAccountRequired")
get_review() {
    local rd_id="$1"
    api GET "/v1/appStoreReviewDetails/$rd_id?fields[appStoreReviewDetails]=contactFirstName,contactLastName,contactPhone,contactEmail,demoAccountRequired" \
        | jq -S '.data.attributes'
}
# Nikki は iOS / macOS の両方を提出するため、両プラットフォームのバージョンが揃っていることを検証する
for platform in IOS MAC_OS; do
    if [ "$(jq --arg pf "$platform" '[.data[] | select(.attributes.platform == $pf)] | length' <<<"$VERSIONS")" -eq 0 ]; then
        mark_failed "$platform の PREPARE_FOR_SUBMISSION バージョンが無い (審査連絡先を設定する対象が無い)"
    fi
done
while read -r ver_id platform ver rd_id; do
    log "- $platform $ver (version $ver_id)"
    if [ "$rd_id" = "null" ]; then
        log "  現状: 未作成"
        if [ $DRY_RUN -eq 0 ]; then
            rd_id=$(api POST "/v1/appStoreReviewDetails" "$(jq -n --arg v "$ver_id" --argjson a "$WANT_REVIEW" \
                '{data:{type:"appStoreReviewDetails",attributes:$a,relationships:{appStoreVersion:{data:{type:"appStoreVersions",id:$v}}}}}')" | jq -r '.data.id')
        fi
    else
        CUR=$(get_review "$rd_id")
        if [ "$CUR" != "$WANT_REVIEW" ]; then
            log "  現状: $(mask_phone <<<"$CUR")"
            if [ $DRY_RUN -eq 0 ]; then
                api PATCH "/v1/appStoreReviewDetails/$rd_id" "$(jq -n --arg id "$rd_id" --argjson a "$WANT_REVIEW" \
                    '{data:{type:"appStoreReviewDetails",id:$id,attributes:$a}}')" >/dev/null
            fi
        else
            log "  現状: 定義どおり"
        fi
    fi
    if [ "$rd_id" = "null" ]; then
        if [ $DRY_RUN -eq 1 ]; then
            mark_failed "$platform の審査連絡先が未作成"
        else
            mark_failed "$platform の審査連絡先を作成できなかった"
        fi
        continue
    fi
    CUR=$(get_review "$rd_id")
    [ "$CUR" = "$WANT_REVIEW" ] && log "  [OK] $platform 審査連絡先" || mark_failed "$platform の審査連絡先が定義と不一致: $(mask_phone <<<"$CUR")"
done < <(jq -r '.data[] | "\(.id) \(.attributes.platform) \(.attributes.versionString) \(.relationships.appStoreReviewDetail.data.id // "null")"' <<<"$VERSIONS")

# ---- 5. 販売地域 ----
log "== 販売地域"
WANT_NEW=$(jq -r '.availability.availableInNewTerritories' "$CONFIG")
ALL_TERRITORIES=$(api GET "/v1/territories?limit=200" | jq -c '[.data[].id]')
TOTAL=$(jq 'length' <<<"$ALL_TERRITORIES")
get_availability() {
    local av
    av=$(api_allow_404 GET "/v1/apps/$APP_ID/appAvailabilityV2?fields[appAvailabilities]=availableInNewTerritories")
    if [ "$(jq -r '.data' <<<"$av")" = "null" ]; then
        echo "none"
        return
    fi
    local new_t avail_count
    new_t=$(jq -r '.data.attributes.availableInNewTerritories' <<<"$av")
    avail_count=$(api GET "/v2/appAvailabilities/$APP_ID/territoryAvailabilities?limit=200&fields[territoryAvailabilities]=available" \
        | jq '[.data[] | select(.attributes.available)] | length')
    echo "$new_t $avail_count"
}
CUR=$(get_availability)
log "現状: availableInNewTerritories/配信テリトリー数 = $CUR / 定義: $WANT_NEW $TOTAL"
if [ "$CUR" != "$WANT_NEW $TOTAL" ] && [ $DRY_RUN -eq 0 ]; then
    if [ "$CUR" = "none" ]; then
        api POST "/v2/appAvailabilities" "$(jq -n --arg app "$APP_ID" --argjson new "$WANT_NEW" --argjson ts "$ALL_TERRITORIES" \
            '{data:{type:"appAvailabilities",attributes:{availableInNewTerritories:$new},relationships:{app:{data:{type:"apps",id:$app}},territoryAvailabilities:{data:[$ts[] | {type:"territoryAvailabilities",id:("${t-" + . + "}")}]}}},
              included:[$ts[] | {type:"territoryAvailabilities",id:("${t-" + . + "}"),attributes:{available:true},relationships:{territory:{data:{type:"territories",id:.}}}}]}')" >/dev/null
    else
        # 既存リソースがある場合は作成 API を再実行せず、無効になっているテリトリーを個別に更新する
        # (appAvailabilities 自体の更新 API は無く、territoryAvailabilities の PATCH のみ提供されている)
        while read -r ta_id; do
            api PATCH "/v1/territoryAvailabilities/$ta_id" "$(jq -n --arg id "$ta_id" \
                '{data:{type:"territoryAvailabilities",id:$id,attributes:{available:true}}}')" >/dev/null
        done < <(api GET "/v2/appAvailabilities/$APP_ID/territoryAvailabilities?limit=200&fields[territoryAvailabilities]=available" \
            | jq -r '.data[] | select(.attributes.available | not) | .id')
        if [ "${CUR%% *}" != "$WANT_NEW" ]; then
            mark_failed "availableInNewTerritories (現状 ${CUR%% *}) を更新する API が無い。App Store Connect で変更が必要"
        fi
    fi
    CUR=$(get_availability)
    log "適用後: $CUR"
fi
[ "$CUR" = "$WANT_NEW $TOTAL" ] && log "[OK] 販売地域" || mark_failed "販売地域が定義と不一致"

log "== 結果"
if [ $FAILED -eq 0 ]; then
    [ $DRY_RUN -eq 1 ] && log "[OK] dry-run: すべて定義どおり (差分なし)" || log "[OK] 5 項目すべて定義どおり (適用・検証済み)"
    exit 0
fi
[ $DRY_RUN -eq 1 ] && log "[WARN] dry-run: 差分あり (--dry-run なしで実行すると適用する)" || log "[NG] 不一致あり"
exit 1
