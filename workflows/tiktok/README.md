# Local TikTok workflow for Codex Cloud `open-edit`

Uses this checked-out OpenEdit fork, FFmpeg, Chromium and local WhisperX. No VEED login,
hosted transcription, fal, paid API or extra AI subscription. Network is used to install
packages and download public model weights; speech processing then runs locally.
Do not invoke the CLI's login, hosted transcribe, generate, fal, lipsync or project-upload routes.

## Setup in a new task

From the checkout:

```bash
bash workflows/tiktok/setup.sh
source workflows/tiktok/env.sh
```

The setup requires Node >=20.18.1, Python 3.12, uv, corepack, FFmpeg/ffprobe and Chromium.
Node 24 is suitable. Setup checks these and installs the frozen pnpm dependencies, builds the
local CLI, syncs the isolated Python dependency lock, downloads NLTK data and records
WhisperX `small.en`. It does not install into system Python. Model weights download on first use.
`bin/openedit` always runs this checkout, avoiding an unpinned registry CLI.
The local pnpm shim uses Corepack's `pnpm@10.16.1` from package.json.

`env.sh` resolves paths from the repository. Default Python environment:
`/workspace/.venvs/whisperx`; caches: `/workspace/.tiktok-state`; uv cache:
`/workspace/.cache/uv`. Override `TIKTOK_VENV` and `TIKTOK_STATE` before sourcing if needed.
WhisperX uses CPU/int8, two threads and ungated local Silero VAD. Torch 2.8 CPU and
torchcodec 0.7 are paired deliberately; latest torchcodec imported with an undefined symbol.
Use the lockfile rather than independently upgrading Python packages.

## Future input video

```bash
source workflows/tiktok/env.sh
bash workflows/tiktok/make.sh /absolute/path/input.mp4 my-reel
# final output: runs/my-reel/final.mp4
```

Chromium is launched through `bin/chromium-local` with `--no-sandbox` because the Cloud
container maps its setuid helper with a non-root owner. The outer container provides isolation;
keep compositions trusted and local.

Runs must have fresh keys (letters, digits, underscore, dash). The script normalizes to 30 fps,
center crops to 1080x1920, transcribes locally, builds an HTML composition, renders through
`openedit render` in Chromium and muxes normalized AAC audio. With no audio, stop and decide
whether manually authored text is appropriate. It does not invent captions.
For non-English speech use a multilingual model (`small` or `medium`) explicitly through
`openedit transcribe --provider whisperx ... --language es --model small`, then supply the
resulting transcript as the third make.sh argument. The wrapper preserves an explicit CLI root.

Each run contains footage.mp4, transcript.json, preset.json, index.html, silent.mp4 and final.mp4.
Edit `index.html` and rerender a range with `--from/--to`, or rebuild the page after correcting
transcript words. Keep captions human-reviewed, particularly names and technical vocabulary.
Any mapper warning about interpolated timings must be reviewed.

## Preset and editorial decisions

`presets/clean.json` is the reusable starting point:

- 9:16, 1080x1920, 30 fps; H.264 yuv420p MP4, AAC 48 kHz, faststart.
  Source normalization CRF 18; OpenEdit HTML render CRF 15. Audio aims at -14 LUFS/-1 dBTP;
  very short/quiet sources may use peak-limited gain (the CLI reports this).
- Up to four words per phrase, 30 characters; 68 px bold system Arial with outline/shadow,
  a warm yellow active word and 100 ms scale settle. Actual aligned word timestamps drive
  animation deterministically through `window.__seek`. Captions clear during gaps.
- Caption box leaves 410 px at bottom, 180 px at right, 100 px at left. Review against current
  TikTok UI and the speaker's face. Long words wrap; unusually long words need smaller text.
- Smooth 1.000–1.035 zoom over a six-second cycle; 120 ms opening/closing fade.
  Subject framing is a center-crop default, requiring manual adjustment per shot.
- Aim for a meaningful first 1–2 seconds, one clear idea, and a satisfying ending; 15–45 seconds
  is a starting range, not a forced duration. Review pauses >350 ms and holds around 2–5 seconds.
  Preserve intentional breaths, emotion and factual meaning. No random cuts or automatic filler deletion.

For cuts, first normalize source clips to matching canvas, frame rate and colour treatment,
then transcribe each source. Read `.claude/skills/open-edit/CUT.md`. Measure silence rather
than cutting on transcript boundaries:

```bash
openedit speech-probe /path/normalized.mp4 --gap 350 --json
openedit apply-edl --edl runs/edit/edl.json --out runs/edit/cut.mp4 --crossfade 40 --crf 18
openedit retime-transcript --edl runs/edit/edl.json --out runs/edit/transcript.json
bash workflows/tiktok/make.sh runs/edit/cut.mp4 edited-reel runs/edit/transcript.json
```

EDL shape (seconds; paths relative to the invocation directory, preferably absolute):

```json
{"sources":{"a":"/path/normalized.mp4"},"transcripts":{"a":"/path/transcript.json"},"ranges":[{"source":"a","start":0,"end":4.5},{"source":"a","start":5.2,"end":9.4}]}
```

40 ms crossfaded joins smooth microcuts while the CLI keeps the frame-grid timeline and
retimed words together. Use restrained longer visual dissolves for deliberate scene changes
only after reviewing motion; avoid transitions across important syllables. Never transcribe
an already retimed edit again. Pacing and crop decisions require the future footage.

## Verification

```bash
bash workflows/tiktok/smoke.sh
```

Downloads a public JFK speech excerpt from ggml-org/whisper.cpp for the local recognition and
alignment test, then renders two seconds of synthetic test-pattern footage with its word timings.
This is a diagnostic, not a real reel. No user footage has been supplied. See VERIFICATION.md
for this task's measured results. Dependency downloads need Cloud network permission; the
runtime proxy and CA trust remain enabled. NLTK's setup download explicitly trusts that proxy.

## Persistence and republishing

Task-local installs/caches are NOT promised to survive another Cloud task. This session exposes
runtime diagnostics but no environment configuration editor/publish action. Preserve these files
in your own fork (origin is Jefjones257/open-edit), never VEED's upstream repository.

In Codex's environment editor, edit `open-edit`, select the branch containing this workflow,
ensure its base/setup provides Node >=20.18.1, Python 3.12, uv, corepack, FFmpeg/ffprobe and
Chromium, and set its repository setup command to:

```bash
cd /workspace/open-edit
bash workflows/tiktok/setup.sh
```

Adapt the checkout path if the editor uses another path. On Debian with administrator access,
FFmpeg and Chromium are supplied by `apt-get update && apt-get install -y ffmpeg chromium`;
perform that in the environment build/setup, not a restricted task. Keep `OPENEDIT_STATE_DIR`
under a writable workspace path. Test the setup, then use the editor's Save/Publish/Republish
control to publish a new version of `open-edit`. Start a fresh task against that version and run
`smoke.sh` to confirm it. If setup networking is disabled, package/model download hosts must be
available during image setup; prewarm model caches by running the smoke command there.
No environment version was republished by this task.
