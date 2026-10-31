"""Package only the new native developer baseline; never package the legacy runtime."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import zipfile
ROOT=Path(__file__).resolve().parent
VERSION='0.2.0'

def main():
    subprocess.run([sys.executable,str(ROOT/'generate_native.py')],check=True)
    subprocess.run([sys.executable,str(ROOT/'build_journal.py')],check=True)
    subprocess.run([sys.executable,str(ROOT/'test_baseline.py')],check=True)
    target=ROOT.parent/f'JoNC-TraumaTeam-Native-v{VERSION}.zip'
    files=sorted(p for name in ('r6','archive') for p in (ROOT/name).rglob('*') if p.is_file())
    assert len([p for p in files if p.suffix=='.archive'])==2
    manifest=[]
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
        for p in files:
            rel=p.relative_to(ROOT).as_posix()
            assert 'TraumaTeamOnCall' not in rel and not rel.startswith('bin/')
            z.write(p,rel)
            manifest.append({'path':rel,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    (ROOT/'reports/package-manifest.json').write_text(json.dumps({'version':VERSION,'developer_only':True,'mission_runtime':'single-scene pilot','playable_mission_verified':False,'files':manifest},indent=2),encoding='utf-8')
    print(f'{target}: {len(files)} files; native rescue pilot, awaiting live validation.')

if __name__=='__main__': main()
