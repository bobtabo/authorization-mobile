#!/bin/bash
#
# デモ録画〜GIF 変換を一発で実行するスクリプト。
#
# 使い方:
#   bash scripts/record-demo.sh ios       # iOS Simulator を録画
#   bash scripts/record-demo.sh android   # Android エミュレーターを録画
#
# 動作フロー:
#   1. 前提チェック（ffmpeg・プラットフォーム別ツールの存在確認）
#   2. 録画開始（この間にデモ操作を行う）
#   3. Enter キーで録画停止
#   4. MP4 → GIF 変換（ffmpeg）
#
# 出力:
#   docs/demo.mp4   録画ファイル（中間・.gitignore 対象）
#   docs/demo.gif   変換後 GIF（README / Notion 掲載用）
#
# macOS のみでの使用を想定しています（OS チェックは警告のみ）。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCS_DIR="${ROOT_DIR}/docs"
MP4_PATH="${DOCS_DIR}/demo.mp4"
GIF_PATH="${DOCS_DIR}/demo.gif"

# GIF 変換パラメーター（サイズが大きい場合は FPS=8 / SCALE_WIDTH=320 に調整）
FPS="${FPS:-10}"
SCALE_WIDTH="${SCALE_WIDTH:-390}"

# Android screenrecord の最大録画時間（秒）。screenrecord のデフォルト上限は 180 秒。
ANDROID_TIME_LIMIT="${ANDROID_TIME_LIMIT:-180}"
ANDROID_REMOTE_MP4="/sdcard/demo.mp4"

usage() {
  echo "使い方: bash scripts/record-demo.sh <ios|android>"
  echo ""
  echo "  ios       起動中の iOS Simulator を録画します"
  echo "  android   接続中の Android エミュレーター/実機を録画します"
}

# --- 引数チェック ---------------------------------------------------------
if [ "$#" -ne 1 ]; then
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

# --- OS チェック（警告のみ）-----------------------------------------------
if [ "$(uname -s)" != "Darwin" ]; then
  echo "⚠  このスクリプトは macOS での使用を想定しています（現在: $(uname -s)）。"
  echo "   iOS Simulator の録画は macOS 以外では利用できません。"
fi

# --- 前提チェック ---------------------------------------------------------
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "❌ ffmpeg が見つかりません。GIF 変換に必要です。"
  echo "   macOS では 'brew install ffmpeg' でインストールできます。"
  exit 1
fi

RECORD_PID=""

# 録画プロセスが残っている場合に確実に停止させるためのクリーンアップ。
cleanup() {
  if [ -n "${RECORD_PID}" ] && kill -0 "${RECORD_PID}" 2>/dev/null; then
    kill -INT "${RECORD_PID}" 2>/dev/null || true
    wait "${RECORD_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

mkdir -p "${DOCS_DIR}"
rm -f "${MP4_PATH}"

start_ios_recording() {
  if ! command -v xcrun >/dev/null 2>&1; then
    echo "❌ xcrun が見つかりません。Xcode Command Line Tools が必要です。"
    exit 1
  fi
  # 起動中の Simulator があるか確認。
  if ! xcrun simctl list devices | grep -q "(Booted)"; then
    echo "❌ 起動中の iOS Simulator が見つかりません。"
    echo "   'open -a Simulator' で起動してください。"
    exit 1
  fi
  echo "🎬 iOS Simulator の録画を開始します..."
  # recordVideo は SIGINT で停止するため、バックグラウンド起動して PID を保持する。
  xcrun simctl io booted recordVideo --codec=h264 --force "${MP4_PATH}" &
  RECORD_PID=$!
}

start_android_recording() {
  if ! command -v adb >/dev/null 2>&1; then
    echo "❌ adb が見つかりません。Android SDK Platform-Tools が必要です。"
    exit 1
  fi
  # 接続中のデバイス（device 状態）があるか確認。
  if ! adb get-state >/dev/null 2>&1; then
    echo "❌ 接続中の Android デバイス/エミュレーターが見つかりません。"
    echo "   'adb devices' で接続状態を確認してください。"
    exit 1
  fi
  echo "🎬 Android エミュレーターの録画を開始します..."
  # screenrecord も SIGINT で停止する。デフォルト上限（180秒）を明示指定。
  adb shell screenrecord --time-limit "${ANDROID_TIME_LIMIT}" "${ANDROID_REMOTE_MP4}" &
  RECORD_PID=$!
}

case "${PLATFORM}" in
  ios) start_ios_recording ;;
  android) start_android_recording ;;
esac

# 録画プロセスが即座に落ちていないか確認。
sleep 1
if ! kill -0 "${RECORD_PID}" 2>/dev/null; then
  echo "❌ 録画プロセスの起動に失敗しました。"
  exit 1
fi

echo ""
echo "▶  録画中です。デモ操作を行ってください。"
echo "   終了するには Enter キーを押してください..."
read -r _

echo "⏹  録画を停止します..."
# SIGINT を送って録画ファイルを正常にフラッシュさせる。
kill -INT "${RECORD_PID}" 2>/dev/null || true
wait "${RECORD_PID}" 2>/dev/null || true
RECORD_PID=""

# Android はエミュレーター内に保存されるためローカルへ取得する。
if [ "${PLATFORM}" = "android" ]; then
  echo "⬇  録画ファイルを取得中..."
  # screenrecord がファイルを閉じるまで少し待つ。
  sleep 1
  adb pull "${ANDROID_REMOTE_MP4}" "${MP4_PATH}"
  adb shell rm -f "${ANDROID_REMOTE_MP4}" 2>/dev/null || true
fi

if [ ! -s "${MP4_PATH}" ]; then
  echo "❌ 録画ファイルが生成されませんでした: ${MP4_PATH}"
  exit 1
fi

echo "🎞  GIF に変換中 (fps=${FPS}, scale=${SCALE_WIDTH}:-1)..."
ffmpeg -y -i "${MP4_PATH}" -vf "fps=${FPS},scale=${SCALE_WIDTH}:-1" "${GIF_PATH}"

echo ""
echo "✅ 完了しました。"
echo "   MP4: ${MP4_PATH}"
echo "   GIF: ${GIF_PATH}"
echo ""
echo "💡 GIF のサイズが大きい場合は FPS=8 SCALE_WIDTH=320 を指定して再実行してください。"
echo "   例: FPS=8 SCALE_WIDTH=320 bash scripts/record-demo.sh ${PLATFORM}"
