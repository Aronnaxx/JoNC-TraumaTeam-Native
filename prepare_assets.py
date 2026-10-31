"""Namespace locally extracted CR2W references and all JoNC voice registrations."""
from pathlib import Path
import json
import shutil
ROOT=Path(__file__).resolve().parent

def main():
    legacy=ROOT/'archive_src/legacy'
    files=sorted(legacy.rglob('*.json'))
    assert len(files)==8, 'Run filtered unbundle + convert serialize first; expect 8 resources'
    mapping={p.relative_to(legacy).as_posix()[:-5].replace('/','\\'): 'jttnative\\'+p.relative_to(legacy).as_posix()[:-5].replace('/','\\') for p in files}
    def rewrite(v):
        if isinstance(v,str): return mapping.get(v,v)
        if isinstance(v,list): return [rewrite(x) for x in v]
        if isinstance(v,dict): return {k:rewrite(x) for k,x in v.items()}
        return v
    for p in files:
        dst=ROOT/'archive_src/JoNCTTNative/jttnative'/p.relative_to(legacy)
        dst.parent.mkdir(parents=True,exist_ok=True)
        dst.write_text(json.dumps(rewrite(json.loads(p.read_text(encoding='utf-8-sig'))),indent=2),encoding='utf-8')
    (ROOT/'reports/resource-map.json').write_text(json.dumps(mapping,indent=2),encoding='utf-8')
    src=ROOT/'original/patched-v5.0.5/r6/audioware/Jobs Of Night City Trauma Team'
    dst=ROOT/'r6/audioware/JoNCTTNative'
    dst.mkdir(parents=True,exist_ok=True)
    lines=[]
    for line in (src/'audios.yaml').read_text(encoding='utf-8-sig').splitlines():
        if line.startswith('  ') and ': ' in line:
            key,value=line.strip().split(': ',1)
            lines.append('  '+json.dumps('jttnative_'+key)+': '+json.dumps(value))
        else: lines.append(line)
    (dst/'audios.yaml').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    for p in src.glob('*.wav'): shutil.copyfile(p,dst/p.name)
    tweak=ROOT/'r6/tweaks/JoNCTTNative/av.yaml'
    tweak.parent.mkdir(parents=True,exist_ok=True)
    tweak.write_text('JoNCTTNative.AV:\n  $base: Vehicle.q001_trauma_av\n  entityTemplatePath: jttnative\\base\\cyberscript\\trauma_av.ent\n',encoding='utf-8')
    print('Prepared 8 namespaced resources, 68 voices, and independent AV record.')

if __name__=='__main__': main()
