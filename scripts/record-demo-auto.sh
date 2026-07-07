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

# Android のカメラ権限付与を裏で繰り返すプロセスのPID。
GRANT_PID=""

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
case "${PLATFORM}" in
  ios | android) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "❌ 不明なプラットフォームです: ${PLATFORM}"
    usage
    exit 1
    ;;
esac

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

# 録画プロセスとカメラ権限付与プロセスを確実に後始末する。
cleanup() {
  if [ -n "${TAIL_PID:-}" ]; then kill "${TAIL_PID}" 2>/dev/null || true; fi
  stop_grant_loop
  stop_recording
}
trap cleanup EXIT

# Android: 初回インストール時のカメラ権限ダイアログがデモ操作を妨げないよう、
# テスト実行中はカメラ権限を裏で付与し続ける（付与済みなら冪等に成功する）。
start_grant_loop() {
  [ "${PLATFORM}" = "android" ] || return 0
  (
    while true; do
      adb -s "${DEVICE_ID}" shell pm grant "${APP_ID}" \
        android.permission.CAMERA >/dev/null 2>&1 || true
      sleep 1
    done
  ) &
  GRANT_PID=$!
}

stop_grant_loop() {
  if [ -n "${GRANT_PID}" ] && kill -0 "${GRANT_PID}" 2>/dev/null; then
    kill "${GRANT_PID}" 2>/dev/null || true
    wait "${GRANT_PID}" 2>/dev/null || true
  fi
  GRANT_PID=""
}

# アプリの起動を待つ。ビルド〜インストールに時間がかかるため、録画は
# 「アプリのプロセスが起動した瞬間」から開始し、無駄な待ち時間を録らない。
#   $1: flutter test のバックグラウンドPID / $2: flutter test の出力ログ
wait_for_app_launch() {
  local test_pid="$1" log="$2"
  echo "⏳  アプリの起動を待機中..."
  for _ in $(seq 1 240); do
    # テストプロセスが先に終了したら待機を打ち切る。
    kill -0 "${test_pid}" 2>/dev/null || return 0
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
}

# --- デモ実行＆録画 -------------------------------------------------------
# 権限付与はアプリ起動前から始めておく（スキャナー画面表示時の権限ダイアログを防ぐ）。
start_grant_loop

echo ""
echo "▶  デモ操作を自動再生します（${TEST_TARGET}）..."

# integration_test をバックグラウンドで実行し、出力はログに保存する。
TEST_LOG="$(mktemp "${TMPDIR:-/tmp}/record-demo-auto.XXXXXX.log")"
(cd "${ROOT_DIR}" && flutter test "${TEST_TARGET}" -d "${DEVICE_ID}") \
  >"${TEST_LOG}" 2>&1 &
TEST_BG_PID=$!

# アプリ起動を待ってから録画開始（ビルド待ち時間を録画に含めない）。
wait_for_app_launch "${TEST_BG_PID}" "${TEST_LOG}"
start_recording "${PLATFORM}"

# テスト出力をリアルタイム表示しつつ、完了を待つ。
tail -n +1 -f "${TEST_LOG}" &
TAIL_PID=$!
TEST_STATUS=0
wait "${TEST_BG_PID}" || TEST_STATUS=$?
kill "${TAIL_PID}" 2>/dev/null || true

echo ""
echo "⏹  録画を停止します..."
stop_grant_loop
stop_recording
rm -f "${TEST_LOG}"

if [ "${TEST_STATUS}" -ne 0 ]; then
  echo "⚠  integration_test が失敗しました（exit=${TEST_STATUS}）。"
  echo "   録画は途中まで保存されている可能性があります。内容を確認してください。"
fi

# --- 後処理（Android 取得・検証・GIF 変換）-------------------------------
finalize_recording "${PLATFORM}"

exit "${TEST_STATUS}"
