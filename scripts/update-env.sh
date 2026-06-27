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

if [ -d "${TF_DIR}" ]; then
  API_ID=$(cd "${TF_DIR}" && tflocal output -raw api_gateway_id 2>/dev/null || true)
else
  echo "⚠️  Terraform ディレクトリが見つかりません: ${TF_DIR}"
  echo "   フォールバック: LocalStack API から直接取得します..."
  API_ID=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis \
    --query 'items[0].id' --output text 2>/dev/null || true)
fi

if [ -z "${API_ID}" ] || [ "${API_ID}" = "None" ]; then
  echo "❌ API Gateway ID を取得できませんでした。"
  echo "   認可サーバーで tflocal apply が完了しているか確認してください。"
  exit 1
fi

echo "✅ API Gateway ID: ${API_ID}"

# API_ID 行がなければ追記、あれば置換
if grep -q '^API_ID=' "${ENV_FILE}"; then
  # macOS と Linux の sed -i 互換対応
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i "" "s/API_ID=.*/API_ID=${API_ID}/" "${ENV_FILE}"
  else
    sed -i "s/API_ID=.*/API_ID=${API_ID}/" "${ENV_FILE}"
  fi
else
  echo "API_ID=${API_ID}" >> "${ENV_FILE}"
fi

echo "✅ ${ENV_FILE} の API_ID を更新しました: API_ID=${API_ID}"
