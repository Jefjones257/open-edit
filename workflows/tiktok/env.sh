# Source from Bash; all writable state stays below /workspace by default.
TIKTOK_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export TIKTOK_REPO
export TIKTOK_STATE="${TIKTOK_STATE:-$(dirname "$TIKTOK_REPO")/.tiktok-state}"
export TIKTOK_VENV="${TIKTOK_VENV:-$(dirname "$TIKTOK_REPO")/.venvs/whisperx}"
export COREPACK_HOME="${COREPACK_HOME:-$(dirname "$TIKTOK_REPO")/.corepack}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-$(dirname "$TIKTOK_REPO")/.cache/uv}"
export HF_HOME="$TIKTOK_STATE/huggingface" TORCH_HOME="$TIKTOK_STATE/torch"
export MPLCONFIGDIR="$TIKTOK_STATE/matplotlib" XDG_CACHE_HOME="$TIKTOK_STATE/cache"
export NLTK_DATA="$TIKTOK_STATE/nltk_data"
export HF_HUB_DISABLE_TELEMETRY=1 DO_NOT_TRACK=1 HF_HUB_DISABLE_XET=1
export XDG_DATA_HOME="$TIKTOK_STATE/data" PNPM_HOME="$TIKTOK_STATE/pnpm"
export npm_config_store_dir="$(dirname "$TIKTOK_REPO")/.pnpm-store"
export XDG_CONFIG_HOME="$TIKTOK_STATE/config"
export OPEN_EDIT_ROOT="${OPEN_EDIT_ROOT:-$TIKTOK_REPO}" OPENEDIT_STATE_DIR="$TIKTOK_STATE/openedit"
export NO_UPDATE_NOTIFIER=1 OPEN_EDIT_WHISPERX_DEVICE=cpu OPEN_EDIT_WHISPERX_COMPUTE=int8
export WHISPERX_BIN="$TIKTOK_REPO/workflows/tiktok/bin/whisperx-local"
export PATH="$TIKTOK_REPO/workflows/tiktok/bin:$PATH"
mkdir -p "$TIKTOK_STATE" "$HF_HOME" "$TORCH_HOME" "$MPLCONFIGDIR" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$PNPM_HOME"
