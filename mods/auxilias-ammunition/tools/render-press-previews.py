"""Refresh the press's saved inspection views without saving or rebuilding its source."""
from pathlib import Path
import hashlib,json
import bpy
from mathutils import Vector

MOD=Path(__file__).resolve().parents[1]
SOURCE=MOD/'source-assets/blender/AuxiliasAmmunitionPress.blend'
OUT=SOURCE.parent/'previews'
source_hash=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
studio=bpy.data.collections['STUDIO_PREVIEW_ONLY__NOT_PART_OF_PRESS']
stage=bpy.data.collections['DARK_REFERENCE_STAGE__NOT_PART_OF_PRESS']
for filename,camera,table,transparent,w,h in [
    ('AuxAmmoPress_hero','Centered-lever concept hero',False,False,1100,1200),
    ('AuxAmmoPress_tabletop','Tabletop scale preview',True,False,1200,900),
    ('AuxAmmoPress_south_transparent','South isometric - sprite source',False,True,900,900),
    ('AuxAmmoPress_east_transparent','East isometric - sprite source',False,True,900,900)]:
    studio.hide_render=not table;stage.hide_render=table or transparent
    scene.camera=bpy.data.objects[camera]
    scene.render.resolution_x=w;scene.render.resolution_y=h;scene.render.resolution_percentage=100
    scene.render.film_transparent=transparent;scene.cycles.samples=40
    scene.render.filepath=str(OUT/f'{filename}.png')
    bpy.ops.render.render(write_still=True)
image=bpy.data.images.load(str(OUT/'AuxAmmoPress_south_transparent.png'),check_existing=False)
image.scale(128,128);image.filepath_raw=str(OUT/'AuxAmmoPress_south_128px.png');image.save()
coll=bpy.data.collections['AMMUNITION_PRESS__MODEL']
points=[o.matrix_world@Vector(v) for o in coll.objects if o.type=='MESH' for v in o.bound_box]
lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
report={'asset':'Authored tabletop press','source_sha256':source_hash,'press_mesh_objects':len([o for o in coll.objects if o.type=='MESH']),
        'press_bounds_min':lo,'press_bounds_max':hi,'press_dimensions':[hi[i]-lo[i] for i in range(3)],
        'units':'metres','preview_worktop_in_prop_collection':False,'runtime_assets_written':False}
(OUT/'AuxAmmoPress_model_report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_hash
