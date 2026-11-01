#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
[[ $# -ge 2 && "$2" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo 'Usage: make.sh source-video key [already-retimed-transcript.json]' >&2; exit 1; }
input="$(realpath "$1")"; key="$2"; run="$TIKTOK_REPO/runs/$key"
[[ ! -e "$run" ]] || { echo "Run exists: $run; use a fresh key to protect edits" >&2; exit 1; }
mkdir -p "$run"
# Center crop is a starting point; review framing and move crop for each speaker.
ffmpeg -nostdin -v error -i "$input" -vf 'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30' -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -ar 48000 -b:a 192k -movflags +faststart "$run/footage.mp4"
if [[ $# -ge 3 ]]; then cp "$3" "$run/transcript.json"; else
 # The filename key must match the run, so use an explicit CLI root for transcription.
 OPEN_EDIT_ROOT="$run/transcription" node "$TIKTOK_REPO/cli/dist/cli.js" transcribe --provider whisperx "$run/footage.mp4"
 cp "$run/transcription/runs/footage/transcript.json" "$run/transcript.json"
fi
duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$run/footage.mp4")"
node "$TIKTOK_REPO/workflows/tiktok/build-page.mjs" "$run/footage.mp4" "$run/transcript.json" "$run" "$duration"
openedit render "$run/index.html" --out "$run/silent.mp4" --fps 30 --duration "$duration" --workers 1 --chrome "$TIKTOK_REPO/workflows/tiktok/bin/chromium-local"
openedit mux-audio --video "$run/silent.mp4" --audio "$run/footage.mp4" --out "$run/final.mp4"
ffprobe -v error -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate,sample_rate -of json "$run/final.mp4"
