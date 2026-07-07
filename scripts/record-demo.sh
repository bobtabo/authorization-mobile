#!/bin/bash
#
# デモ録画〜GIF 変換を一発で実行するスクリプト（手動操作版）。
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
# デモ操作自体も自動化したい場合は scripts/record-demo-auto.sh を使用してください。
#
# macOS のみでの使用を想定しています（OS チェックは警告のみ）。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/record-common.sh
source "${SCRIPT_DIR}/lib/record-common.sh"

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
warn_if_not_macos

# --- 前提チェック・準備 ---------------------------------------------------
prepare_output_dir

trap stop_recording EXIT

# --- 録画開始 -------------------------------------------------------------
start_recording "${PLATFORM}"

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

# --- 後処理（Android 取得・検証・GIF 変換）-------------------------------
finalize_recording "${PLATFORM}"
