"""Read the authored Blender source, export temporary copies, audit FBX, render previews.

blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/export-parts.py
Use -- --verify-only --no-render to audit the existing distribution without replacing it.
Never rebuild geometry or save the source .blend from this tool.
"""
import argparse
import hashlib
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.kdtree import KDTree

MOD = Path(__file__).resolve().parents[1]
ROOT = MOD.parents[1]
TARGET = json.loads((ROOT / 'config/project-zomboid.json').read_text())['target']
MEDIA = MOD / 'workshop/Contents/mods/AuxiliasAmmunition' / TARGET['releaseLine'] / 'media'
SOURCE = MOD / 'source-assets/blender/AuxiliasAmmunitionParts.blend'
ATLAS = MOD / 'source-assets/blender/textures/AuxAmmoPartsAtlas.png'
PREVIEWS = MOD / 'source-assets/blender/previews/parts'
WORK = MOD / 'work/parts-validation'
IDS = ('SmallPistolBody', 'HeavyPistolBody', 'RifleBody', 'ShotgunBody',
       'MineralSalts', 'CarbonPowder', 'NitrogenousMix', 'SurvivalPropellant')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(obj):
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    return (Vector([min(p[i] for p in points) for i in range(3)]),
            Vector([max(p[i] for p in points) for i in range(3)]))


def flatten(coll):
    dep = bpy.context.evaluated_depsgraph_get()
    verts, faces, uv_coords = [], [], []
    for obj in coll.all_objects:
        if obj.type != 'MESH':
            continue
        evaluated = obj.evaluated_get(dep)
        mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=dep)
        try:
            if len(mesh.uv_layers) != 1 or len(mesh.materials) != 1:
                raise RuntimeError(f'{obj.name}: expected one authored UV layer and atlas material')
            offset = len(verts)
            verts.extend(obj.matrix_world @ v.co for v in mesh.vertices)
            for p in mesh.polygons:
                faces.append([offset + i for i in p.vertices])
                uv_coords.extend(tuple(mesh.uv_layers.active.data[i].uv) for i in p.loop_indices)
        finally:
            evaluated.to_mesh_clear()
    mesh = bpy.data.meshes.new(coll.name + '_export')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    uv = mesh.uv_layers.new(name='UVMap')
    for loop, co in zip(uv.data, uv_coords):
        loop.uv = co
    mesh.materials.append(bpy.data.materials['Parts atlas - matte'])
    obj = bpy.data.objects.new(coll.name + '_export', mesh)
    bpy.context.scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new('Export triangulation', 'TRIANGULATE')
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def triangles(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    return [[tuple(obj.matrix_world @ mesh.vertices[vi].co) + tuple(mesh.uv_layers.active.data[li].uv)
             for vi, li in zip(t.vertices, t.loops)] for t in mesh.loop_triangles]


def compare(expected, actual):
    if len(expected) != len(actual):
        raise RuntimeError('FBX changed triangle count')
    tree = KDTree(len(actual))
    for i, tri in enumerate(actual):
        tree.insert(tuple(sum(c[a] for c in tri) / 3 for a in range(3)), i)
    tree.balance()
    used, maximum = set(), 0.0
    for tri in expected:
        center = tuple(sum(c[a] for c in tri) / 3 for a in range(3))
        match = None
        for _, index, _ in tree.find_range(center, 1e-6):
            if index in used:
                continue
            for offset in range(3):
                delta = max(abs(tri[i][a] - actual[index][(i + offset) % 3][a])
                            for i in range(3) for a in range(5))
                if delta <= 1e-6:
                    match = index
                    maximum = max(maximum, delta)
                    break
            if match is not None:
                break
        if match is None:
            raise RuntimeError('FBX changed position, winding or UV beyond 1e-6')
        used.add(match)
    return maximum


def audit(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    for t in mesh.loop_triangles:
        a, b, c = [mesh.uv_layers.active.data[i].uv for i in t.loops]
        if t.area < 1e-14 or abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)) < 2e-12:
            raise RuntimeError(f'{obj.name}: degenerate geometry or collapsed UV')
    lo, hi = bounds(obj)
    if abs(lo.z) > 1e-6 or min(hi-lo) < .003 or max(hi-lo) > .16:
        raise RuntimeError(f'{obj.name}: invalid ground plane or small-prop envelope')
    if 'Body_export' in obj.name and (hi.z > .025 or max(hi.x-lo.x,hi.y-lo.y) < 1.5*hi.z):
        raise RuntimeError(f'{obj.name}: loose body must lie across the ground, not stand upright')
    return {'triangles': len(mesh.loop_triangles), 'vertices': len(mesh.vertices),
            'bounds_min': list(lo), 'bounds_max': list(hi), 'dimensions': list(hi-lo),
            'degenerate_triangles': 0, 'collapsed_uv_triangles': 0}


def render(collections):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Medium High Contrast'
    scene.view_settings.exposure = .5
    scene.world = bpy.data.worlds.new('Parts inspection studio')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.65,.65,.65,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .8
    camera = bpy.data.objects.new('Parts inspection camera', bpy.data.cameras.new('Parts inspection camera'))
    scene.collection.objects.link(camera)
    camera.data.type = 'ORTHO'
    scene.camera = camera
    light = bpy.data.objects.new('Parts soft key', bpy.data.lights.new('Parts soft key', 'AREA'))
    scene.collection.objects.link(light)
    light.data.shape = 'DISK'
    for name, coll in collections.items():
        for other in collections.values():
            other.hide_render = other != coll
        points = [o.matrix_world @ v.co for o in coll.all_objects if o.type == 'MESH' for v in o.data.vertices]
        lo = Vector([min(p[i] for p in points) for i in range(3)])
        hi = Vector([max(p[i] for p in points) for i in range(3)])
        center, span = (lo+hi)/2, max(hi-lo)
        light.location = center + Vector((-.8,-1.0,1.5))*span
        light.rotation_euler = (center-light.location).to_track_quat('-Z','Y').to_euler()
        light.data.energy = 95*span*span
        light.data.size = span*1.8
        camera.data.ortho_scale = span*1.5
        for view, direction in [('iso',(.8,-1.1,1.35)),('top',(0,0,2)),('side',(.2,-2,.18))]:
            camera.location = center+Vector(direction)*span*2
            camera.rotation_euler = (center-camera.location).to_track_quat('-Z','Y').to_euler()
            scene.render.filepath = str(PREVIEWS/f'{name}_{view}.png')
            bpy.ops.render.render(write_still=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--no-render', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    WORK.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    source_hash = sha(SOURCE)
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    atlas = bpy.data.images['AuxAmmoPartsAtlas']
    if not atlas.packed_file or hashlib.sha256(atlas.packed_file.data).hexdigest() != sha(ATLAS):
        raise RuntimeError('Packed atlas and source PNG differ')
    collections = {name: bpy.data.collections['AuxAmmo'+name] for name in IDS}
    for coll in collections.values():
        coll.hide_viewport = False
    bpy.context.view_layer.update()
    report = {'target': TARGET, 'source_sha256': source_hash, 'atlas_sha256': sha(ATLAS), 'assets': {}}
    model_dir = MEDIA/'models_X/WorldItems'
    for name, coll in collections.items():
        obj = flatten(coll)
        row = audit(obj)
        # Same tested PZ basis as this repository's authored crossbow components.
        obj.rotation_euler.x = math.pi
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        path = (model_dir if args.verify_only else WORK)/f'AuxAmmo{name}.fbx'
        if not args.verify_only:
            bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, object_types={'MESH'},
                global_scale=1, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE',
                use_space_transform=True, bake_space_transform=False, axis_forward='-Y', axis_up='Z',
                add_leaf_bones=False, bake_anim=False, path_mode='STRIP')
        before = set(bpy.context.scene.objects)
        bpy.ops.wm.fbx_import(filepath=str(path))
        imported = set(bpy.context.scene.objects)-before
        if len(imported) != 1:
            raise RuntimeError(f'{name}: expected one FBX object')
        actual = next(iter(imported))
        if actual.type != 'MESH' or len(actual.data.materials) != 1 or len(actual.data.uv_layers) != 1:
            raise RuntimeError(f'{name}: FBX mesh/material/UV contract failed')
        row['fbx_max_coordinate_uv_delta'] = compare(triangles(obj), triangles(actual))
        row['fbx_geometry_uv_winding_match'] = True
        row['fbx_sha256'] = sha(path)
        row['materials'] = 1
        row['uv_layers'] = 1
        for temporary in [actual,obj]:
            bpy.data.objects.remove(temporary,do_unlink=True)
        report['assets'][name] = row
    tex_dir = MEDIA/'textures/WorldItems'
    if args.verify_only:
        if sha(tex_dir/ATLAS.name) != sha(ATLAS):
            raise RuntimeError('Runtime atlas differs from source')
    else:
        model_dir.mkdir(parents=True,exist_ok=True)
        tex_dir.mkdir(parents=True,exist_ok=True)
        for name in IDS:
            shutil.copyfile(WORK/f'AuxAmmo{name}.fbx', model_dir/f'AuxAmmo{name}.fbx')
        shutil.copyfile(ATLAS,tex_dir/ATLAS.name)
    if not args.no_render:
        render(collections)
    if sha(SOURCE) != source_hash:
        raise RuntimeError('Exporter modified the authored source')
    report['source_unchanged'] = True
    (WORK/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    if not args.verify_only:
        (SOURCE.parent/'parts-manifest.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('Validated eight authored parts, FBX round trips, atlas and source preservation.')


if __name__ == '__main__':
    main()
