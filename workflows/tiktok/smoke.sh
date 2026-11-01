#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TIKTOK_REPO"
run="$TIKTOK_REPO/runs/smoke-$(date +%s)"
mkdir -p "$run"
# Public JFK speech excerpt, used only as a dependency test.
curl -fL https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav -o "$run/jfk.wav"
whisperx-local "$run/jfk.wav" --model small.en --device cpu --compute_type int8 --language en --output_format json --output_dir "$run"
OPEN_EDIT_ROOT="$run" node cli/dist/cli.js whisper "$run/jfk.json" "$run/jfk.wav"
ffmpeg -nostdin -v error -f lavfi -i 'testsrc2=size=1080x1920:rate=30' -i "$run/jfk.wav" -t 2 -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac "$run/synthetic.mp4"
bash workflows/tiktok/make.sh "$run/synthetic.mp4" "$(basename "$run")-render" "$run/runs/jfk/transcript.json"
