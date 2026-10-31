module JoNCTTNative
import Audioware.{Tween, AudioSettingsExt}

// Single authored, noncombat rescue for validating the native transport/treatment loop.
// No legacy interpreter or On Call runtime dependency. Run-owned entities never persist.
public class JTTRuntime extends ScriptableSystem {
  public let state: Int32;
  public let message: String;
  public let patient: ref<JTTPatient>;
  private let generation: Int32;
  private let tickID: DelayID;
  private let clock: Float;
  private let elapsed: Float;
  private let flightElapsed: Float;
  private let flightDuration: Float;
  private let flightStart: Vector4;
  private let flightEnd: Vector4;
  private let flightPhase: Int32;
  private let returning: Bool;
  private let owned: array<EntityID>;
  private let crew: array<EntityID>;
  private let av: EntityID;
  private let victim: EntityID;
  private let treatmentIndex: Int32;
  private let treatmentRoll: Int32;
  private let voices: array<CName>;
  private let voice: CName;
  private let voiceRemaining: Float;
  private let hud: ref<JTTRuntimeHud>;
  private let enabled: Bool;

  public static func Get() -> ref<JTTRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"JoNCTTNative.JTTRuntime") as JTTRuntime;
  }
  public static func Med() -> Vector4 = Vector4(-1334.58, 1744.64, 19.8, 1.0)
  public static func Roof() -> Vector4 = Vector4(-1352.0, 1790.0, 129.5, 1.0)
  public static func Scene() -> Vector4 = Vector4(-1474.382568, 2637.027832, 7.117821, 1.0)
  public static func Yaw() -> EulerAngles { let a: EulerAngles; a.Yaw = 0.0; return a; }

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) {
    this.enabled = false;
    this.Cleanup(false);
    this.state = 0;
    this.generation += 1;
    this.clock = EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance()));
    this.QueueTick();
  }
  private func OnPlayerDetach(request: ref<PlayerDetachRequest>) {
    this.generation += 1;
    GameInstance.GetDelaySystem(GetGameInstance()).CancelDelay(this.tickID);
    this.Cleanup(false);
    this.enabled = false;
  }
  // Opt-in prevents two JoNC versions from spawning a crew merely by loading a save.
  public func Enable() {
    if !JTTJournal.Get().IsReady() { this.message = "Native journal archive is missing."; return; }
    this.enabled = true;
    this.message = "Native rescue pilot — meet the officer at MedCenter";
    if this.state == 0 { JTTJournal.Get().Begin(false, JTTRuntime.Med()); this.SetState(1); }
  }
  public func Abort() {
    if !this.enabled { return; }
    if this.state == 13 || this.state == 14 { this.enabled = false; this.Cleanup(false); return; }
    this.Cleanup(true);
    this.SetState(14);
    this.message = "Rescue aborted. Returned to MedCenter. Press F8 to start again.";
  }
  private func SetState(next: Int32) {
    this.state = next;
    this.elapsed = 0.0;
  }
  private func QueueTick() {
    let cb = new JTTTick(); cb.generation = this.generation;
    this.tickID = GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(cb, 0.03, false);
  }
  public func Tick(token: Int32) {
    if token != this.generation { return; }
    let now = EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance()));
    let dt = ClampF(now - this.clock, 0.0, 0.1); this.clock = now;
    let player = GetPlayer(GetGameInstance());
    if IsDefined(player) && this.enabled {
      let menu = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_System).GetBool(GetAllBlackboardDefs().UI_System.IsInMenu);
      if !IsDefined(this.hud) { this.hud = new JTTRuntimeHud(); }
      this.hud.Attach();
      if !menu && dt > 0.0 { this.Step(dt, player); }
      if IsDefined(this.hud) { this.hud.Update(this, menu); }
    }
    this.QueueTick();
  }
  private func Spawn(record: TweakDBID, pos: Vector4) -> EntityID {
    let spec = new DynamicEntitySpec();
    spec.recordID = record; spec.position = pos; spec.orientation = EulerAngles.ToQuat(JTTRuntime.Yaw());
    spec.persistState = false; spec.persistSpawn = false; spec.alwaysSpawned = true;
    spec.spawnInView = true; spec.active = true; spec.tags = [n"JTTNative.Owned"];
    let id = GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
    ArrayPush(this.owned, id); return id;
  }
  private func Entity(id: EntityID) -> ref<GameObject> { return GameInstance.FindEntityByID(GetGameInstance(), id) as GameObject; }
  private func Move(id: EntityID, pos: Vector4) {
    let ent = this.Entity(id);
    if IsDefined(ent) { GameInstance.GetTeleportationFacility(GetGameInstance()).Teleport(ent, pos, JTTRuntime.Yaw()); }
  }
  private func Mount(id: EntityID, seat: CName) {
    let info: MountingInfo; info.parentId = this.av; info.childId = id; info.slotId.id = seat;
    let req = new MountingRequest(); req.lowLevelMountingInfo = info;
    req.mountData = new MountEventData(); req.mountData.isInstant = true;
    req.mountData.slotName = seat; req.mountData.mountParentEntityId = this.av;
    req.mountData.entryAnimName = n"forcedTransition";
    let options = new MountEventOptions(); options.alive = true; options.occupiedByNonFriendly = false;
    req.mountData.mountEventOptions = options;
    GameInstance.GetMountingFacility(GetGameInstance()).Mount(req);
    let npc = this.Entity(id) as NPCPuppet;
    if IsDefined(npc) {
      let cmd = new AIMountCommand(); cmd.mountData = req.mountData;
      npc.GetAIControllerComponent().SendCommand(cmd);
    }
  }
  private func Mounted(id: EntityID) -> Bool {
    let info = GameInstance.GetMountingFacility(GetGameInstance()).GetMountingInfoSingleWithObjects(this.Entity(id));
    return Equals(info.parentId, this.av);
  }
  private func Unmount(id: EntityID) {
    if !this.Mounted(id) { return; }
    let req = new UnmountingRequest(); req.lowLevelMountingInfo = GameInstance.GetMountingFacility(GetGameInstance()).GetMountingInfoSingleWithObjects(this.Entity(id));
    req.mountData = new MountEventData(); req.mountData.isInstant = true;
    GameInstance.GetMountingFacility(GetGameInstance()).Unmount(req);
  }
  private func StartRoof() {
    GameInstance.GetTeleportationFacility(GetGameInstance()).Teleport(GetPlayer(GetGameInstance()), JTTRuntime.Roof() + Vector4(0.0,-9.0,0.0,0.0), JTTRuntime.Yaw());
    this.av = this.Spawn(t"JoNCTTNative.AV", JTTRuntime.Roof() + Vector4(0.0,0.0,35.0,0.0));
    let i = 0;
    while i < 4 {
      ArrayPush(this.crew, this.Spawn(i == 3 ? t"Character.trauma_soldier_ranged2_dian_ma" : t"Character.trauma_soldier_shotgun2_zhuo_ma_rare", JTTRuntime.Roof() + Vector4(Cast<Float>(i) * 2.0 - 3.0,-5.0,0.0,0.0)));
      i += 1;
    }
    this.returning = false;
    this.patient = JTTPatient.Create("Araceli", "Cooley", "Gold", "Cerebral module infection; burned neurosensors.", JTTRuntime.Scene());
    JTTJournal.Get().Advance(2, JTTRuntime.Roof());
    this.SetState(2); this.message = "Awaiting the AV and crew";
  }
  private func CrewReady() -> Bool {
    if ArraySize(this.crew) != 4 || !IsDefined(this.Entity(this.av)) { return false; }
    for id in this.crew { if !IsDefined(this.Entity(id)) { return false; } }
    return true;
  }
  private func SeatCrew() {
    this.Mount(this.crew[0], n"trauma_pos1"); this.Mount(this.crew[1], n"trauma_pos3");
    this.Mount(this.crew[2], n"trauma_pos2"); this.Mount(this.crew[3], n"trauma_pos_sergent");
  }
  private func AllMounted() -> Bool {
    for id in this.crew { if !this.Mounted(id) { return false; } }
    if this.returning && !this.Mounted(this.victim) { return false; }
    return this.Mounted(GetPlayer(GetGameInstance()).GetEntityID());
  }
  private func Fly(from: Vector4, to: Vector4, duration: Float) {
    this.flightStart = from; this.flightEnd = to;
    this.flightElapsed = 0.0; this.flightDuration = duration;
  }
  private func FlightTick(dt: Float) -> Bool {
    this.flightElapsed += dt;
    let u = ClampF(this.flightElapsed / this.flightDuration, 0.0, 1.0);
    let ease = u * u * (3.0 - 2.0 * u);
    this.Move(this.av, this.flightStart + (this.flightEnd - this.flightStart) * ease);
    return u >= 1.0;
  }
  private func BeginFlight(back: Bool) {
    this.returning = back; this.flightPhase = 0;
    let p = this.Entity(this.av).GetWorldPosition();
    this.Fly(p, Vector4(p.X,p.Y,450.0,1.0), 16.0);
    this.SetState(6);
    if !back {
      this.Say(n"jttnative_traumateam_355");
      this.Say(n"jttnative_traumateam_medical hud");
      this.Say(n"jttnative_traumateam_no hostile");
    }
    this.message = back ? "Returning to MedCenter" : "En route to the policyholder";
    JTTJournal.Get().Advance(back ? 6 : 4, back ? JTTRuntime.Roof() : this.patient.location);
  }
  private func Arrive() {
    let pos = this.returning ? JTTRuntime.Roof() : this.patient.location + Vector4(-10.0,0.0,1.0,0.0);
    let player = GetPlayer(GetGameInstance());
    this.Unmount(player.GetEntityID());
    GameInstance.GetTeleportationFacility(GetGameInstance()).Teleport(player, pos + Vector4(0.0,-6.0,0.0,0.0), JTTRuntime.Yaw());
    let i = 0;
    while i < ArraySize(this.crew) {
      this.Unmount(this.crew[i]); this.Move(this.crew[i], pos + Vector4(Cast<Float>(i)*2.0-3.0,-4.0,0.0,0.0)); i += 1;
    }
    if this.returning {
      JTTJournal.Get().Advance(7, JTTRuntime.Roof()); this.Say(n"jttnative_traumateam_end v");
      this.SetState(12); this.message = "Debriefing — wait for the sergeant";
    } else {
      this.victim = this.Spawn(t"Character.LightCrowd_rancho_wa", this.patient.location);
      this.SetState(8); this.message = "Locating the patient";
    }
  }
  private func Step(dt: Float, player: ref<PlayerPuppet>) {
    this.elapsed += dt; this.TickVoice(dt);
    if this.state == 1 && this.Near(JTTRuntime.Med(), 6.0) { this.message = "[F1] Join the rooftop crew"; }
    if this.state == 2 {
      if this.CrewReady() {
        this.Fly(JTTRuntime.Roof()+Vector4(0.0,0.0,35.0,0.0),JTTRuntime.Roof(),10.0);
        this.SetState(3); this.Say(n"jttnative_traumateam_thanks joining"); this.message = "AV descending — stand clear";
      } else if this.elapsed > 20.0 { this.Fail("The AV or crew failed to spawn."); }
    } else if this.state == 3 && this.FlightTick(dt) {
      this.SeatCrew(); this.SetState(4); this.message = "[F1] Board the AV";
      JTTJournal.Get().Advance(3, JTTRuntime.Roof());
    } else if this.state == 5 {
      if this.AllMounted() { this.BeginFlight(this.returning); }
      else if this.elapsed > 15.0 { this.Fail("A seat could not be occupied."); }
    } else if this.state == 6 {
      if !IsDefined(this.Entity(this.av)) || !this.Mounted(player.GetEntityID()) { this.Fail("AV transport interrupted."); return; }
      if this.FlightTick(dt) {
        let dest = this.returning ? JTTRuntime.Roof() : this.patient.location + Vector4(-10.0,0.0,1.0,0.0);
        if this.flightPhase == 0 {
          this.flightPhase = 1; this.Fly(this.flightEnd,Vector4(dest.X,dest.Y,450.0,1.0),35.0);
        } else if this.flightPhase == 1 {
          this.flightPhase = 2; this.Fly(this.flightEnd,dest,22.0); this.Say(n"jttnative_traumateam_arrive soon");
        } else { this.Arrive(); }
      }
    } else if this.state == 8 {
      let npc = this.Entity(this.victim);
      if IsDefined(npc) {
        StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.Unconscious");
        JTTJournal.Get().Advance(5,this.patient.location); this.SetState(9);
      } else if this.elapsed > 20.0 { this.Fail("The patient failed to spawn."); }
    } else if this.state == 9 {
      if !IsDefined(this.Entity(this.victim)) { this.Fail("The patient is missing."); return; }
      if this.patient.IsTreating() {
        if !this.Near(this.patient.location,3.0) { this.patient.CancelTreatment(); }
        else { this.patient.TickTreatment(dt,this.treatmentRoll); }
      }
      this.message = this.patient.IsTreating() ? JTTContent.TreatmentLabel(this.treatmentIndex) + " — " + ToString(RoundF(this.patient.Progress()*100.0)) + "%" : "[F1] First aid    [F2] Firmware    [F3] Hotfix    [F4] Recovery";
      if !this.Near(this.patient.location,3.0) { this.message = "Approach the patient to begin treatment"; }
      if this.patient.IsDead() { this.Fail("Patient lost during treatment."); }
      else if this.patient.CanEvacuate() {
        this.Say(n"jttnative_traumateam_evacuate_f"); this.SetState(10);
        this.message = "Patient stabilized. [F1] Evacuate and board the AV";
        JTTJournal.Get().Advance(6,this.Entity(this.av).GetWorldPosition());
      }
    } else if this.state == 12 && ArraySize(this.voices) == 0 && this.voiceRemaining <= 0.0 {
      JTTJournal.Get().End(true); this.Cleanup(true); this.SetState(13);
      this.message = "Rescue complete. Press F8 to take another call.";
    }
  }
  public func Near(pos: Vector4, distance: Float) -> Bool {
    let player = GetPlayer(GetGameInstance());
    return IsDefined(player) && Vector4.Distance(player.GetWorldPosition(),pos) <= distance;
  }
  public func Action(index: Int32) {
    let bb = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_System);
    if bb.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu) { return; }
    if !this.enabled { return; }
    if index == 0 && this.state == 1 && this.Near(JTTRuntime.Med(),6.0) {
      let mounted = GameInstance.GetMountingFacility(GetGameInstance()).GetMountingInfoSingleWithObjects(GetPlayer(GetGameInstance()));
      if NotEquals(mounted.parentId,EntityID()) { this.message = "Exit your vehicle before joining the crew."; return; }
      this.StartRoof();
    }
    else if index == 0 && (this.state == 4 || this.state == 10) && IsDefined(this.Entity(this.av)) && this.Near(this.Entity(this.av).GetWorldPosition(),10.0) {
      this.returning = this.state == 10;
      if this.returning {
        StatusEffectHelper.RemoveStatusEffect(this.Entity(this.victim),t"BaseStatusEffect.Unconscious");
        this.Mount(this.victim,n"npc_injured");
      }
      this.SeatCrew(); this.Mount(GetPlayer(GetGameInstance()).GetEntityID(),n"player_seated");
      this.SetState(5); this.message = "Checking seats";
    } else if this.state == 9 && this.Near(this.patient.location,3.0) {
      if this.patient.BeginTreatment(index) {
        this.treatmentIndex = index;
        this.treatmentRoll = RandRange(JTTContent.TreatmentMinimum(index),JTTContent.TreatmentMaximum(index)+1);
      }
    }
  }
  public func Restart() {
    if this.state != 0 && this.state != 13 && this.state != 14 { return; }
    this.Cleanup(false); this.state = 0; this.Enable();
  }
  private func Fail(reason: String) {
    this.Cleanup(true); this.SetState(14); this.message = reason + " Returned to MedCenter. Press F8 to retry.";
  }
  private func Cleanup(returnPlayer: Bool) {
    let player = GetPlayer(GetGameInstance());
    if IsDefined(player) && ArraySize(this.owned)>0 {
      this.Unmount(player.GetEntityID());
      if returnPlayer { GameInstance.GetTeleportationFacility(GetGameInstance()).Teleport(player,JTTRuntime.Med(),JTTRuntime.Yaw()); }
    }
    if NotEquals(this.voice,n"") && IsDefined(player) { GameInstance.GetAudioSystemExt(GetGameInstance()).Stop(this.voice,player.GetEntityID(),n"JTTNative",null); }
    this.voice = n""; this.voiceRemaining = 0.0; ArrayClear(this.voices);
    if IsDefined(this.patient) { this.patient.CancelTreatment(); }
    for id in this.owned { this.Unmount(id); }
    for id in this.owned { GameInstance.GetDynamicEntitySystem().DeleteEntity(id); }
    ArrayClear(this.owned); ArrayClear(this.crew);
    this.av = EntityID(); this.victim = EntityID(); this.patient = null;
    if JTTJournal.Get().IsActive() { JTTJournal.Get().End(false); }
    if IsDefined(this.hud) { this.hud.Close(); this.hud = null; }
  }
  private func Say(line: CName) { ArrayPush(this.voices,line); }
  private func TickVoice(dt: Float) {
    this.voiceRemaining -= dt;
    if this.voiceRemaining <= 0.0 {
      this.voice = n"";
      if ArraySize(this.voices)>0 {
        this.voice = this.voices[0]; ArrayErase(this.voices,0);
        this.voiceRemaining = JTTVoiceContent.Duration(this.voice)+0.3;
        GameInstance.GetAudioSystemExt(GetGameInstance()).Play(this.voice,GetPlayer(GetGameInstance()).GetEntityID(),n"JTTNative",scnDialogLineType.Regular,null);
      }
    }
  }
  public func Subtitle() -> String = JTTVoiceContent.Subtitle(this.voice)
}

public class JTTTick extends DelayCallback {
  public let generation: Int32;
  public func Call() { JTTRuntime.Get().Tick(this.generation); }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result = wrappedMethod();
  this.RegisterInputListener(this,n"JTTNativeStart"); this.RegisterInputListener(this,n"JTTNativeAbort");
  this.RegisterInputListener(this,n"JTTNativeAction0"); this.RegisterInputListener(this,n"JTTNativeAction1");
  this.RegisterInputListener(this,n"JTTNativeAction2"); this.RegisterInputListener(this,n"JTTNativeAction3");
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  let result = wrappedMethod(action,consumer);
  if Equals(ListenerAction.GetType(action),gameinputActionType.BUTTON_PRESSED) {
    let key = ListenerAction.GetName(action);
    switch key {
      case n"JTTNativeStart": JTTRuntime.Get().Restart(); break;
      case n"JTTNativeAbort": JTTRuntime.Get().Abort(); break;
      case n"JTTNativeAction0": JTTRuntime.Get().Action(0); break;
      case n"JTTNativeAction1": JTTRuntime.Get().Action(1); break;
      case n"JTTNativeAction2": JTTRuntime.Get().Action(2); break;
      case n"JTTNativeAction3": JTTRuntime.Get().Action(3); break;
    }
  }
  return result;
}
