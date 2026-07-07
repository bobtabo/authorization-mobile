#!/bin/bash
#
# デモ録画スクリプトの共通処理ライブラリ。
#
# このファイルは単体では実行せず、`source` して使う。
#   - scripts/record-demo.sh       手動操作を録画（Enter で停止）
#   - scripts/record-demo-auto.sh  integration_test で操作を自動再生して録画
#
# source する側は、事前に ROOT_DIR（リポジトリのルート）を定義しておくこと。
#

# GIF 変換パラメーター（サイズが大きい場合は FPS=8 / SCALE_WIDTH=320 に調整）
FPS="${FPS:-10}"
SCALE_WIDTH="${SCALE_WIDTH:-390}"

# Android screenrecord の最大録画時間（秒）。screenrecord のデフォルト上限は 180 秒。
ANDROID_TIME_LIMIT="${ANDROID_TIME_LIMIT:-180}"
ANDROID_REMOTE_MP4="/sdcard/demo.mp4"

# 出力パス（ROOT_DIR は source 側で定義済みであること）
DOCS_DIR="${ROOT_DIR}/docs"
MP4_PATH="${DOCS_DIR}/demo.mp4"
GIF_PATH="${DOCS_DIR}/demo.gif"

RECORD_PID=""
# 録画中のプラットフォーム（stop_recording が停止方法を切り替えるために保持）。
RECORD_PLATFORM=""

# 指定コマンドが存在しなければエラー終了する。
#   $1: コマンド名 / $2: 見つからない場合の補足メッセージ
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ $1 が見つかりません。$2"
    exit 1
  fi
}

# 対象プラットフォーム（ios|android）を検証する。呼び出し側で usage() を
# 定義しておくこと（不正な値のときにヘルプを表示する）。
validate_platform() {
  case "$1" in
    ios | android) ;;
    *)
      echo "❌ 不明なプラットフォームです: $1"
      usage
      exit 1
      ;;
  esac
}

# macOS 以外での実行時に警告する（iOS Simulator 録画は macOS のみ）。
warn_if_not_macos() {
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "⚠  このスクリプトは macOS での使用を想定しています（現在: $(uname -s)）。"
    echo "   iOS Simulator の録画は macOS 以外では利用できません。"
  fi
}

# 出力ディレクトリを準備し、既存の中間 MP4 を削除する。
prepare_output_dir() {
  require_cmd ffmpeg "GIF 変換に必要です。macOS では 'brew install ffmpeg' でインストールできます。"
  mkdir -p "${DOCS_DIR}"
  rm -f "${MP4_PATH}"
}

# 録画プロセスに SIGINT を送って停止・回収する。多重呼び出ししても安全なように
# RECORD_PID を空にして再入を防ぐ。cleanup（trap）と通常フローの両方から呼ばれる。
stop_recording() {
  if [ -z "${RECORD_PID}" ]; then
    return 0
  fi
  # Android: ローカルの adb クライアントへ SIGINT を送っても、リモートの
  # screenrecord まで伝播しないことがある。その場合 `wait` がタイムリミット
  # （既定180秒）まで返らず、録画が無駄に長くなる。先にデバイス側の
  # screenrecord へ直接停止シグナルを送り、MP4 を確定させてから待つ。
  if [ "${RECORD_PLATFORM}" = "android" ]; then
    adb shell pkill -INT screenrecord 2>/dev/null || true
  fi
  kill -INT "${RECORD_PID}" 2>/dev/null || true
  wait "${RECORD_PID}" 2>/dev/null || true
  RECORD_PID=""
}

_start_ios_recording() {
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

_start_android_recording() {
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

# プラットフォーム別に録画を開始し、起動直後の異常終了を検知する。
#   $1: ios|android
start_recording() {
  RECORD_PLATFORM="$1"
  case "$1" in
    ios) _start_ios_recording ;;
    android) _start_android_recording ;;
  esac

  # 録画プロセスが即座に落ちていないか確認。
  sleep 1
  if ! kill -0 "${RECORD_PID}" 2>/dev/null; then
    echo "❌ 録画プロセスの起動に失敗しました。"
    exit 1
  fi
}

# 録画停止後の後処理。Android はファイル取得、共通で検証と GIF 変換を行う。
#   $1: ios|android
finalize_recording() {
  local platform="$1"

  # Android はエミュレーター内に保存されるためローカルへ取得する。
  if [ "${platform}" = "android" ]; then
    # ローカルの adb クライアントへの SIGINT がリモートの screenrecord まで
    # 伝播しないケースに備え、リモート側にも明示的に停止シグナルを送る。
    adb shell pkill -INT screenrecord 2>/dev/null || true

    echo "⬇  録画ファイルを取得中..."
    # screenrecord がファイルを閉じる（サイズが安定する）まで待ってから pull する。
    local prev_size=-1 size
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
    local duration
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
}
