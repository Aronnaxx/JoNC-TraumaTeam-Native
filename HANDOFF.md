# Resume here — JoNC Trauma Team Native

Updated 2026-10-31. v0.2.0 native single-scene rescue pilot. Live test FAILED usability; not a playable baseline.
Entirely separate from TraumaTeam_OnCall. Prior preservation/research history:
[HANDOFF-v0.1.0.md](HANDOFF-v0.1.0.md), [RESEARCH.md](RESEARCH.md).

## Authorization

Ethan explicitly approved dev deployment and game tests in this chat: “You are A-OK
to run it when you're ready.” Existing HUD harness is installed. No further permission
needed to iterate this pilot's reversible dev test. Check running_apps before GUI,
respect other games, never touch On Call sources or Vortex configuration.

## Current implementation

- Runtime.reds: opt-in ScriptableSystem, generation-guarded gameplay-time loop;
  original roof/crew/AV assets; mounting validation; eased ascent/cruise/descent;
  original TraumaSpot_27 dock patient; four source-derived treatment outcomes;
  return flight, debrief, repeat, timeout/abort cleanup, session detach cleanup.
- Journal.reds + build_journal.py: independently owned journal, seven linear pilot
  objectives, GPS map pin, globally streamed marker, localization in a second archive.
  Exclamation variant implemented; scoped red coloring is still outstanding.
- RuntimeHud.reds: live patient card, choice labels, progress bar, serialized voiced
  subtitles. Generated PatientCard remains generated; host placement is authored.
- Original 68 WAVs retained; selected lines wired to Audioware using measured durations.
- InputLoader XML: F8 start, F1 interaction/first aid, F2 firmware, F3 hotfix,
  F4 recovery; F7 abort/return or dismiss outcome. These avoid On Call's F/R keys.
- `tools/e2e/projects.json` project `jtt_native`; scenarios `jtt_native_roof` and
  `jtt_native_roundtrip`. Full scenario checks actual states, never writes them;
  latches errors to prevent later teleports after a failed stage; dumps each capture.

## Validation so far

Offline compile 0 errors/0 warnings; eight original preservation tests pass;
84-file v0.2.0 zip convention checks pass; lint and tweak structure checks clean.
PyYAML absent: YAML checks are structural, not a full parser. Journal build now
converts four explicit JSON files individually (never a folder with binary .json).
Both archives are independently namespaced. These checks do not prove playability.
Dev-deployed 84 NEW files (no existing mod replaced), user-authorized. See live findings below.

## Still missing from original parity

World recruitment board and journal-menu click, crew walking, boarding glitch/animation,
patient/medic/V workspot animations, original dynamic conversation choice selector,
hostile/protection branches, 116 other locations, membership/website/rescue systems.
Current pilot has function-key choices, an unconscious patient, instantaneous boarding,
and a noncombat fixed route. No ambient-hostile safety scan or obstacle avoidance.
No mid-call save resume: loading cleans up; do not call this a complete native port.

## Next steps

Read live test artifacts; fix runtime/placement failures, repeat roof then full trip.
Inspect screenshots with widget dumps. Validate successful treatment, risk failure,
cancel/out-of-range, repeated calls, abort in flight and save/load cleanup. Update
this file with actual evidence and final deployment state; remove dev deployment at
end unless Ethan asks to keep it. Do not disable original JoNC or On Call implicitly.

## Files/build

`python JoNC-TraumaTeam-Native-source/build.py` regenerates views/content, builds only
the four journal resources, verifies original preservation, packages r6 + archive.
Existing eight AV assets remain in JoNCTTNative.archive. Generate_native.py owns
Content/VoiceContent/PatientCard/RecruitmentBoard, not runtime classes.

## Housekeeping

Ethan manually removed the unintended 20.75 GB extraction output (confirmed in chat).
Never repeat unfiltered wk_extract mode=serialize; use filtered extract then convert.

## Live findings / lower-cost-model handoff (2026-10-31 14:13)

User has ~20% usage left and asked about a smaller model. Keep next pass narrow.
User correctly reported: only sergeant + one crewman visible; no patient HUD or usable
treatment; asked whether old JoNC and On Call had been disabled. THEY WERE NOT.
This was a test-isolation oversight. Next test must reversibly disable both old JoNC
and On Call first, recording/restoring exact prior state. Do not change their sources.

- Roof scenario artifacts: artifacts/runs/20261031-140418_jtt_native_roof;
  screenshots 20261031-140612_jtt_recruitment.png and 20261031-140630_jtt_av_roof.png.
- Harness reported success for limited state assertions, but screenshot review FAILED:
  custom HUD is off-screen. RuntimeHud root is 3840x2160 centered in a 1024x768
  virtual window. Fix top-left, pivot(0,0), root scale=windowHeight/2160, canvas
  width=windowWidth/scale. Existing READ-ONLY example TTHelmetHud.reds lines706-725.
  Scale the canvas, never individual text widgets. Reposition subtitle within width.
- Native quest title/tracker and GPS route appeared. AV spawned/descent finished.
  All four crew initially reported correct custom mounted slots on roof.
- Manually used normal runtime Action(0) to board; player traveled to dock/state9.
  During flight AllMounted() became false. At scene two crew positions remained
  (-1351,1784,130),(-1351,1783,130); other two at dock. Root cause not proven;
  probably AI unmount behavior/duplicate low-level + AIMountCommand needs scrutiny.
  Do not claim all crew transported. Flight currently checks only player's mount.
- Roof AV rear door remained closed. Legacy function VehicleDoors uses
  vehicle:GetVehiclePS():OpenAllRegularVehDoors(false), CloseAllVehDoors(false).
- Patient spawned/state9 health1; UI off-screen so treatment unavailable in practice.
  No completed treatment, return flight, success, repeat or failure tests performed.
  Keys F1-F4 exist but are not an acceptable final replacement for original choices.
- User explicitly requested disable NCPD heat only DURING missions. NOT IMPLEMENTED.
  Live RTTI DumpType('PreventionSystem') confirmed IsSystemEnabled(), IsSystemLocked(),
  TogglePreventionSystem(toggle: Bool), OnTogglePreventionSystem(TogglePreventionSystem),
  systemLockSources array<CName>, OnClearPreventionSystemLocks, ChangeHeatStage,
  and TogglePreventionGlobalQuestObjective_Internal(preventionGlobalQuestDisabled,
  eventSource:CName). Inspect TogglePreventionSystem request fields/engine behavior;
  prefer own named lock/source so releasing ours never overrides another mod/quest.
  Must restore on success/failure/abort/load/detach and test pre-disabled system.
- User-authorized test was aborted through runtime cleanup, then game exited via
  harness quit. No manual save requested. Temporary native deployment was undone;
  all 84 native files removed, none skipped. Original mods remained enabled throughout.

NEXT PRIORITY: isolated environment + HUD root scale, crew retention, real treatment
input, NCPD mission lock. Rebuild/compile then inspect each short stage before full loop.
Use small tool outputs; do not dump full RTTI or 84-file manifests into model context.

User offered to perform manual gameplay tests to conserve usage. Prefer static checks + a narrowly scoped test build and short user checklist; avoid another long automated full-mission run unless needed. Current build is NOT ready for user testing. Game closed; all 84 native dev files removed successfully, none skipped. On Call and legacy JoNC remain enabled/unmodified.
