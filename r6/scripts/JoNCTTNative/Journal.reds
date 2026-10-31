module JoNCTTNative
// Independent native journal bridge; shared engine API pattern, no On Call dependency.
public class JTTJournal extends ScriptableSystem {
    private let questId: String;
    private let objectiveIndex: Int32;
    private let markerPos: Vector4;
    private let placeAttempts: Int32;
    private let placeGeneration: Int32;

    public static func Get() -> ref<JTTJournal> {
        return GameInstance
            .GetScriptableSystemsContainer(GetGameInstance())
            .Get(n"JoNCTTNative.JTTJournal") as JTTJournal;
    }

    public static func MarkerRef() -> String = "$/jttnative/markers/objective"
    public static func ObjectiveCount() -> Int32 = 7

    private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
        // Calls don't survive a load: clear any of our quests a save left active
        this.questId = "";
        this.objectiveIndex = 0;
        GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(new JTTJournalResetCallback(), 3.0, false);
    }

    public func ResetAll() -> Void {
        if StrLen(this.questId) > 0 {
            return;
        }
        this.Deactivate("jttnative_mission");
    }

    public func IsReady() -> Bool {
        let jm = this.Journal();
        return IsDefined(jm) && IsDefined(jm.GetEntryByString(JTTJournal.QuestPath("jttnative_mission"), "gameJournalQuest"));
    }

    public func IsActive() -> Bool = StrLen(this.questId) > 0

    // Start a call at objective 1 with the marker on the scene
    public func Begin(unlisted: Bool, pos: Vector4) -> Bool {
        if !this.IsReady() {
            return false;
        }
        if StrLen(this.questId) > 0 {
            this.End(false);
        }
        this.questId = unlisted ? "jttnative_mission" : "jttnative_mission";
        this.objectiveIndex = 1;
        this.markerPos = pos;

        let jm = this.Journal();
        let path = JTTJournal.QuestPath(this.questId);
        this.Deactivate(this.questId);
        jm.ChangeEntryState(path, "gameJournalQuest", gameJournalEntryState.Active, JournalNotifyOption.Notify);
        jm.ChangeEntryState(path + "/description", "gameJournalQuestDescription", gameJournalEntryState.Active, JournalNotifyOption.DoNotNotify);
        jm.ChangeEntryState(path + "/phase", "gameJournalQuestPhase", gameJournalEntryState.Active, JournalNotifyOption.DoNotNotify);
        this.ActivateObjective();
        return true;
    }

    // Move to objective 2 (treat) or 3 (hand off) with the marker at pos
    public func Advance(index: Int32, pos: Vector4) -> Bool {
        if StrLen(this.questId) == 0 {
            return false;
        }
        let jm = this.Journal();
        if !IsDefined(jm) {
            return false;
        }
        if index != this.objectiveIndex {
            jm.ChangeEntryState(this.ObjectivePath(this.objectiveIndex), "gameJournalQuestObjective", gameJournalEntryState.Succeeded, JournalNotifyOption.DoNotNotify);
            this.objectiveIndex = index;
        }
        this.markerPos = pos;
        this.ActivateObjective();
        return true;
    }

    // Close the call: Succeeded on a hand-off, Failed on an abort
    public func End(success: Bool) -> Void {
        if StrLen(this.questId) == 0 {
            return;
        }
        let jm = this.Journal();
        let path = JTTJournal.QuestPath(this.questId);
        let state = success ? gameJournalEntryState.Succeeded : gameJournalEntryState.Failed;
        this.questId = "";
        this.placeGeneration += 1;
        if !IsDefined(jm) {
            return;
        }
        this.UntrackIfTracked(path);
        jm.ChangeEntryState(path + "/phase/objective_" + ToString(this.objectiveIndex), "gameJournalQuestObjective", state, JournalNotifyOption.DoNotNotify);
        jm.ChangeEntryState(path + "/phase", "gameJournalQuestPhase", state, JournalNotifyOption.DoNotNotify);
        jm.ChangeEntryState(path, "gameJournalQuest", state, JournalNotifyOption.Notify);
        jm.ChangeEntryState(path + "/description", "gameJournalQuestDescription", gameJournalEntryState.Inactive, JournalNotifyOption.DoNotNotify);
        this.objectiveIndex = 0;
    }

    private func ActivateObjective() -> Void {
        let jm = this.Journal();
        let objPath = this.ObjectivePath(this.objectiveIndex);
        jm.ChangeEntryState(objPath, "gameJournalQuestObjective", gameJournalEntryState.Active, JournalNotifyOption.Notify);
        jm.ChangeEntryState(objPath + "/mappin", "gameJournalQuestMapPin", gameJournalEntryState.Active, JournalNotifyOption.DoNotNotify);
        this.placeAttempts = 0;
        this.placeGeneration += 1;
        this.TryPlaceAndTrack(this.placeGeneration);
    }

    // The marker entity may still be streaming in: retry for ~10 s
    public func TryPlaceAndTrack(generation: Int32) -> Void {
        if generation != this.placeGeneration || StrLen(this.questId) == 0 {
            return;
        }
        let gi = GetGameInstance();
        let marker = GameInstance.FindEntityByID(gi, ToEntityID(CreateNodeRef(JTTJournal.MarkerRef()))) as GameObject;
        if !IsDefined(marker) {
            this.placeAttempts += 1;
            if this.placeAttempts < 20 {
                let cb = new JTTJournalPlaceCallback();
                cb.generation = generation;
                GameInstance.GetDelaySystem(gi).DelayCallback(cb, 0.5, false);
            }
            return;
        }
        GameInstance.GetTeleportationFacility(gi).Teleport(marker, this.markerPos, EulerAngles());
        let jm = this.Journal();
        let objective = jm.GetEntryByString(this.ObjectivePath(this.objectiveIndex), "gameJournalQuestObjective");
        if IsDefined(objective) {
            jm.TrackEntry(objective);
        }
    }

    private func Deactivate(id: String) -> Void {
        let jm = this.Journal();
        if !IsDefined(jm) {
            return;
        }
        let path = JTTJournal.QuestPath(id);
        let quest = jm.GetEntryByString(path, "gameJournalQuest");
        if !IsDefined(quest) {
            return;
        }
        this.UntrackIfTracked(path);
        let i = 1;
        while i <= JTTJournal.ObjectiveCount() {
            jm.ChangeEntryState(path + "/phase/objective_" + ToString(i), "gameJournalQuestObjective", gameJournalEntryState.Inactive, JournalNotifyOption.DoNotNotify);
            i += 1;
        }
        jm.ChangeEntryState(path + "/phase", "gameJournalQuestPhase", gameJournalEntryState.Inactive, JournalNotifyOption.DoNotNotify);
        jm.ChangeEntryState(path + "/description", "gameJournalQuestDescription", gameJournalEntryState.Inactive, JournalNotifyOption.DoNotNotify);
        jm.ChangeEntryState(path, "gameJournalQuest", gameJournalEntryState.Inactive, JournalNotifyOption.DoNotNotify);
    }

    private func UntrackIfTracked(questPath: String) -> Void {
        let jm = this.Journal();
        let quest = jm.GetEntryByString(questPath, "gameJournalQuest");
        if !IsDefined(quest) {
            return;
        }
        let questHash = jm.GetEntryHash(quest);
        let tracked = jm.GetTrackedEntry();
        let depth = 0;
        while IsDefined(tracked) && depth < 10 {
            if jm.GetEntryHash(tracked) == questHash {
                jm.UntrackEntry();
                return;
            }
            tracked = jm.GetParentEntry(tracked);
            depth += 1;
        }
    }

    private func Journal() -> ref<JournalManager> = GameInstance.GetJournalManager(GetGameInstance())

    public static func QuestPath(id: String) -> String = "quests/street_stories/" + id

    private func ObjectivePath(index: Int32) -> String = JTTJournal.QuestPath(this.questId) + "/phase/objective_" + ToString(index)
}

public class JTTJournalPlaceCallback extends DelayCallback {
    public let generation: Int32;

    public func Call() -> Void {
        let sys = JTTJournal.Get();
        if IsDefined(sys) {
            sys.TryPlaceAndTrack(this.generation);
        }
    }
}

public class JTTJournalResetCallback extends DelayCallback {
    public func Call() -> Void {
        let sys = JTTJournal.Get();
        if IsDefined(sys) {
            sys.ResetAll();
        }
    }
}
