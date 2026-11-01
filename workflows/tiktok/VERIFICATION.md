# Verified in Cloud `open-edit`

Measured 2026-10-31 (America/Bogota; execution host was already Nov 1 UTC).
Base checkout: `1d3b75b` (`Mirror from veed-llm-editor (#29)`), fork remote
`https://github.com/Jefjones257/open-edit.git`. CLI reports `0.0.0-dev`, so the
Git revision identifies the source build rather than a published npm version.

| Dependency/check | Actual result |
| --- | --- |
| Node | v24.19.0; meets >=20.18.1 |
| Python | 3.12.14 |
| pnpm via local Corepack wrapper | 10.16.1 |
| FFmpeg / ffprobe | 7.1.5-0+deb13u1, `/usr/bin/ffmpeg`, `/usr/bin/ffprobe` |
| Chromium | 154.0.8037.57, `/usr/bin/chromium` |
| OpenEdit | checkout CLI built with `pnpm run build`; `openedit init` reports ready |
| WhisperX | 3.8.4, `/workspace/.venvs/whisperx/bin/whisperx` |
| Torch / torchaudio | 2.8.0+cpu / 2.8.0+cpu |
| torchcodec | 0.7.0; AudioDecoder imports successfully |
| Python dependency consistency | `uv pip check`: all 103 packages compatible |
| Repository build/type check | `pnpm run build`, `pnpm run typecheck:cli` pass |
| Reproducible setup | `bash workflows/tiktok/setup.sh` completes with preflight ready |
| Local recognition and alignment | `small.en`, CPU/int8, Silero; JFK sample -> 22 timed words |
| CLI provider path | `openedit transcribe --provider whisperx ... --language en --model small.en` completes with `HF_HUB_OFFLINE=1` after model download |
| Render | HTML through OpenEdit/Chromium: 60 frames, 2.000 s, 1080x1920, 30 fps; about 28 s wall time |
| Delivery FFprobe | H.264, yuv420p, 1080x1920, 30/1; AAC, 48000 Hz; 2.000000 s |

Smoke artifacts (task-local, ignored by Git):

- `/workspace/open-edit/runs/setup-smoke/jfk.wav`: public sample from
  `https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav`
- `/workspace/open-edit/runs/setup-smoke/jfk.json`: WhisperX output with aligned words.
- `/workspace/open-edit/runs/jfk/transcript.json`: OpenEdit mapper output.
- `/workspace/open-edit/runs/setup-smoke/provider-test/runs/jfk/transcript.json`:
  successful integrated CLI transcription.
- `/workspace/open-edit/runs/setup-render/index.html`: caption/zoom composition over synthetic testsrc2.
- `/workspace/open-edit/runs/setup-render/final.mp4`: diagnostic H.264/AAC delivery file.
- `/workspace/open-edit/runs/setup-smoke/{setup,transcription,provider,render,mux}.log`: command evidence.

Setup fixes: writable Hugging Face/Torch/NLTK/XDG/pnpm cache locations, punkt_tab resource,
matching torchcodec version and local Silero VAD. System Chromium's setuid helper is mapped
with a non-root owner in this Cloud container, so `bin/chromium-local` passes `--no-sandbox`;
the outer Cloud container provides isolation. Use only trusted local compositions here.
This is explicit in the wrapper rather than modifying the upstream renderer.

No VEED sign-in, hosted transcription, paid API, generation or subscription was used.
No real reel was made; the source video is still outstanding. Caption accuracy, source framing,
editorial pacing and joins must be reviewed on that future footage. Browser rendering at this
CPU speed is relatively slow (roughly 14x video duration in this tiny test).

No environment version was republished. Installed environments (about 2.7 GB) and model/cache
state (about 875 MB at this point) are task-local. See README.md for the environment editor's
setup/republish steps; these measurements do not establish persistence across tasks.
