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

# 指定コマンドが存在しなければエラー終了する。
#   $1: コマンド名 / $2: 見つからない場合の補足メッセージ
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ $1 が見つかりません。$2"
    exit 1
  fi
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
require_cmd ffmpeg "GIF 変換に必要です。macOS では 'brew install ffmpeg' でインストールできます。"

RECORD_PID=""

# 録画プロセスに SIGINT を送って停止・回収する。多重呼び出ししても安全なように
# RECORD_PID を空にして再入を防ぐ。cleanup（trap）と通常フローの両方から呼ばれる。
stop_recording() {
  if [ -n "${RECORD_PID}" ]; then
    kill -INT "${RECORD_PID}" 2>/dev/null || true
    wait "${RECORD_PID}" 2>/dev/null || true
    RECORD_PID=""
  fi
}
trap stop_recording EXIT

mkdir -p "${DOCS_DIR}"
rm -f "${MP4_PATH}"

start_ios_recording() {
  require_cmd xcrun "Xcode Command Line Tools が必要です。"
  # 起動中の Simulator 台数を確認。
  local booted_count
  booted_count=$(xcrun simctl list devices | grep -c "(Booted)" || true)
  if [ "${booted_count}" -eq 0 ]; then
    echo "❌ 起動中の iOS Simulator が見つかりません。"
    echo "   'open -a Simulator' で起動してください。"
    exit 1
  fi
  if [ "${booted_count}" -gt 1 ]; then
    echo "⚠  複数の Simulator が起動しています。録画対象は 'booted' の 1 台に依存します。"
    echo "   意図しない端末を録画しないよう、録画したい 1 台のみ起動することを推奨します。"
  fi
  echo "🎬 iOS Simulator の録画を開始します..."
  # recordVideo は SIGINT で停止するため、バックグラウンド起動して PID を保持する。
  xcrun simctl io booted recordVideo --codec=h264 --force "${MP4_PATH}" &
  RECORD_PID=$!
}

start_android_recording() {
  require_cmd adb "Android SDK Platform-Tools が必要です。"
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

# Enter 入力を待つ。ただし待機中も録画プロセスの生存を監視し、
# time-limit 到達や異常終了で録画が先に止まった場合は検知して知らせる
# （そのまま気づかず途中で切れた GIF を生成しないため）。
stopped_early=false
while kill -0 "${RECORD_PID}" 2>/dev/null; do
  if read -r -t 1 _; then
    break
  fi
done

if ! kill -0 "${RECORD_PID}" 2>/dev/null; then
  stopped_early=true
  echo "⚠  Enter を押す前に録画プロセスが終了しました。"
  echo "   time-limit（${ANDROID_TIME_LIMIT}秒）到達、または録画の異常終了の可能性があります。"
  echo "   生成される動画が意図より短い場合は、再録画してください。"
fi

if [ "${stopped_early}" = false ]; then
  echo "⏹  録画を停止します..."
fi
# SIGINT を送って録画ファイルを正常にフラッシュさせ、プロセスを回収する。
stop_recording

# Android はエミュレーター内に保存されるためローカルへ取得する。
if [ "${PLATFORM}" = "android" ]; then
  # ローカルの adb クライアントへの SIGINT がリモートの screenrecord まで
  # 伝播しないケースに備え、リモート側にも明示的に停止シグナルを送る。
  adb shell pkill -INT screenrecord 2>/dev/null || true

  echo "⬇  録画ファイルを取得中..."
  # screenrecord がファイルを閉じる（サイズが安定する）まで待ってから pull する。
  prev_size=-1
  for _ in $(seq 1 20); do
    size=$(adb shell "stat -c %s ${ANDROID_REMOTE_MP4} 2>/dev/null" | tr -d '\r' || echo 0)
    size=${size:-0}
    if [ "${size}" != "0" ] && [ "${size}" = "${prev_size}" ]; then
      break
    fi
    prev_size="${size}"
    sleep 0.5
  done
  adb pull "${ANDROID_REMOTE_MP4}" "${MP4_PATH}"
  adb shell rm -f "${ANDROID_REMOTE_MP4}" 2>/dev/null || true
fi

if [ ! -s "${MP4_PATH}" ]; then
  echo "❌ 録画ファイルが生成されませんでした: ${MP4_PATH}"
  exit 1
fi

# ffprobe があれば動画ストリームと再生時間を検証し、途中で切れた/壊れた mp4 を弾く。
if command -v ffprobe >/dev/null 2>&1; then
  duration=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "${MP4_PATH}" 2>/dev/null || echo "")
  if [ -z "${duration}" ]; then
    echo "❌ 録画ファイルが壊れているか、動画ストリームを検出できません: ${MP4_PATH}"
    exit 1
  fi
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
