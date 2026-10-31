"""Checks preservation, generated content and isolation; does not claim live gameplay QA."""
import hashlib
import json
from pathlib import Path
import unittest
import zipfile
ROOT=Path(__file__).resolve().parent

class BaselineTests(unittest.TestCase):
    def setUp(self):
        self.catalog=json.loads((ROOT/'data/catalog.json').read_text(encoding='utf-8'))

    def test_snapshot_is_byte_identical_to_patch_zip(self):
        with zipfile.ZipFile(ROOT/'original/JobsOfNightCity-TraumaTeam-Patched-v5.0.5.zip') as z:
            files=[x for x in z.infolist() if not x.is_dir()]
            self.assertEqual(len(files),119)
            for x in files: self.assertEqual(z.read(x),(ROOT/'original/patched-v5.0.5'/x.filename).read_bytes(),x.filename)

    def test_all_definitions_survive(self):
        p=ROOT/'original/patched-v5.0.5/bin/x64/plugins/cyber_engine_tweaks/mods/Jobs Of Night City - Trauma Team/scripts'
        self.assertEqual(len(self.catalog),44)
        for f in p.rglob('*.json'):
            self.assertEqual(json.loads(f.read_text(encoding='utf-8-sig')),self.catalog[f.relative_to(p).as_posix()])

    def test_treatment_context_overrides_are_not_lost(self):
        treatments=json.loads((ROOT/'data/treatments.json').read_text(encoding='utf-8'))
        # Literal operate_score fields are misleading: actual ranges live in context.
        self.assertEqual([(x['min_delta'],x['max_delta'],x['duration']) for x in treatments],[(5,10,1.5),(-2,15,4.5),(-5,20,2.5),(-10,30,2.5)])

    def test_no_objective_edge_is_dropped(self):
        objectives=self.catalog['mission/trauma_mission.json']['objectives']
        ids={o['tag'] for o in objectives}
        self.assertEqual(len(ids),12)
        for o in objectives:
            for target in o['unlock']: self.assertIn(target,ids)
        self.assertEqual(objectives[2]['unlock'],['trauma_mission_objective_3','trauma_mission_objective_9'])

    def test_all_widgets_have_distinct_native_ids(self):
        for cls,src,count in [('PatientCard','victim_membership_card_ui',26),('RecruitmentBoard','trauma_mission_ui',17)]:
            code=(ROOT/f'r6/scripts/JoNCTTNative/{cls}.reds').read_text(encoding='utf-8')
            self.assertEqual(len(self.catalog[f'interfaces/{src}.json']['controls']),count)
            self.assertEqual(code.count('ArrayPush(view.widgets,'),count)
            self.assertNotIn('SetScale(',code)

    def test_audio_is_complete_and_namespaced(self):
        folder=ROOT/'r6/audioware/JoNCTTNative'
        lines=(folder/'audios.yaml').read_text(encoding='utf-8').splitlines()[2:]
        self.assertEqual(len(lines),68)
        for line in lines:
            key,value=line.strip().split(': ',1)
            self.assertTrue(json.loads(key).startswith('jttnative_'))
            self.assertTrue((folder/json.loads(value)).is_file())
        for row in json.loads((ROOT/'data/audio-durations.json').read_text(encoding='utf-8')):
            self.assertEqual(hashlib.sha256((folder/Path(row['file']).name).read_bytes()).hexdigest(),row['sha256'])

    def test_archive_staging_has_only_namespaced_binaries(self):
        p=ROOT/'archive_src/packed/JoNCTTNative'
        files=[x for x in p.rglob('*') if x.is_file()]
        self.assertEqual(len(files),8)
        for x in files:
            self.assertEqual(x.relative_to(p).parts[0],'jttnative')
            self.assertIn(x.suffix,('.ent','.workspot'))

    def test_original_resource_references_are_remapped(self):
        mapping=json.loads((ROOT/'reports/resource-map.json').read_text())
        for p in (ROOT/'archive_src/JoNCTTNative').rglob('*.json'):
            raw=p.read_text(encoding='utf-8')
            for old in mapping: self.assertNotIn(json.dumps(old),raw)

if __name__=='__main__': unittest.main(verbosity=2)
