#!/bin/bash
#
# tflocal apply 後に LocalStack から API Gateway ID を取得し、
# .env の API_ID を更新するスクリプト。
#
# 使い方:
#   bash scripts/update-env.sh
#
# macOS / Linux 両対応。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [ ! -f "${ENV_FILE}" ]; then
  echo "❌ ${ENV_FILE} が見つかりません。cp .env.example .env で作成してください。"
  exit 1
fi

# 認可サーバーの Terraform ディレクトリ（相対パスで指定、環境変数で上書き可能）
TF_DIR="${AUTH_TERRAFORM_DIR:-${ROOT_DIR}/../authorization/terraform/local}"

echo "🔍 Terraform output から API Gateway ID を取得中..."

API_ID=""
if [ -d "${TF_DIR}" ]; then
  API_ID=$(cd "${TF_DIR}" && tflocal output -raw api_gateway_id 2>&1) || {
    echo "⚠️  tflocal output に失敗しました: ${API_ID}"
    API_ID=""
  }
fi

if [ -z "${API_ID}" ] || [ "${API_ID}" = "None" ]; then
  echo "⚠️  Terraform ディレクトリが見つからないか output を取得できませんでした。"
  echo "   フォールバック: LocalStack API (名前フィルター付き) から取得します..."
  API_ID=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis \
    --query "items[?name=='authorization-api'].id | [0]" \
    --output text 2>&1) || {
    echo "❌ LocalStack API からの取得にも失敗しました: ${API_ID}"
    exit 1
  }
fi

if [ -z "${API_ID}" ] || [ "${API_ID}" = "None" ]; then
  echo "❌ API Gateway ID を取得できませんでした。"
  echo "   認可サーバーで tflocal apply が完了しているか確認してください。"
  exit 1
fi

# API_ID が英数字・ハイフンのみであることを検証（sed インジェクション防止）
if [[ ! "${API_ID}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "❌ 取得した API_ID に不正な文字が含まれています: ${API_ID}"
  exit 1
fi

echo "✅ API Gateway ID: ${API_ID}"

# API_ID 行がなければ追記、あれば置換（perl で OS 差分なし・メタ文字安全）
if grep -q '^API_ID=' "${ENV_FILE}"; then
  perl -i -pe "s/^API_ID=.*/API_ID=${API_ID}/" "${ENV_FILE}"
else
  echo "API_ID=${API_ID}" >> "${ENV_FILE}"
fi

echo "✅ ${ENV_FILE} の API_ID を更新しました: API_ID=${API_ID}"
