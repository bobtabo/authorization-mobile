#!/bin/bash
#
# デモ操作の自動再生〜録画〜GIF 変換を一発で実行するスクリプト（自動操作版）。
#
# scripts/record-demo.sh が「録画中に人手で操作する」前提なのに対し、こちらは
# integration_test（integration_test/demo_scenario_test.dart）でデモ操作自体を
# 自動再生する。録画開始 → テスト実行 → テスト完了で録画停止、までを1コマンドで
# 行うため、真の意味で「スクリプト一発でデモ GIF が完成する」。
#
# 使い方:
#   bash scripts/record-demo-auto.sh ios [device-id]       # iOS Simulator
#   bash scripts/record-demo-auto.sh android [device-id]   # Android エミュレーター
#
#   device-id を省略した場合は、起動中の端末を自動検出する。
#
# 動作フロー:
#   1. 前提チェック（ffmpeg・flutter・プラットフォーム別ツールの存在確認）
#   2. 録画開始
#   3. flutter test で integration_test を実行（デモ操作を自動再生）
#   4. テスト完了を検知して録画停止（Enter 待ちはしない）
#   5. MP4 → GIF 変換（ffmpeg）
#
# 出力:
#   docs/demo.mp4   録画ファイル（中間・.gitignore 対象）
#   docs/demo.gif   変換後 GIF（README / Notion 掲載用）
#
# 重要: このデモは実サーバー（LocalStack / ngrok / 実バックエンド）に一切接続せず、
#       API 応答はすべて MockClient でモックする。他リポジトリや実行環境には
#       干渉しない。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/record-common.sh
source "${SCRIPT_DIR}/lib/record-common.sh"

TEST_TARGET="integration_test/demo_scenario_test.dart"

# android/app/build.gradle(.kts) の applicationId を読み取る（取得できなければ既定値）。
# 片方のファイルが存在しなくても grep がエラー終了して set -e に引っかからないよう、
# 存在するファイルだけを対象にし、失敗しても握りつぶす。
read_app_id() {
  local f
  for f in "${ROOT_DIR}/android/app/build.gradle" \
    "${ROOT_DIR}/android/app/build.gradle.kts"; do
    [ -f "${f}" ] || continue
    grep -hoE 'applicationId[[:space:]]*=?[[:space:]]*"[^"]+"' "${f}" 2>/dev/null \
      | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/'
  done | head -n 1
}
APP_ID="$(read_app_id || true)"
APP_ID="${APP_ID:-com.authorization.mobile}"

usage() {
  echo "使い方: bash scripts/record-demo-auto.sh <ios|android> [device-id]"
  echo ""
  echo "  ios       起動中の iOS Simulator でデモを自動再生・録画します"
  echo "  android   接続中の Android エミュレーター/実機でデモを自動再生・録画します"
  echo "  device-id 省略時は起動中の端末を自動検出します"
}

# --- 引数チェック ---------------------------------------------------------
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "❌ プラットフォームを引数で指定してください。"
  usage
  exit 1
fi

PLATFORM="$1"
if [ "${PLATFORM}" = "-h" ] || [ "${PLATFORM}" = "--help" ]; then
  usage
  exit 0
fi
validate_platform "${PLATFORM}"

DEVICE_ID="${2:-}"

# 対象デバイスIDを解決する（未指定なら自動検出）。
resolve_device_id() {
  if [ -n "${DEVICE_ID}" ]; then
    return
  fi
  case "${PLATFORM}" in
    android)
      require_cmd adb "Android SDK Platform-Tools が必要です。"
      DEVICE_ID=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
      ;;
    ios)
      require_cmd xcrun "Xcode Command Line Tools が必要です。"
      DEVICE_ID=$(xcrun simctl list devices booted \
        | grep -oE '[0-9A-Fa-f-]{36}' | head -n 1)
      ;;
  esac
  if [ -z "${DEVICE_ID}" ]; then
    echo "❌ 対象デバイスを検出できませんでした。端末を起動してから再実行するか、"
    echo "   device-id を第2引数で指定してください。"
    exit 1
  fi
}

# --- OS チェック（警告のみ）-----------------------------------------------
warn_if_not_macos

# --- 前提チェック・準備 ---------------------------------------------------
require_cmd flutter "Flutter SDK が必要です。https://docs.flutter.dev/get-started/install"
prepare_output_dir
resolve_device_id

echo "🎯 対象デバイス: ${DEVICE_ID}"

# 録画プロセスを確実に後始末する。
cleanup() {
  if [ -n "${TAIL_PID:-}" ]; then kill "${TAIL_PID}" 2>/dev/null || true; fi
  stop_recording
}
trap cleanup EXIT

# アプリの起動を待つ。ビルド〜インストールに時間がかかるため、録画は
# 「アプリのプロセスが起動した瞬間」から開始し、無駄な待ち時間を録らない。
#   $1: flutter test のバックグラウンドPID / $2: flutter test の出力ログ
# 戻り値: 0=起動を検知（またはタイムアウトで録画継続）/ 1=起動確認前にテストが終了した
wait_for_app_launch() {
  local test_pid="$1" log="$2"
  echo "⏳  アプリの起動を待機中..."
  for _ in $(seq 1 240); do
    # テストプロセスが先に終了した場合、録画しても無意味なので打ち切る。
    if ! kill -0 "${test_pid}" 2>/dev/null; then
      echo "❌  アプリの起動を確認する前にテストプロセスが終了しました。"
      return 1
    fi
    case "${PLATFORM}" in
      android)
        if adb -s "${DEVICE_ID}" shell pidof "${APP_ID}" >/dev/null 2>&1; then
          return 0
        fi
        ;;
      *)
        # iOS など: flutter test がテスト本体の実行を開始した合図を待つ。
        if grep -q '+0: ' "${log}" 2>/dev/null; then
          return 0
        fi
        ;;
    esac
    sleep 0.5
  done
  echo "⚠  アプリ起動を検出できませんでした。そのまま録画を開始します。"
  return 0
}

# --- デモ実行＆録画 -------------------------------------------------------
if [ "${PLATFORM}" = "android" ]; then
  # 前回実行の残留プロセスがあると起動検知が誤検知するため、事前に停止しておく。
  adb -s "${DEVICE_ID}" shell am force-stop "${APP_ID}" 2>/dev/null || true
fi

echo ""
echo "▶  デモ操作を自動再生します（${TEST_TARGET}）..."

# integration_test をバックグラウンドで実行し、出力はログに保存する。
# DEMO_SCAN_PREVIEW=true を渡すことで、スキャナー画面が実機カメラの代わりに
# サンプルQRコードをプレビュー表示する（エミュレーター/シミュレーターでも
# 「QRコードを読み取っている」様子を録画できる）。本番ビルドには影響しない。
TEST_LOG="$(mktemp "${TMPDIR:-/tmp}/record-demo-auto.XXXXXX.log")"
(cd "${ROOT_DIR}" && flutter test "${TEST_TARGET}" -d "${DEVICE_ID}" \
  --dart-define=DEMO_SCAN_PREVIEW=true) \
  >"${TEST_LOG}" 2>&1 &
TEST_BG_PID=$!

# アプリ起動を待ってから録画開始（ビルド待ち時間を録画に含めない）。
# テストプロセスが起動確認前に終了していたら、録画せずそのままログを見せて終了する。
if ! wait_for_app_launch "${TEST_BG_PID}" "${TEST_LOG}"; then
  TEST_STATUS=0
  wait "${TEST_BG_PID}" || TEST_STATUS=$?
  echo ""
  echo "⚠  integration_test の出力:"
  cat "${TEST_LOG}"
  rm -f "${TEST_LOG}"
  exit "${TEST_STATUS}"
fi
start_recording "${PLATFORM}"

# テスト出力をリアルタイム表示しつつ、完了を待つ。
tail -n +1 -f "${TEST_LOG}" &
TAIL_PID=$!
TEST_STATUS=0
wait "${TEST_BG_PID}" || TEST_STATUS=$?
kill "${TAIL_PID}" 2>/dev/null || true
wait "${TAIL_PID}" 2>/dev/null || true

echo ""
echo "⏹  録画を停止します..."
stop_recording

if [ "${TEST_STATUS}" -ne 0 ]; then
  echo "⚠  integration_test が失敗しました（exit=${TEST_STATUS}）。"
  echo "   録画は途中まで保存されている可能性があります。内容を確認してください。"
  echo "   ログ: ${TEST_LOG}"
else
  rm -f "${TEST_LOG}"
fi

# --- 後処理（Android 取得・検証・GIF 変換）-------------------------------
finalize_recording "${PLATFORM}"

exit "${TEST_STATUS}"
