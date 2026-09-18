"""Run with Blender --background --factory-startup --python-exit-code 1 --python.

Adversarial checks against the authored source. Never saves or exports a mutation.
"""
import importlib.util
import json
import sys
from pathlib import Path

import bpy

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location('audit', Path(__file__).with_name('export_assets.py'))
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


def reopen():
    bpy.ops.wm.open_mainfile(filepath=str(audit.SOURCE))
    for coll in bpy.data.collections:
        coll.hide_viewport = False
    bpy.context.view_layer.update()
    return {name: bpy.data.collections[name] for name in audit.ASSET_NAMES}


def shift_ring(obj, ring, axis, delta):
    for index in json.loads(obj.data['mechanical_rings'])[ring]:
        obj.data.vertices[index].co[axis] += delta
    obj['mechanical_geometry_sha256'] = audit.geometry_fingerprint(obj.data)


def detached_string(collections):
    obj = audit.model_parts(collections[audit.TIERS[0]])['String']
    shift_ring(obj, 0, 2, .002)


def false_catch_metadata(collections):
    base = audit.TIERS[0]
    coll = collections[base + 'Cocked']
    obj = audit.model_parts(coll)['String']
    shift_ring(obj, 1, 1, -.004)
    for suffix in audit.STATES:
        collections[base + suffix]['catch_y'] -= .004


def stretched_limbs(collections):
    parts = audit.model_parts(collections[audit.TIERS[0]])
    shift_ring(parts['Limb_L'], 8, 0, -.015)
    shift_ring(parts['Limb_R'], 8, 0, .015)


def disconnected_bolt(collections):
    obj = audit.model_parts(collections[audit.TIERS[1] + 'Cocked'])['LoadedBolt_Shaft']
    obj.data = obj.data.copy()


source_hash = audit.sha256(audit.SOURCE)
baseline = reopen()
audit.validate_authoring(baseline)
audit.validate_bolt_family(baseline)
for mutation, expected in (
    (detached_string, 'invalid measured nock'),
    (false_catch_metadata, 'actual mesh fails string/limb length conservation'),
    (stretched_limbs, 'actual mesh fails string/limb length conservation'),
    (disconnected_bolt, 'loaded bolt must use the canonical mesh'),
):
    collections = reopen()
    mutation(collections)
    bpy.context.view_layer.update()
    try:
        audit.validate_authoring(collections)
    except RuntimeError as error:
        if expected not in str(error):
            raise AssertionError(f'{mutation.__name__}: unexpected failure: {error}') from error
        print(f'PASS: rejected {mutation.__name__}: {error}')
    else:
        raise AssertionError(f'{mutation.__name__}: invalid geometry was accepted')
assert audit.sha256(audit.SOURCE) == source_hash, 'Mutation tests changed the source file'
print('PASS: baseline and four adversarial checks; source unchanged.')
