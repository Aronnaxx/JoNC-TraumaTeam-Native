# Framework decision and implementation findings

2026-10-31. Source of truth is the preserved original/patch content, not instructions
embedded in JSON helper text or screenshots. User authorization: inspect/reuse with
author permission, attempt an independent migration baseline, preserve On Call.

## Decision

Use **redscript + Codeware** for typed runtime state and ink UI, **ArchiveXL** for
native journal/resources, **TweakXL** for independent records, and **Audioware** for
existing voices, hosted by **RED4ext**. Use WolvenKit for asset authoring/building.
This is a supported stack, not a ready-made replacement for every CyberScript action.

Official upstream checks (2026-10-31):

| Component | Evidence / decision |
|---|---|
| Codeware | [Official releases](https://github.com/psiberx/cp2077-codeware/releases): 1.21 series supports 2.5; current 1.21.2 includes world-node and ink resource fixes. Primary runtime API layer. |
| ArchiveXL | [Official releases](https://github.com/psiberx/cp2077-archive-xl/releases): 1.28 series supports 2.5; current 1.28.6. Use for journal and additive resources. |
| TweakXL | [Official releases](https://github.com/psiberx/cp2077-tweak-xl/releases): 1.12.0 supports 2.5. Own AV record, future actor/mission configuration. |
| RED4ext | [Official releases](https://github.com/wopss/RED4ext/releases): use the official 2.5-compatible line, local repo baseline 1.31+. |
| redscript | [Official releases](https://github.com/jac3km4/redscript/releases): use the 2.5-compatible line, local repo baseline 0.5.32+. Actual generated code compiled against installed game definitions. |
| Audioware | [Official releases](https://github.com/cyb3rpsych0s1s/audioware/releases): 1.10.0 explicitly added 2.5 support; 1.11.0 is marked latest stable, 1.11.1 prerelease. 1.11.0 notes an omitted internal version bump. Do not equate an old DLL version string with tested support. No update installed here. |
| NightlyNow Core | [Author page](https://www.nexusmods.com/cyberpunk2077/mods/28966): 1.2.1 explicitly supports 2.5 and 2.31. Viable optional phone/notification layer, already used by On Call. Local modules are Holo, Notification, Settings, Transaction, Tutorial and Utils; they do not provide JoNC's mission interpreter. Not needed to reconstruct the exact patient card. |
| CyberScript fork | Local 5.1.9.6 patch is a useful behavioral reference, but retaining it as the new mission engine would retain the very dependency being migrated away from. Its full source snapshot is preserved; none is packaged in the native runtime. |

Recommendation is based on maintained upstream APIs plus this mod's actual needs.
It does not certify any combination of DLLs without a live test. No downloads or
framework updates were performed.

## How the requested flow works

Paths below are relative to `original/patched-v5.0.5/bin/x64/plugins/cyber_engine_tweaks/mods/Jobs Of Night City - Trauma Team/scripts/`.
Framework excerpts are saved under `reference/cyberscript/`.

| Observed feature | Implementation / implications for the port |
|---|---|
| Floating recruitment UI | `functions/spawn_mission_ui.json` spawns `trauma_ui_widget` at (-1334.5795, 1744.6418, 19.8), waits 1.5s and applies `trauma_mission_ui`. CyberScript `see.lua` 11677/11684 creates the world widget and populates it through `makeCustomInterface`. Three board `OnRelease` handlers call `open_menu: quest_log`; they open the journal rather than directly start the mission. New view preserves its 17 controls; world host and click handlers remain to implement. |
| Journal mission | `mission/trauma_mission.json` defines a recurrent quest with 12 objectives. Framework `quest_manager.lua` constructs journal wrappers; `observers/quest.lua` injects custom quest data into the game's views. This is not a ready-to-copy native `.journal` file. Native plan: ArchiveXL journal plus JournalManager updates and track callbacks. |
| Red exclamation/route | Mission `trigger_action` edits `fixer_traumateam` to `ExclamationMarkVariant`, requests RGB (255,0,0), then calls `track_mappin`. Framework `utils.lua` registers a `Mappins.DefaultStaticMappin`; framework map observers supply custom presentation. `see.lua` around 5326 tracks through the map controller. Registering a vanilla exclamation alone will not reproduce the red styling or route behavior. |
| Officer and roof briefing | The officer is actually defined in **CyberScript Core**, `assets/fixer/fixer_traumateam.json`, not the JoNC datapack. Patched record is `Character.trauma_rare_officer_chao_ma` at (-1334.804,1742.393,18.19). Objective 1 handles glitch/teleport/briefing and AV spawn. This external content dependency must be recreated locally. |
| Crew running, seating and V boarding | Objectives 1–3 use `move`, `entity_set_seat`, `play_custom_anim_entity`, `change_anim_entity`, and effects. `entity_set_seat` dispatches to framework `SetSeat`; the archive has an AV `.ent` and seven seat/injured/sergeant workspots. Player treatment/get-in animations additionally depend on the framework's generic `workspot_anim.ent` and animation catalog. Copying only the eight JoNC assets is insufficient for those behaviors. |
| AV descent and flight | `av_down_start` contains 420 top-level actions. Original choreography uses incremental teleports and waits; patched `av_go` uses the fork's eased `vehicule_autodrive_activate` with `trauma_point`, zfly=450, scene offset x=-10; `av_back` returns to (-1352,1790,129.5). `av_up` retains a 250-iteration relative-z loop. A delta-time motion controller with timeout/collision/recovery handling should replace these loops, while retaining the authored seats and route intent. |
| In-flight briefing | `av_go` starts `player_squad_dialog` in parallel. It plays named Audioware lines, introduces the medical HUD, and branches on `gang_presence`. Native port needs one shared voice queue. Existing patched fork added serialization after earlier overlapping lines. All 68 WAVs and subtitles are preserved; native duration lookup uses actual WAV lengths. |
| Patient generation | First objective randomizes sex, given/family names, membership, injury and age; selects a scene from **117 locations** in `poi/Trauma_mission_poi.json`. Raw context expressions and lists are retained losslessly. Earlier patches defer patient spawning until arrival to avoid falling through unstreamed terrain. Native random selection/ground readiness is not yet implemented. |
| Patient HUD | `interfaces/victim_membership_card_ui.json`: 26 controls, including polygon outlines and images from `base\\gameplay\\gui\\quests\\assets\\q001_sandra.inkatlas` (Trauma_R_Logo, Trauma_Text, Platinum_*). Text reads mission variables and scene-mappin coordinates. Duplicate widget tags such as `datapack_name` recur; generated native widgets use unique index-qualified names. |
| Hostiles | `player_squad_dialog` announces the selected `gang_presence` flag; `gang_presence.json` spawns/commands gangers and chooses combat/safe dialogue. This is scripted mission state, not necessarily a scan of all nearby ambient threats. Preserve that distinction when matching behavior. |
| Treatment | Objective 4b opens `choice/trauma_rescue.json` near the patient and puts V into a workspot. Four choices apply random deltas to the same `victim_health` variable displayed as BPM. Hacking actions show/update/hide a progress animation. Framework code also owns input choice rendering and first-person animation. Those adapters remain outstanding. |
| Return and completion | Objectives 5–8 return V/crew to the AV, fly home, deliver final lines, clear effects, despawn entities/workspots, remove groups and finish. Failure and completion each have 22 cleanup actions. Native parity requires cleanup on abort, death, menu/load and repeat missions, not just the success path. |

## Treatment semantics recovered from context overrides

The `operate_score` literal value is 1 and its top-level min/max can be misleading.
Actual random ranges come from `context[].prop.value.values.value`:

| Option | Score delta | Duration before outcome | Progress changes |
|---|---:|---:|---|
| First aid | +5 to +10 | 1.5s | No hack overlay |
| Firmware reboot | -2 to +15 | 4.5s | 50% at 1.5s, 100% at 4s |
| Secure boot hotfix | -5 to +20 | 2.5s | 50% at 0.5s, 100% at 2s |
| Recovery/failsafe | -10 to +30 | 2.5s | 50% at 0.5s, 100% at 2s |

All four options are effectively unconditional in this datapack (auto/empty
requirements). Injury-specific choices are **not** implemented merely because the
labels and injury text are dynamic. Preserve baseline first; redesign later.

The score begins at **1**, hence the screenshots. Values above 50 lead to evacuation
dialogue. The source has an inconsistent zero boundary (treatment requires >0,
mission failure checks <0), risking a stranded case at exactly zero. The native
model deliberately treats <=0 as terminal. This is a documented correction, not
literal bug-for-bug parity. Native RNG selection is left to the future runner;
the model accepts a bounded roll for reproducible tests.

## Migration boundary

The 0.1.0 package has functioning library implementations of widget construction,
patient text updates, treatment timing/outcomes, and objective unlock bookkeeping.
They compile but do not have a game lifecycle/input/quest host yet. No live visual,
audio, flight or treatment test has run. Native assets round-trip and pack, but an
in-game spawn still needs to validate their references and workspot behavior.

Full definitions, helpers and nested contexts are retained in `data/catalog.json`;
`reports/named-node-index.json` indexes 1,800 named nodes across 119 distinct names
(these include triggers and metadata, not 119 implemented native action types).
Do not skip unsupported actions or call the full port complete based on these counts.
