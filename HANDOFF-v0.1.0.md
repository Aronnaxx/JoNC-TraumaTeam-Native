# Resume here — JoNC Trauma Team Native

Updated 2026-10-31; version 0.1.0. **Full legacy copy preserved; native migration
partial; no playable quest yet.** Independent of `TraumaTeam_OnCall` by user request.

## User intent and constraints

Ethan has the JoNC author's permission and wants almost the same recruitment →
journal/route → roof briefing → crew/AV ride → medical HUD → treatment → return flow.
First establish a modern supported stack and attempt a full independent baseline.
Do not redesign career progression or merge this into On Call. Do not change
game/Vortex state or download dependencies without authorization. No deployment
approval was requested because this package is not ready for gameplay testing.

## Completed

- Read repo AGENTS/CLAUDE/HANDOFF, ran doctor/repo status, inspected original mod and
  framework code, verified patched 5.0.5 has 119 deployed-identical files.
- Chosen stack: redscript + Codeware + ArchiveXL + TweakXL + Audioware / RED4ext.
  Upstream support checked; evidence and detailed mechanisms in `RESEARCH.md`.
- `original/`: original 5.0.0 7z, patched 5.0.5 zip and extracted 119-file copy,
  CyberScript fork 5.1.9.6 and GameArchive 5.1.9 zip snapshots, hash manifest.
- `reference/`: all ten user screenshots and focused framework source excerpts.
- `data/`: all 44 original JSON definitions, 12 objective definitions, four treatment
  timelines, 68 measured WAV durations. 117 authored mission locations retained.
- `r6/scripts/JoNCTTNative`: generated PatientCard, RecruitmentBoard, Content,
  VoiceContent; authored Patient, Preview, ObjectiveGraph.
- `archive/pc/mod/JoNCTTNative.archive`: exactly eight resources, all under
  `jttnative/`; seven seat workspots and original AV entity with internal references
  remapped. `r6/tweaks/JoNCTTNative/av.yaml` owns `JoNCTTNative.AV`.
- `r6/audioware/JoNCTTNative`: 68 unchanged WAVs; unique `jttnative_` event names.
- Repo-root `JoNC-TraumaTeam-Native-v0.1.0.zip`: 78 new component files only.

## Validation

- Offline redscript compile against deployed 2.5 set: **0 errors / 0 warnings**.
- Eight preservation/content/isolation tests passed (`test_baseline.py`). These
  validate generated data and assets, not runtime redscript execution.
- Source/package lint: no errors/warnings. PyYAML is absent, so general YAML parser
  validation was not available; audio keys/paths checked by dedicated tests.
- WolvenKit deserialize and pack succeeded; archive listing has eight entries,
  no authoring JSON and no original resource paths as archive entry names.
- Zip conventions passed; deploy status reports **78 missing / not deployed**.
- No game launch, GUI input, installs, downloads or edits to On Call.

## Next work, in order

1. Add a deliberate test host for `JTTPreview.Create(parent)` and review patient
   card against `reference/user-06.png`/`user-07.png`. It currently accepts a caller-
   provided ink parent and tick; there is no automatic attachment. Fix margins,
   font, wrapping, anchor and HDR behavior using screenshots, not compile results.
2. Native recruitment vertical slice: independently owned world-widget entity,
   board input callbacks, ArchiveXL journal resource, tracked-objective bridge and
   scoped red mappin styling. Source board opens `quest_log` only. No `.journal`
   exists yet. Preserve selectable/recurrent behavior and ordinary quest tracking.
3. Mission runner: explicit state + cancellable DelaySystem callbacks, save/load
   recovery, unique per-run entity ownership and cleanup. `ObjectiveGraph` only
   copies default unlock edges; apply source `context`/branch logic before using
   it (there are protection/player-treatment branches). Never simply advance a
   timer through every objective or silently treat unsupported actions as success.
4. Spawn officer/crew using Codeware. Officer data lives in framework reference,
   not JoNC's own files. Use independent IDs, keep allies out of police prevention.
5. Rebuild generic animation/workspot adapter. The eight JoNC assets do NOT include
   CyberScript's `workspot_anim.ent`/world-widget entity/animation catalog. Extract
   only required resources from the preserved GameArchive zip with filters, inspect
   dependencies, namespace them or author replacements; don't ship all CyberScript.
6. Seated AV round trip: crew movement/mount readiness, V glitch/workspot boarding,
   delta-time descent/cruise/landing, timeouts and safe abort/reload. Validate on roof
   and one fixed scene before enabling any of the 117 random locations.
7. Serialized Audioware queue + subtitles, using actual duration lookup; hostile flag
   briefing and arrival spawning. No audio playback is currently wired.
8. Treatment interaction choice UI, V animation and progress-bar renderer wired to
   `JTTPatient`; source risk ranges documented. Resolve exactly-zero failure as
   documented. Preserve original score display first, then separately decide whether
   real BPM/condition should replace it. No treatment input is currently registered.
9. Full round-trip success/failure/repeat/reload tests, then membership/rescue/website
   systems (preserved in the full catalog, not implemented natively). Only claim full
   copy parity when every original subsystem is accounted for and tested.

## Build / references

See README for build commands. `generate_native.py` owns generated files; do not
hand-edit them. `prepare_assets.py` owns resource/audio renaming. `build.py` only
packages `r6/` and `archive/`; cannot accidentally include legacy loader or On Call.
Run the compile after generation; package build does not automatically compile.

## Outstanding housekeeping incident

`wk_extract mode=serialize` used `uncook -gp` and unexpectedly expanded unrelated
game resources. Own WolvenKit process was stopped. Replacement filtered unbundle
and separate serialize returned exactly eight assets. Automatic approval review
blocked recursive deletion with only “blocked by policy”. The unintended output
was moved safely to `archive/runs/jtt-unintended-extraction-20261031` (47,912 files,
20.75 GB decimal). **Removed manually by Ethan, confirmed in chat 2026-10-31.** Excluded from package/source.
Do not repeat that unfiltered serialize mode. No game resources were modified.
