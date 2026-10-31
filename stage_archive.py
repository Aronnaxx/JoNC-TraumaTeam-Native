from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parent
source=ROOT/'archive_src/JoNCTTNative'
target=ROOT/'archive_src/packed/JoNCTTNative'
files=[p for p in source.rglob('*') if p.suffix in ('.ent','.workspot')]
assert len(files)==8
for p in files:
    dst=target/p.relative_to(source)
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(p,dst)
print('Staged eight binary resources, without authoring JSON.')
