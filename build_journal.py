"""Independent journal assets. Engine serialization pattern adapted from the local On Call builder; no runtime dependency."""
from pathlib import Path
import json, subprocess, shutil
ROOT=Path(__file__).resolve().parent
WK=r"C:\Users\wyant\Documents\WolvenKit.Console-9.0.1\WolvenKit.CLI.exe"
MARKER_REF="$/jttnative/markers/objective"
JOURNAL_PATH=r"jttnative\journal\mission.journal"
SECTOR_PATH=r"jttnative\sectors\markers.streamingsector"
BLOCK_PATH=r"jttnative\all.streamingblock"
LOC_PATH=r"jttnative\localization\en-us.json"
QUESTS=[("jttnative_mission","JTT-Title","JTT-Description")]
OBJECTIVES=["JTT-Obj-"+str(i) for i in range(1,8)]
TEXTS={"JTT-Title":"Jobs of Night City: Trauma Team — Native", "JTT-Description":"Join the Trauma Team crew, stabilize the policyholder and return to MedCenter."}
TEXTS.update(dict(zip(OBJECTIVES,["Meet the officer at MedCenter", "Attend the rooftop briefing", "Board the Trauma Team AV", "Fly to the patient", "Stabilize the patient", "Return to the AV and MedCenter", "Debrief with the sergeant"])))
def header(name):
    return {
        "WolvenKitVersion": "9.0.1",
        "WKitJsonVersion": "0.0.9",
        "GameVersion": 2310,
        "ExportedDateTime": "2026-10-29T00:00:00.0000000Z",
        "DataType": "CR2W",
        "ArchiveFileName": name,
    }


def cr2w(name, root):
    return {"Header": header(name), "Data": {"Version": 195, "BuildVersion": 0, "RootChunk": root, "EmbeddedFiles": []}}


def cname(v):
    return {"$type": "CName", "$storage": "string", "$value": v}


def noderef(v):
    if v:
        return {"$type": "NodeRef", "$storage": "string", "$value": v}
    return {"$type": "NodeRef", "$storage": "uint64", "$value": "0"}


def tdbid(v=None):
    if v:
        return {"$type": "TweakDBID", "$storage": "string", "$value": v}
    return {"$type": "TweakDBID", "$storage": "uint64", "$value": "0"}


def loc(key):
    return {"unk1": "0", "value": key}


def no_res(flags="Soft"):
    return {"DepotPath": {"$type": "ResourcePath", "$storage": "uint64", "$value": "0"}, "Flags": flags}


class Handles:
    def __init__(self):
        self.n = 0

    def wrap(self, data):
        h = {"HandleId": str(self.n), "Data": data}
        self.n += 1
        return h


def journal():
    H = Handles()
    # Handles are numbered in creation order; parents are created first
    root = {"$type": "gameJournalRootFolderEntry", "descriptor": no_res(), "id": "", "journalEntryOverrideDataList": [], "entries": []}
    root_h = H.wrap(root)
    prim = {"$type": "gameJournalPrimaryFolderEntry", "id": "quests", "journalEntryOverrideDataList": [], "entries": []}
    root["entries"].append(H.wrap(prim))
    folder = {"$type": "gameJournalFolderEntry", "id": "street_stories", "journalEntryOverrideDataList": [], "entries": []}
    prim["entries"].append(H.wrap(folder))
    for qid, title, desc in QUESTS:
        quest = {
            "$type": "gameJournalQuest", "districtID": "", "entries": [], "id": qid,
            "journalEntryOverrideDataList": [], "recommendedLevelID": tdbid(), "title": loc(title), "type": "StreetStory",
        }
        folder["entries"].append(H.wrap(quest))
        quest["entries"].append(H.wrap({"$type": "gameJournalQuestDescription", "description": loc(desc), "id": "description", "journalEntryOverrideDataList": []}))
        phase = {"$type": "gameJournalQuestPhase", "entries": [], "id": "phase", "journalEntryOverrideDataList": [], "locationPrefabRef": noderef(None)}
        quest["entries"].append(H.wrap(phase))
        for i, obj_key in enumerate(OBJECTIVES, start=1):
            obj = {
                "$type": "gameJournalQuestObjective", "counter": 0, "description": loc(obj_key), "districtID": "", "entries": [],
                "id": f"objective_{i}", "itemID": tdbid(), "journalEntryOverrideDataList": [], "locationPrefabRef": noderef(None), "optional": 0,
            }
            phase["entries"].append(H.wrap(obj))
            obj["entries"].append(H.wrap({
                "$type": "gameJournalQuestMapPin", "enableGPS": 1, "entries": [], "id": "mappin", "journalEntryOverrideDataList": [],
                "mappinData": {
                    "$type": "gamemappinsMappinData", "active": 1, "debugCaption": "", "localizedCaption": loc(""),
                    "mappinType": tdbid("Mappins.QuestEntityMappinDefinition"), "scriptData": None,
                    "variant": "ExclamationMarkVariant", "visibleThroughWalls": 1,
                },
                "offset": {"$type": "Vector3", "X": 0, "Y": 0, "Z": 0.5},
                "reference": {
                    "$type": "gameEntityReference", "dynamicEntityUniqueName": cname("None"), "names": [],
                    "reference": noderef(MARKER_REF), "sceneActorContextName": cname("None"), "slotName": cname("None"), "type": "EntityRef",
                },
                "slotName": cname("UI_Interaction"),
                "uiAnimation": tdbid(),
            }))
    return cr2w(JOURNAL_PATH, {"$type": "gameJournalResource", "cookingPlatform": "PLATFORM_None", "entry": root_h})


def vec4(x, y, z, w=0):
    return {"$type": "Vector4", "W": w, "X": x, "Y": y, "Z": z}


def sector():
    x, y, z = 100, 100, 0
    node_data = [{
        "Id": "0", "NodeIndex": 0, "Position": vec4(x, y, z),
        "Orientation": {"$type": "Quaternion", "i": 0, "j": 0, "k": 0, "r": 1},
        "Scale": {"$type": "Vector3", "X": 1, "Y": 1, "Z": 1},
        "Pivot": {"$type": "Vector3", "X": x, "Y": y, "Z": z},
        "Bounds": {"$type": "Box", "Max": vec4(x, y, z), "Min": vec4(x, y, z)},
        "QuestPrefabRefHash": noderef(MARKER_REF), "UkHash1": noderef(None),
        "CookedPrefabData": no_res("Default"),
        "MaxStreamingDistance": 2.8924e38, "UkFloat1": 3.40282347e38,
        "Uk10": 1056, "Uk11": 512, "Uk12": 0, "Uk13": "0", "Uk14": "0",
    }]
    node = {"HandleId": "0", "Data": {
        "$type": "worldEntityNode", "appearanceName": cname("default"), "debugName": cname("[Entity Template] jttnative_objective_marker"),
        "entityLod": 0,
        "entityTemplate": {"DepotPath": {"$type": "ResourcePath", "$storage": "string", "$value": "base\\gameplay\\devices\\empty_visible_object.ent"}, "Flags": "Soft"},
        "instanceData": None, "ioPriority": "Immediate", "isHostOnly": 0, "isVisibleInGame": 1, "proxyScale": None,
        "sourcePrefabHash": "0", "tag": "None", "tagExt": "None",
    }}
    root = {
        "$type": "worldStreamingSector", "category": "Exterior", "cookingPlatform": "PLATFORM_None",
        "externInplaceResource": no_res(), "level": 1, "localInplaceResource": [],
        "nodeData": {"BufferId": "0", "Flags": 0,
                     "Type": "WolvenKit.RED4.Archive.Buffer.worldNodeDataBuffer, WolvenKit.RED4, Version=9.0.1.0, Culture=neutral, PublicKeyToken=null",
                     "Data": node_data},
        "nodeRefs": [noderef(MARKER_REF)], "nodes": [node],
        "persistentNodeIndex": 0, "persistentNodes": [], "variantIndices": [0], "variantNodes": [], "version": 62,
    }
    return cr2w(SECTOR_PATH, root)


def block():
    big = 3.40282347e38
    root = {
        "$type": "worldStreamingBlock", "cookingPlatform": "PLATFORM_None",
        "descriptors": [{
            "$type": "worldStreamingSectorDescriptor",
            "blockIndex": {"$type": "worldStreamingBlockIndex", "oup": "Base", "rldGridCell": 0},
            "category": "Exterior",
            "data": {"DepotPath": {"$type": "ResourcePath", "$storage": "string", "$value": SECTOR_PATH}, "Flags": "Soft"},
            "level": 1, "numNodeRanges": 1, "questPrefabNodeRef": noderef(None),
            "streamingBox": {"$type": "Box", "Max": vec4(big, big, big, -big), "Min": vec4(-big, -big, -big, big)},
            "variants": [],
        }],
        "index": {"$type": "worldStreamingBlockIndex", "oup": "Base", "rldGridCell": 0},
    }
    return cr2w(BLOCK_PATH, root)


def localization():
    entries = [{"$type": "localizationPersistenceOnScreenEntry", "femaleVariant": text, "maleVariant": "",
                "primaryKey": "0", "secondaryKey": key} for key, text in TEXTS.items()]
    root = {"$type": "JsonResource", "cookingPlatform": "PLATFORM_None",
            "root": {"HandleId": "0", "Data": {"$type": "localizationPersistenceOnScreenEntries", "entries": entries}}}
    return cr2w(LOC_PATH, root)



def main():
    work=ROOT/'archive_src/journal'
    author=work/'authoring'
    packed=work/'JTTNativeJournal'
    resources=[(JOURNAL_PATH,journal()),(SECTOR_PATH,sector()),(BLOCK_PATH,block()),(LOC_PATH,localization())]
    for name,data in resources:
        p=author/(name+'.json'); p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(json.dumps(data,indent=1),encoding='utf8')
        result=subprocess.run([WK,'convert','deserialize',str(p)],check=True,capture_output=True,text=True)
        if 'Error' in result.stdout or 'Error' in result.stderr:
            raise RuntimeError(result.stdout+result.stderr)
    for name,_ in resources:
        src=author/name; dst=packed/name; dst.parent.mkdir(parents=True,exist_ok=True)
        if src.read_bytes()[:4]!=b'CR2W': raise RuntimeError('Invalid resource '+name)
        shutil.copyfile(src,dst)
    subprocess.run([WK,'pack','-p',str(packed),'-o',str(work)],check=True)
    out=ROOT/'archive/pc/mod'; out.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(work/'JTTNativeJournal.archive',out/'JTTNativeJournal.archive')
    (out/'JTTNativeJournal.archive.xl').write_text('journal:\n  - '+JOURNAL_PATH+'\nstreaming:\n  blocks:\n    - '+BLOCK_PATH+'\nlocalization:\n  onscreens:\n    en-us: '+LOC_PATH+'\n',encoding='utf8')
if __name__=='__main__': main()
