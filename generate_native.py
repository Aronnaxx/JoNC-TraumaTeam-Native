"""Generate native ink UI and typed content from the preserved author's definitions."""
from pathlib import Path
import json
import math

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'r6/scripts/JoNCTTNative'
def q(s): return json.dumps(str(s), ensure_ascii=False)
def f(n): return f'{float(n):.6f}'
def write(name, text):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(text, encoding='utf-8')

def generate_ui(name, data):
    controls = data['controls']
    cls = 'JTT' + name
    lines = ['module JoNCTTNative', '', '// Generated from JoNC JSON; keep source indices because original tags repeat.', f'public class {cls} extends IScriptable {{', '  public let root: ref<inkCanvas>;', '  public let widgets: array<ref<inkWidget>>;', f'  public static func Create(parent: ref<inkCompoundWidget>) -> ref<{cls}> {{', f'    let view = new {cls}();', '    view.root = new inkCanvas();', f'    view.root.SetName(n"JTT_{name}");', '    view.root.SetSize(3840.0, 2160.0);', '    view.root.Reparent(parent);']
    parents = {}
    for i,c in enumerate(controls):
        typ = c['type']
        native = {'area':'inkCanvas','horizontal_area':'inkHorizontalPanel','vertical_area':'inkVerticalPanel','rectangle':'inkRectangle','label':'inkText','image':'inkImage','shape':'inkShape'}[typ]
        v = f'w{i}'
        lines += [f'    let {v} = new {native}();', f'    {v}.SetName(n"jtt_{i}_{c["tag"]}");']
        parent = parents.get(c.get('parent'), 'view.root')
        if typ == 'label':
            style = c.get('style') or {}
            lines += [f'    {v}.SetFontFamily("base\\\\gameplay\\\\gui\\\\fonts\\\\raj\\\\raj.inkfontfamily");', f'    {v}.SetFontStyle(n"Medium");', f'    {v}.SetFontSize({int(style.get("fontsize",30))});', f'    {v}.SetText({q(c.get("text",""))});']
        if typ == 'image':
            lines += [f'    {v}.SetAtlasResource(r{q(c["tweak"])});', f'    {v}.SetTexturePart(n{q(c["texture"])});']
        if typ == 'shape':
            lines += [f'    {v}.shapeVariant = IntEnum<inkEShapeVariant>({c.get("shapevariant",1)});', f'    {v}.lineThickness = {f(c.get("linethickness",1))};', f'    {v}.endCapStyle = IntEnum<inkEEndCapStyle>({c.get("endcapstyle",0)});']
            for pt in c.get('vertex',[]):
                lines.append(f'    ArrayPush({v}.vertexList, new Vector2({f(pt["x"])}, {f(pt["y"])}));')
        size,margin,color = c.get('size') or {},c.get('margin') or {},c.get('textcolor') or {}
        scale = c.get('scale') or {}
        size = dict(size, width=size.get('width',0)*scale.get('width',1), height=size.get('height',0)*scale.get('height',1))
        lines += [f'    {v}.SetSize({f(size.get("width",0))}, {f(size.get("height",0))});', f'    {v}.SetMargin(new inkMargin({f(margin.get("left",0))}, {f(margin.get("top",0))}, 0.0, 0.0));', f'    {v}.SetAnchor(IntEnum<inkEAnchor>({c.get("anchor",0)}));', f'    {v}.SetAnchorPoint(new Vector2(0.0, 0.0));', f'    {v}.SetFitToContent({str(c.get("fittocontent",False)).lower()});', f'    {v}.SetOpacity({f(c.get("opacity",1))});', f'    {v}.SetRotation({f(c.get("rotation",0))});', f'    {v}.SetTintColor(new HDRColor({f(color.get("red",255)/255)}, {f(color.get("green",255)/255)}, {f(color.get("blue",255)/255)}, 1.0));', f'    {v}.Reparent({parent});', f'    ArrayPush(view.widgets, {v});']
        if typ == 'shape': lines.append(f'    {v}.borderColor = {v}.GetTintColor();')
        if typ in ('area','horizontal_area','vertical_area'): parents.setdefault(c['tag'],v)
    lines += ['    return view;', '  }', '  public func Dispose() {', '    if IsDefined(this.root) && IsDefined(this.root.GetParentWidget()) { (this.root.GetParentWidget() as inkCompoundWidget).RemoveChild(this.root); }', '    ArrayClear(this.widgets);', '  }']
    if name == 'PatientCard':
        lines += ['  public func Refresh(patient: ref<JTTPatient>) {', '    if !IsDefined(patient) { return; }']
        for i,c in enumerate(controls):
            if c['type'] != 'label': continue
            contexts = c.get('context') or []
            for ctx in contexts:
                prop = ctx.get('prop',{}).get('text',{})
                if not prop: continue
                expr = q(prop.get('text',''))
                for token,source in prop.get('values',{}).items():
                    key = source.get('key','')
                    field = {'victim_name':'firstName','victim_familyname':'familyName','victim_member':'membership','victim_injury':'injury','victim_health':'health'}.get(key)
                    value = f'patient.{field}' if field else ('patient.location.X' if source.get('prop')=='x' else 'patient.location.Y')
                    if field=='health' or not field: value = f'ToString({value})'
                    expr = f'StrReplace({expr}, {q("##"+token)}, {value})'
                lines.append(f'    (this.widgets[{i}] as inkText).SetText({expr});')
        lines.append('  }')
    lines.append('}')
    write(name+'.reds','\n'.join(lines)+'\n')

def main():
    catalog = json.loads((ROOT/'data/catalog.json').read_text(encoding='utf-8'))
    for name,src in [('PatientCard','victim_membership_card_ui'),('RecruitmentBoard','trauma_mission_ui')]:
        generate_ui(name,catalog['interfaces/'+src+'.json'])
    mission=catalog['mission/trauma_mission.json']
    treatments=json.loads((ROOT/'data/treatments.json').read_text(encoding='utf-8'))
    lines=['module JoNCTTNative','','// Generated content. Native adapters do not execute raw CyberScript actions.', 'public class JTTContent extends IScriptable {','  public static func ObjectiveTitle(index: Int32) -> String {','    switch index {']
    for i,o in enumerate(mission['objectives']): lines += [f'      case {i}: return {q(o["title"])};']
    lines += ['    }','    return "";','  }']
    for method,field,typ in [('TreatmentLabel','label','String'),('TreatmentMinimum','min_delta','Int32'),('TreatmentMaximum','max_delta','Int32'),('TreatmentDuration','duration','Float')]:
        lines += [f'  public static func {method}(index: Int32) -> {typ} {{','    switch index {']
        for i,t in enumerate(treatments):
            value=q(t[field]) if typ=='String' else f(t[field]) if typ=='Float' else str(t[field])
            lines += [f'      case {i}: return {value};']
        lines += ['    }',f'    return {q("") if typ=="String" else "0.0" if typ=="Float" else "0"};','  }']
    lines += ['  public static func TreatmentPercent(index: Int32, elapsed: Float) -> Int32 {', '    switch index {']
    for i,t in enumerate(treatments):
        marks=[n for n in t['timeline'] if n['action'].get('name')=='change_hack_animation_percent']
        lines += [f'      case {i}:']
        for mark in reversed(marks): lines.append(f'        if elapsed >= {f(mark["at"])} {{ return {mark["action"]["value"]}; }}')
        lines.append('        return 0;')
    lines += ['    }','    return 0;','  }']
    lines += ['  public static func NextObjectives(index: Int32) -> array<Int32> {','    let result: array<Int32>;','    switch index {']
    lookup={o['tag']:i for i,o in enumerate(mission['objectives'])}
    for i,o in enumerate(mission['objectives']):
        lines.append(f'      case {i}:')
        for tag in o.get('unlock',[]): lines.append(f'        ArrayPush(result, {lookup[tag]});')
        lines.append('        break;')
    lines += ['    }','    return result;','  }','}']
    write('Content.reds','\n'.join(lines)+'\n')
    durations={Path(x['file']).stem:x['seconds'] for x in json.loads((ROOT/'data/audio-durations.json').read_text(encoding='utf-8'))}
    sounds=catalog['sound/Jobs Of Night City Trauma Team.json']
    lines=['module JoNCTTNative','','public class JTTVoiceContent extends IScriptable {']
    for method,typ in [('Subtitle','String'),('Duration','Float')]:
        lines += [f'  public static func {method}(tag: CName) -> {typ} {{','    switch tag {']
        for s in sounds:
            value=q(s['subtitle']) if typ=='String' else f(durations[s['tag']])
            lines.append(f'      case n{q("jttnative_"+s["tag"])}: return {value};')
        lines += ['    }',f'    return {q("") if typ=="String" else "0.0"};','  }']
    lines += ['}']
    write('VoiceContent.reds','\n'.join(lines)+'\n')
    print('Generated two ink views and typed mission/treatment content.')

if __name__=='__main__': main()
