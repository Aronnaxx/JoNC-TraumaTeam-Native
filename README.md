# Jobs of Night City: Trauma Team — Native

v0.2.0 single-scene rescue pilot. Independent from Trauma Team On Call.

The mission runtime is now implemented, but live validation is in progress. This is
not yet a complete or stable replacement for the original. See [HANDOFF.md](HANDOFF.md)
for current evidence, remaining parity work, and deployment state.

## Pilot controls

After testing/deployment: F8 starts a call and tracks MedCenter. Travel there, then F1
joins the rooftop crew. F1 near the AV boards; during treatment F1 applies first aid,
F2 reboots firmware, F3 applies hotfix, F4 starts recovery. First aid is safe; other
choices can reduce the original treatment score. Above 50 permits evacuation. F1
near the AV boards for return. F7 aborts and returns to MedCenter; on the outcome
screen it dismisses the HUD. F8 starts another call. Keyboard bindings are temporary;
the original interaction-choice presentation remains to be ported.

## Dependencies and scope

RED4ext, redscript, Codeware, ArchiveXL, TweakXL, Audioware and InputLoader. Versions
and upstream 2.5 support evidence are in [RESEARCH.md](RESEARCH.md). CET is used only
by the external development test harness; no CyberScript runtime dependency.

Original assets, all 119 reference files, all 44 definitions, seven seat workspots,
AV entity, 68 voices and ten supplied screenshots are preserved. The pilot currently
uses one original dock location, four crew, an unconscious patient, native journal,
instant seat transitions, scripted flight and treatment HUD. Animated boarding and
treatment, world recruitment UI, combat branches, random calls, membership and rescue
systems remain incomplete. No mid-call save resume or obstacle avoidance yet.

## Build and test

Run `python JoNC-TraumaTeam-Native-source/build.py` from the repo root. Run lint and
redscript_check with override `JoNC-TraumaTeam-Native-source/r6/scripts/JoNCTTNative`.
The e2e project is `jtt_native`; test roof first, then `jtt_native_roundtrip`.
Dev deployment and game tests are authorized for this session. Do not install it
through Vortex until live evidence supports a user-testable release.
