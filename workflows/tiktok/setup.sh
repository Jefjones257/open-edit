#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TIKTOK_REPO"
node -e 'let [a,b,c]=process.versions.node.split(".").map(Number);if(a<20||(a===20&&(b<18||(b===18&&c<1))))process.exit(1)'
for tool in ffmpeg ffprobe chromium uv corepack; do command -v "$tool" >/dev/null || { echo "Missing $tool; install via the Cloud environment editor setup script" >&2; exit 1; }; done
pnpm install --frozen-lockfile --ignore-scripts
pnpm run build
uv venv --python 3.12 --allow-existing "$TIKTOK_VENV"
uv pip sync --python "$TIKTOK_VENV/bin/python" workflows/tiktok/requirements.lock --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
NLTK_ALLOW_PROXIED_URLOPEN=1 "$TIKTOK_VENV/bin/python" -c 'import nltk,os; assert nltk.download("punkt_tab", download_dir=os.environ["NLTK_DATA"])'
openedit init --workspace "$TIKTOK_REPO"
openedit transcribe --record whisperx --model small.en
openedit install-ffmpeg --check
"$TIKTOK_VENV/bin/python" -c 'import whisperx; from torchcodec.decoders import AudioDecoder; import importlib.metadata as m; print("WhisperX",m.version("whisperx"))'
echo 'Ready. Source workflows/tiktok/env.sh in each future task. Models download on first transcription.'
