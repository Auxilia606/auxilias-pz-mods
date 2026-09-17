"""Export and audit the authored .blend; never generate or save source geometry.

Run from any directory with Blender:
    blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python <this file>
    blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python <this file> -- --verify-only
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

MOD_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = MOD_ROOT.parents[1]
GAME_TARGET = json.loads((REPO_ROOT / 'config/project-zomboid.json').read_text())['target']
VERSION_ROOT = MOD_ROOT / 'workshop/Contents/mods/AuxiliasCrossbow' / GAME_TARGET['releaseLine']
SOURCE = MOD_ROOT / 'source-assets/blender/AuxiliasCrossbowAssets.blend'
MODEL_TEXTURE_NAME = 'AuxiliaCrossbowAtlas'
MODEL_DIR = VERSION_ROOT / 'media/models_X/weapons/2handed'
TEXTURE_DIR = VERSION_ROOT / 'media/textures/weapons/2handed'
VALIDATION_DIR = MOD_ROOT / 'work/model-validation'
STAGING_DIR = VALIDATION_DIR / 'export-staging'
TIERS = ('AuxiliaImprovisedCrossbow', 'AuxiliaReinforcedCrossbow', 'AuxiliaHeavyArbalest')
STATES = ('', 'Cocked', 'CockedStoneBolt')
BOLTS = ('AuxiliaCrossbowBolt', 'AuxiliaStoneCrossbowBolt', 'AuxiliaBrokenBolt', 'AuxiliaBrokenStoneBolt')
COMPONENTS = ('AuxiliaBoltShaft', 'AuxiliaBoltHead', 'AuxiliaStoneBoltHead')
SMALL_ASSETS = BOLTS + COMPONENTS
ASSET_NAMES = tuple(base + state for base in TIERS for state in STATES) + SMALL_ASSETS


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def geometry_fingerprint(mesh):
    coordinates = [[round(c, 8) for c in v.co] for v in mesh.vertices]
    return hashlib.sha256(json.dumps(coordinates).encode()).hexdigest()


def bounds(objects):
    points = [obj.matrix_world @ v.co for obj in objects for v in obj.data.vertices]
    return (Vector([min(v[a] for v in points) for a in range(3)]),
            Vector([max(v[a] for v in points) for a in range(3)]))


def model_parts(collection):
    return {obj['part']: obj for obj in collection.all_objects if obj.type == 'MESH' and 'part' in obj}


def validate_authoring(collections):
    scene = bpy.context.scene
    if scene.get('authoring_schema') != 2:
        raise RuntimeError('Expected the editable Blender source, schema 2.')
    atlas = bpy.data.images.get(MODEL_TEXTURE_NAME)
    if not atlas or not atlas.packed_file or tuple(atlas.size) != (512, 512):
        raise RuntimeError('Source must carry its packed 512px atlas.')
    external_atlas = MOD_ROOT / 'source-assets/blender/textures/AuxiliaCrossbowAtlas.png'
    if hashlib.sha256(atlas.packed_file.data).hexdigest() != sha256(external_atlas):
        raise RuntimeError('Packed atlas differs from the authoring PNG; reload and repack the current bake.')
    depsgraph = bpy.context.evaluated_depsgraph_get()
    physics = json.loads(scene['mechanical_reference'])
    for base in TIERS:
        reference = model_parts(collections[base])
        for suffix in STATES:
            parts = model_parts(collections[base + suffix])
            for required in ('Tiller', 'BoltGroove_L', 'BoltGroove_R', 'Limb_L', 'Limb_R',
                             'String', 'StringNut', 'TriggerLink', 'TriggerLever', 'BridlePass', 'ForeEndRivet'):
                if required not in parts:
                    raise RuntimeError(f'{base + suffix}: missing editable part {required}')
            for role in ('Limb_L', 'Limb_R', 'String'):
                obj = parts[role]
                # The source retains the measured limb/string cages unchanged.
                # A future geometry edit must deliberately remeasure the mechanical
                # reference, rather than silently accepting stale custom properties.
                if geometry_fingerprint(obj.data) != obj.get('mechanical_geometry_sha256'):
                    raise RuntimeError(f'{obj.name}: remeasure the edited limb/string reference before export')
                if (obj.location.length > 1e-8 or max(abs(s - 1) for s in obj.scale) > 1e-8
                        or obj.rotation_euler.to_quaternion().angle > 1e-8 or len(obj.modifiers)):
                    raise RuntimeError(f'{obj.name}: mechanical reference transform changed')
            if suffix:
                for role, original in reference.items():
                    if role not in ('Limb_L', 'Limb_R', 'String'):
                        if parts[role].data != original.data:
                            raise RuntimeError(f'{base + suffix}: {role} no longer shares the common body mesh')
                        compare_triangles(triangle_data(original.evaluated_get(depsgraph)),
                                          triangle_data(parts[role].evaluated_get(depsgraph)))
                canonical_name = BOLTS[1 if 'Stone' in suffix else 0]
                canonical = model_parts(collections[canonical_name])
                loaded = []
                translations = []
                for role, original in canonical.items():
                    obj = parts['LoadedBolt_' + role]
                    if obj.data != original.data or len(obj.modifiers):
                        raise RuntimeError(f'{obj.name}: loaded bolt must use the canonical mesh')
                    if max(abs(s - 1) for s in obj.scale) > 1e-8 or obj.rotation_euler.to_quaternion().angle > 1e-8:
                        raise RuntimeError(f'{obj.name}: loaded bolt permits translation only')
                    translations.append(obj.location - original.location)
                    loaded.append(obj)
                if max((v - translations[0]).length for v in translations) > 1e-6:
                    raise RuntimeError(f'{base + suffix}: loaded bolt parts have inconsistent offsets')
                lo, hi = bounds(loaded)
                ref_lo, ref_hi = bounds(list(canonical.values()))
                dimension_delta = max(abs(v) for v in ((hi - lo) - (ref_hi - ref_lo)))
                if dimension_delta > 1e-6:
                    raise RuntimeError(f'{base + suffix}: loaded/world bolt dimensions differ')
                nock = parts['LoadedBolt_Nock']
                nock_lo, _ = bounds([nock])
                catch_y = float(collections[base + suffix]['catch_y'])
                radius = float(collections[base + suffix]['string_radius'])
                contact_gap = abs(nock_lo.y - catch_y - radius)
                axis_delta = abs(translations[0].z - float(collections[base + suffix]['power_axis_z']))
                overhang = hi.y - .262
                if contact_gap > 1e-6 or axis_delta > 1e-6 or not .027 <= overhang <= .033:
                    raise RuntimeError(f'{base + suffix}: bolt/string contact or point overhang changed')
                # Check the underside up to the fore-end, including edge crossings
                # where a point widens beyond the end of the stock. Vertices alone
                # miss a sloping head that cuts through the final bit of wood.
                _, tiller_hi = bounds([parts['Tiller']])
                _, groove_hi = bounds([parts['BoltGroove_L'], parts['BoltGroove_R']])
                supported_points = []
                for obj in loaded:
                    vertices = [obj.matrix_world @ v.co for v in obj.data.vertices]
                    supported_points.extend(v for v in vertices if v.y <= tiller_hi.y)
                    for edge in obj.data.edges:
                        a, b = (vertices[i] for i in edge.vertices)
                        if (a.y-tiller_hi.y)*(b.y-tiller_hi.y) < 0:
                            supported_points.append(a.lerp(b, (tiller_hi.y-a.y)/(b.y-a.y)))
                stock_clearance = min(v.z for v in supported_points) - tiller_hi.z
                vane_points = [obj.matrix_world @ v.co for obj in loaded
                               if obj['part'].startswith('LoadedBolt_Fletching_') for v in obj.data.vertices]
                # The narrow shaft/head binding sits between the lips; the three
                # wider vanes must also clear the slightly higher lip surface.
                channel_clearance = min(stock_clearance, min(v.z for v in vane_points)-groove_hi.z)
                if channel_clearance < .00015:
                    raise RuntimeError(f'{base + suffix}: bolt intersects or crowds the tiller groove')
                kind = 'stone' if 'Stone' in suffix else 'metal'
                physics[base][kind + '_bolt_channel_clearance'] = channel_clearance
                physics[base][kind + '_world_loaded_dimension_delta'] = dimension_delta
                physics[base][kind + '_loaded_point_overhang'] = overhang
                physics[base][kind + '_loaded_bolt_scale'] = 1.0
                physics[base]['string_nock_contact_gap'] = max(physics[base]['string_nock_contact_gap'], contact_gap)
                physics[base]['loaded_bolt_axis_offset'] = max(physics[base]['loaded_bolt_axis_offset'], axis_delta)
        if not (physics[base]['string_length_delta'] <= 1e-5
                and physics[base]['sampled_limb_length_delta'] <= .0002):
            raise RuntimeError(f'{base}: invalid preserved mechanical reference')
    return physics


def validate_bolt_family(collections):
    """Keep recovered heads and crafting parts faithful to the assembled bolt."""
    if bpy.context.scene.get('bolt_family_revision') != 1:
        raise RuntimeError('Expected the refined canonical bolt family.')
    links = {
        'AuxiliaBrokenBolt': ('AuxiliaCrossbowBolt', ('HeadSocket', 'BodkinPoint')),
        'AuxiliaBrokenStoneBolt': ('AuxiliaStoneCrossbowBolt', ('HeadBinding', 'ChippedPoint')),
        'AuxiliaBoltShaft': ('AuxiliaCrossbowBolt', ('Shaft',)),
        'AuxiliaBoltHead': ('AuxiliaCrossbowBolt', ('HeadSocket', 'BodkinPoint')),
        'AuxiliaStoneBoltHead': ('AuxiliaStoneCrossbowBolt', ('ChippedPoint',)),
    }
    report = {}
    for name, (source, roles) in links.items():
        parts = model_parts(collections[name])
        canonical = model_parts(collections[source])
        offsets = []
        expected = set(roles) | ({'Shaft'} if name in BOLTS else set())
        if set(parts) != expected:
            raise RuntimeError(f'{name}: unexpected component or leftover fracture proxy')
        for role in roles:
            obj, original = parts[role], canonical[role]
            if obj.data != original.data or len(obj.modifiers):
                raise RuntimeError(f'{name}: {role} must share its canonical mesh')
            if max(abs(s-1) for s in obj.scale) > 1e-8 or obj.rotation_euler.to_quaternion().angle > 1e-8:
                raise RuntimeError(f'{name}: component permits translation only')
            offsets.append(obj.location-original.location)
        if max((v-offsets[0]).length for v in offsets) > 1e-6:
            raise RuntimeError(f'{name}: component parts have inconsistent translations')
        lo, hi = bounds(list(parts.values()))
        if name in BOLTS:
            ref_lo, ref_hi = bounds(list(canonical.values()))
            ratio = (hi.y-lo.y)/(ref_hi.y-ref_lo.y)
            if not .55 < ratio < .70:
                raise RuntimeError(f'{name}: fracture should leave a short head-side fragment')
            shaft = parts['Shaft']
            if (shaft.location-offsets[0]).length > 1e-6 or len(shaft.modifiers):
                raise RuntimeError(f'{name}: fracture shaft detached from its canonical head')
            for a in (0, 2):
                shaft_lo, shaft_hi = bounds([shaft])
                ref_shaft_lo, ref_shaft_hi = bounds([canonical['Shaft']])
                if abs((shaft_hi[a]-shaft_lo[a])-(ref_shaft_hi[a]-ref_shaft_lo[a])) > 1e-6:
                    raise RuntimeError(f'{name}: broken shaft thickness differs from intact bolt')
        report[name] = {'canonical_asset': source, 'shared_parts': list(roles),
                        'translation_only': True, 'dimensions': list(hi-lo)}
    return report


def evaluated_copy(collection):
    """Flatten evaluated authoring parts into a temporary, single-material export."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    verts, faces, uvs = [], [], []
    for obj in collection.all_objects:
        if obj.type != 'MESH':
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=depsgraph)
        try:
            if len(mesh.uv_layers) != 1:
                raise RuntimeError(f'{obj.name}: expected exactly one UV layer')
            offset = len(verts)
            verts.extend(obj.matrix_world @ v.co for v in mesh.vertices)
            for p in mesh.polygons:
                faces.append([offset + i for i in p.vertices])
                uvs.extend(tuple(mesh.uv_layers.active.data[i].uv) for i in p.loop_indices)
        finally:
            evaluated.to_mesh_clear()
    mesh = bpy.data.meshes.new(collection.name + '_ExportMesh')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    uv = mesh.uv_layers.new(name='UVMap')
    for loop, co in zip(uv.data, uvs):
        loop.uv = co
    mesh.materials.append(bpy.data.materials['Game atlas - matte preview'])
    obj = bpy.data.objects.new(collection.name + '_GameExport', mesh)
    bpy.context.scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new('Game triangulation', 'TRIANGULATE')
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def mesh_audit(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    uv = mesh.uv_layers.active
    collapsed = 0
    for tri in mesh.loop_triangles:
        if tri.area < 1e-14:
            raise RuntimeError(f'{obj.name}: degenerate geometry triangle')
        a, b, c = [uv.data[i].uv for i in tri.loops]
        if abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)) < 2e-12:
            collapsed += 1
    if collapsed:
        raise RuntimeError(f'{obj.name}: {collapsed} collapsed UV triangles')
    lo, hi = bounds([obj])
    dimensions = hi - lo
    is_bolt = any(obj.name.startswith(n + '_') for n in SMALL_ASSETS)
    if not is_bolt and not (.22 < dimensions.x < .34 and .31 < dimensions.y < .355 and .04 < dimensions.z < .09):
        raise RuntimeError(f'{obj.name}: unexpected weapon envelope {tuple(dimensions)}')
    return {'single_mesh': True, 'vertices': len(mesh.vertices), 'triangles': len(mesh.loop_triangles),
            'materials': [m.name for m in mesh.materials], 'uv_layers': len(mesh.uv_layers),
            'collapsed_uv_triangles': collapsed, 'dimensions': list(dimensions),
            'bounds_min': list(lo), 'bounds_max': list(hi)}


def triangle_data(obj):
    mesh = obj.data
    mesh.calc_loop_triangles()
    triangles = []
    for tri in mesh.loop_triangles:
        corners = []
        for index, loop in zip(tri.vertices, tri.loops):
            co = obj.matrix_world @ mesh.vertices[index].co
            item = tuple(co) + tuple(mesh.uv_layers.active.data[loop].uv)
            corners.append(item)
        triangles.append(corners)
    return triangles


def compare_triangles(expected, actual):
    """Tolerant corner matching, retaining triangle winding and UV seams.

    Rounded coordinate hashes fail at decimal half-way boundaries even when the
    FBX differs by only a float32 ULP. Match triangle centroids then actual corners.
    """
    if len(expected) != len(actual):
        raise RuntimeError('FBX triangle count changed')
    tree = KDTree(len(actual))
    for i, tri in enumerate(actual):
        tree.insert(tuple(sum(c[a] for c in tri)/3 for a in range(3)), i)
    tree.balance()
    used = set()
    maximum_delta = 0.0
    for tri in expected:
        center = tuple(sum(c[a] for c in tri)/3 for a in range(3))
        match = None
        for _, index, _ in tree.find_range(center, 1e-6):
            if index in used:
                continue
            for offset in range(3):
                delta = max(abs(tri[i][a] - actual[index][(i+offset)%3][a])
                            for i in range(3) for a in range(5))
                if delta <= 1e-6:
                    match = index
                    maximum_delta = max(maximum_delta, delta)
                    break
            if match is not None:
                break
        if match is None:
            raise RuntimeError('FBX changed a triangle position, winding or UV by more than 1e-6')
        used.add(match)
    return maximum_delta


def export_object(game_obj, path):
    # Preserve the tested PZ basis, unit metadata and baked half-turn.
    game_obj.rotation_euler.x += math.pi
    bpy.context.view_layer.objects.active = game_obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True, object_types={'MESH'},
        global_scale=1.0, apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE',
        use_space_transform=True, bake_space_transform=False, axis_forward="-Y", axis_up="Z",
        add_leaf_bones=False, bake_anim=False, path_mode='STRIP')


def validate_fbx(game_obj, path):
    before = set(bpy.context.scene.objects)
    bpy.ops.wm.fbx_import(filepath=str(path))
    imported = [o for o in bpy.context.scene.objects if o not in before]
    try:
        meshes = [o for o in imported if o.type == 'MESH']
        if len(meshes) != 1 or len(imported) != 1:
            raise RuntimeError(f'{path.name}: expected exactly one FBX mesh')
        obj = meshes[0]
        if len(obj.data.materials) != 1 or len(obj.data.uv_layers) != 1:
            raise RuntimeError(f'{path.name}: FBX lost single-material / UV contract')
        maximum_delta = compare_triangles(triangle_data(game_obj), triangle_data(obj))
        lo, hi = bounds([obj])
        return {'fbx_round_trip_dimensions': list(hi-lo), 'fbx_uv_layers': 1,
                'fbx_materials': [m.name for m in obj.data.materials], 'fbx_geometry_and_uv_match': True,
                'fbx_maximum_coordinate_uv_delta': maximum_delta}
    finally:
        for obj in imported:
            mesh = obj.data if obj.type == 'MESH' else None
            bpy.data.objects.remove(obj, do_unlink=True)
            if mesh and mesh.users == 0:
                bpy.data.meshes.remove(mesh)


def render_validation(collections):
    scene = bpy.context.scene
    camera = scene.camera
    scene.render.resolution_x = 800
    scene.render.resolution_y = 600
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    views = {'iso': ((.82,-.84,.68), .51), 'top': ((0,.115,1.35), .50),
             'side': ((1.3,.115,.045), .44), 'front': ((0,1.35,.055), .40)}
    for name in ASSET_NAMES:
        for key, coll in collections.items():
            coll.hide_render = key != name
        coll = collections[name]
        is_bolt = name in SMALL_ASSETS
        for view, (position, scale) in views.items():
            if is_bolt and view != 'iso':
                continue
            lo, hi = bounds(list(model_parts(coll).values()))
            target = (lo+hi)/2 if is_bolt else Vector((0,.115,.012))
            camera.location = position
            camera.data.ortho_scale = max(.045, (hi-lo).length*1.45) if is_bolt else scale
            camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
            scene.render.filepath = str(VALIDATION_DIR / f'{name}_{view}.png')
            bpy.ops.render.render(write_still=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only', action='store_true', help='Audit installed exports against source without replacing assets')
    parser.add_argument('--no-render', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    VALIDATION_DIR.mkdir(parents=True, exist_ok=True)
    STAGING_DIR.mkdir(exist_ok=True)
    source_hash = sha256(SOURCE)
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    collections = {name: bpy.data.collections[name] for name in ASSET_NAMES}
    for coll in bpy.data.collections:
        coll.hide_viewport = False
    bpy.context.view_layer.update()
    report = {'authoring_schema': 2, 'source_sha256': source_hash, 'target': GAME_TARGET,
              'coordinate_system': 'X width, Y forward, Z up; action at origin', 'assets': {},
              'crossbow_physics': validate_authoring(collections),
              'bolt_family': validate_bolt_family(collections), 'runtime_client_test': 'not performed by exporter'}
    for name, coll in collections.items():
        obj = evaluated_copy(coll)
        try:
            row = mesh_audit(obj)
            target = MODEL_DIR / f'{name}.fbx' if args.verify_only else STAGING_DIR / f'{name}.fbx'
            if args.verify_only:
                obj.rotation_euler.x += math.pi
                bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
            else:
                export_object(obj, target)
            row.update(validate_fbx(obj, target))
            row['authoring_parts'] = len(model_parts(coll))
            row['fbx_sha256'] = sha256(target)
            report['assets'][name] = row
        finally:
            mesh = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            if mesh.users == 0:
                bpy.data.meshes.remove(mesh)
    atlas = bpy.data.images[MODEL_TEXTURE_NAME]
    atlas.filepath_raw = str(STAGING_DIR / f'{MODEL_TEXTURE_NAME}.png')
    atlas.file_format = 'PNG'
    atlas.save()
    report['atlas_sha256'] = sha256(atlas.filepath_raw)
    if args.verify_only:
        if sha256(TEXTURE_DIR / f'{MODEL_TEXTURE_NAME}.png') != report['atlas_sha256']:
            raise RuntimeError('Installed atlas differs from packed authoring pixels')
    else:
        for name in ASSET_NAMES:
            shutil.copyfile(STAGING_DIR / f'{name}.fbx', MODEL_DIR / f'{name}.fbx')
        shutil.copyfile(atlas.filepath_raw, TEXTURE_DIR / f'{MODEL_TEXTURE_NAME}.png')
    if not args.no_render:
        render_validation(collections)
    if sha256(SOURCE) != source_hash:
        raise RuntimeError('Export unexpectedly modified the authored .blend')
    report['source_unchanged_by_export'] = True
    (VALIDATION_DIR / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(f'PASS: {len(ASSET_NAMES)} authored assets; FBX geometry, UVs, materials and canonical bolt family verified; source unchanged.')


if __name__ == '__main__':
    main()
