# Jobs of Night City: Trauma Team — isolated native migration

Version 0.1.0, 2026-10-31. **Developer baseline, not a playable replacement.**

This project preserves a complete copy of JoNC Trauma Team and begins converting its
content to redscript/Codeware. It is completely separate from `TraumaTeam_OnCall`.
Nothing has been installed, launched or changed in Vortex or the game by this work.

Read [HANDOFF.md](HANDOFF.md) first when resuming, then [RESEARCH.md](RESEARCH.md).

## What exists

- Complete original 5.0.0 download and byte-identical patched 5.0.5 reference (119 files).
- Local CyberScript fork and game-resource zip snapshots for researching dependencies.
- Lossless catalog of all 44 JSON files, all 12 objective definitions, four treatment
  timelines, 68 measured voice durations, source pointers, and SHA-256 provenance.
- Native ink construction for the 26-control patient card and 17-control recruitment
  board, preserving atlas references, shape vertices and original geometry. Patient
  text has typed live bindings. No text widget scaling.
- Native treatment model, source-derived choices, timing, outcome ranges and progress
  checkpoints; callable preview composition and objective unlock graph.
- Eight repathed AV/workspot resources in `JoNCTTNative.archive`, independent
  `JoNCTTNative.AV` TweakXL record, 68 original WAVs with `jttnative_` Audioware keys,
  native subtitle and measured duration lookup.

The raw JSON is reference/content data. There is **no CyberScript interpreter** in
the new runtime. Copying JSON does not implement its actions in redscript.

## What does not exist yet

An active quest runner, native journal resource and tracking bridge, world board
interaction, NPC spawning/AI, mount/workspot orchestration, AV flight, audio playback
queue, treatment interaction choices/progress-bar renderer, persistence and cleanup
are not wired. Nothing automatically appears in game. The native preview requires
a harness/host to supply an ink parent and tick it. Do not install expecting a job.

The two view classes compile but are not visually verified. Board event/context
logic is preserved in the catalog but not bound in the generated view. Its native
layout and text styles require screenshot comparison before a claim of visual parity.

## Build

From the repository root:

```powershell
python JoNC-TraumaTeam-Native-source/import_baseline.py
python JoNC-TraumaTeam-Native-source/prepare_assets.py
python tools/agent/cpt.py wk_convert direction=deserialize path=JoNC-TraumaTeam-Native-source/archive_src/JoNCTTNative
python JoNC-TraumaTeam-Native-source/stage_archive.py
python tools/agent/cpt.py wk_pack folder=JoNC-TraumaTeam-Native-source/archive_src/packed/JoNCTTNative out=JoNC-TraumaTeam-Native-source/archive/pc/mod
python JoNC-TraumaTeam-Native-source/build.py
python tools/agent/cpt.py lint paths='["JoNC-TraumaTeam-Native-source/r6"]'
python tools/agent/cpt.py redscript_check override='["JoNC-TraumaTeam-Native-source/r6/scripts/JoNCTTNative"]'
```

`archive_src/legacy` already contains the eight extracted original resources. To
regenerate it, use **unbundle/extract with a filter**, then `wk_convert serialize`.
Do not use `wk_extract mode=serialize`: its `uncook -gp` expanded unrelated game
resources during this session. See the log.

Build output is `JoNC-TraumaTeam-Native-v0.1.0.zip` at the repo root. It contains only
new namespaced components; original archives, JSON catalogs and CyberScript are
excluded. Keep these reference files in the source project for continuation.

Credits: JoNC author donk7413; Ethan reports permission to reuse the author's
systems in On Call. CyberScript/Artheriax snapshots are research references, not
bundled runtime code. Game atlas/animation paths refer to resources in the game.
