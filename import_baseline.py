"""Repo-only, lossless JoNC snapshot and migration inventory. Never writes to the game."""
from pathlib import Path
import collections
import hashlib
import json
import shutil
import wave
import zipfile

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
MOD = Path('bin/x64/plugins/cyber_engine_tweaks/mods/Jobs Of Night City - Trauma Team')

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

def nodes(value, pointer=''):
    if isinstance(value, dict):
        yield pointer, value
        for key, child in value.items():
            yield from nodes(child, pointer + '/' + key.replace('~', '~0').replace('/', '~1'))
    elif isinstance(value, list):
        for i, child in enumerate(value):
            yield from nodes(child, pointer + '/' + str(i))

def main():
    originals = ROOT / 'original'
    originals.mkdir(exist_ok=True)
    inputs = [
        REPO / 'JobsOfNightCity-TraumaTeam-Patched-source/original/Jobs of Night City - Trauma Team-7427-5-0-0-1729059646.7z',
        REPO / 'JobsOfNightCity-TraumaTeam-Patched-v5.0.5.zip',
        REPO / 'CyberScript-Core-ArtheriaxFork-Patched-v5.1.9.6.zip',
        REPO / 'CyberScript-Core-GameArchive-v5.1.9.zip',
    ]
    for src in inputs:
        dst = originals / src.name
        if dst.exists():
            assert digest(dst) == digest(src), f'Snapshot changed: {src.name}'
        else:
            shutil.copyfile(src, dst)
    baseline = originals / 'patched-v5.0.5'
    with zipfile.ZipFile(originals / inputs[1].name) as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            dst = (baseline / info.filename).resolve()
            assert dst.is_relative_to(baseline.resolve())
            dst.parent.mkdir(parents=True, exist_ok=True)
            data = z.read(info)
            if dst.exists():
                assert dst.read_bytes() == data, f'Immutable snapshot changed: {dst}'
            else:
                dst.write_bytes(data)
    scripts = baseline / MOD / 'scripts'
    catalog, named, references = {}, collections.defaultdict(list), []
    for p in sorted(scripts.rglob('*.json')):
        rel = p.relative_to(scripts).as_posix()
        value = json.loads(p.read_text(encoding='utf-8-sig'))
        catalog[rel] = value
        for pointer, node in nodes(value):
            if isinstance(node.get('name'), str):
                named[node['name']].append({'file': rel, 'pointer': pointer})
            if node.get('name') == 'do_function':
                references.append({'file': rel, 'pointer': pointer, 'function': node.get('value')})
    write_json(ROOT / 'data/catalog.json', catalog)
    write_json(ROOT / 'reports/named-node-index.json', dict(sorted(named.items())))
    write_json(ROOT / 'reports/function-references.json', references)
    mission = catalog['mission/trauma_mission.json']
    write_json(ROOT / 'data/objectives.json', [{k: o.get(k) for k in ('tag', 'id', 'title', 'state', 'unlock', 'requirement', 'trigger', 'resume_action')} for o in mission['objectives']])
    treatments = []
    for option in catalog['choice/trauma_rescue.json']['options']:
        operation = next(a for a in option['action'] if a.get('name') == 'operate_score')
        limits = operation['context'][0]['prop']['value']['values']['value']
        elapsed, timeline = 0, []
        for action in option['action']:
            if action.get('name') == 'wait_second':
                elapsed += action['value']
            timeline.append({'at': elapsed, 'action': action})
        treatments.append({'label': option['description'], 'icon': option['icon'], 'min_delta': limits['min'], 'max_delta': limits['max'], 'duration': elapsed, 'timeline': timeline})
    write_json(ROOT / 'data/treatments.json', treatments)
    sounds = []
    for p in sorted((baseline / 'r6/audioware').rglob('*.wav')):
        with wave.open(str(p), 'rb') as w:
            sounds.append({'file': p.relative_to(baseline).as_posix(), 'seconds': w.getnframes()/w.getframerate(), 'sha256': digest(p)})
    write_json(ROOT / 'data/audio-durations.json', sounds)
    manifest = [{'path': p.relative_to(originals).as_posix(), 'bytes': p.stat().st_size, 'sha256': digest(p)} for p in sorted(originals.rglob('*')) if p.is_file()]
    write_json(ROOT / 'reports/provenance.json', {'date': '2026-10-31', 'permission': 'Ethan reports author permission to reuse systems in On Call; this is an isolated personal migration study.', 'files': manifest})
    summary = {'snapshot_files': len([p for p in baseline.rglob('*') if p.is_file()]), 'json_documents': len(catalog), 'objectives': len(mission['objectives']), 'named_node_kinds': len(named), 'named_nodes': sum(map(len, named.values())), 'voices': len(sounds), 'treatments': treatments and len(treatments), 'runtime_parity': False}
    write_json(ROOT / 'reports/import-summary.json', summary)
    print(json.dumps(summary))

if __name__ == '__main__':
    main()
