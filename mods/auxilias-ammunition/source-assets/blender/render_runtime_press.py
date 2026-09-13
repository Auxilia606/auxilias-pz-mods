"""Render four consistently framed transparent views of the tabletop press.

Run from the repository root with Blender 5.2::

    blender --background mods/auxilias-ammunition/source-assets/blender/AuxiliasAmmunitionPress.blend --python mods/auxilias-ammunition/source-assets/blender/render_runtime_press.py

The square renders and their common bed anchor are source art for
``tools/build-press-art.py``. The approved Blender model is never saved here.
"""

import json
import math
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector


HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parent / "tiles" / "renders"
OUTPUT.mkdir(parents=True, exist_ok=True)

RENDER_SIZE = 768
PRESS_COLLECTION = "AMMUNITION_PRESS__MODEL"
BED_OBJECT_NAME = "Solid weathered oak press bed"
BED_ANCHOR = Vector((-0.019, 0.002, 0.0025))
CAMERA_TARGET = Vector((BED_ANCHOR.x, BED_ANCHOR.y, 0.28))
# Rotate the model rather than orbiting the camera so each sprite shares its
# orthographic projection, game-view lighting, and screen-space position.
VIEWS = (("south", 0), ("east", -90), ("north", 180), ("west", 90))

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_x = RENDER_SIZE
scene.render.resolution_y = RENDER_SIZE
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.view_settings.exposure = 0.0

for name in ("STUDIO_PREVIEW_ONLY__NOT_PART_OF_PRESS", "DARK_REFERENCE_STAGE__NOT_PART_OF_PRESS"):
    bpy.data.collections[name].hide_render = True

# The concept .blend's directional studio lights and low exposure are useful
# for the hero image, but too dark and inconsistent for four game sprites.
for obj in bpy.data.objects:
    if obj.type == "LIGHT":
        obj.hide_render = True

if scene.world is None:
    scene.world = bpy.data.worlds.new("Neutral sprite ambience")
else:
    scene.world = scene.world.copy()
scene.world.use_nodes = True
background = scene.world.node_tree.nodes.get("Background")
background.inputs["Color"].default_value = (0.6, 0.6, 0.6, 1.0)
background.inputs["Strength"].default_value = 0.7


def add_area_light(name, location, energy, size):
    data = bpy.data.lights.new(name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (CAMERA_TARGET - obj.location).to_track_quat("-Z", "Y").to_euler()


add_area_light("Runtime neutral key", CAMERA_TARGET + Vector((-0.9, -0.9, 1.25)), 120, 1.1)
add_area_light("Runtime neutral fill", CAMERA_TARGET + Vector((1.0, 0.75, 0.95)), 70, 1.3)

camera = bpy.data.objects.new("Runtime isometric camera", bpy.data.cameras.new("Runtime isometric camera"))
scene.collection.objects.link(camera)
# A 30-degree elevation gives the ground plane Project Zomboid's 2:1 diamond.
# For x/y offsets of 0.9, z = 0.9 * sqrt(2 / 3).
camera.location = CAMERA_TARGET + Vector((0.9, -0.9, 0.9 * math.sqrt(2 / 3)))
camera.rotation_euler = (CAMERA_TARGET - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 1.12
scene.camera = camera
bpy.context.view_layer.update()

press_objects = tuple(obj for obj in bpy.data.collections[PRESS_COLLECTION].objects if obj.type == "MESH")
original_matrices = {obj: obj.matrix_world.copy() for obj in press_objects}
bed_object = bpy.data.objects.get(BED_OBJECT_NAME)
if bed_object is None or bed_object not in press_objects:
    raise RuntimeError(f"Missing press bed mesh: {BED_OBJECT_NAME}")
anchor_view = world_to_camera_view(scene, camera, BED_ANCHOR)
anchor_px = [round(anchor_view.x * RENDER_SIZE, 4), round((1.0 - anchor_view.y) * RENDER_SIZE, 4)]


def projected_bounds(obj):
    points = [world_to_camera_view(scene, camera, obj.matrix_world @ Vector(corner)) for corner in obj.bound_box]
    xs = [point.x * RENDER_SIZE for point in points]
    ys = [(1.0 - point.y) * RENDER_SIZE for point in points]
    return [round(min(xs), 4), round(min(ys), 4), round(max(xs), 4), round(max(ys), 4)]

metadata = {"render_size": [RENDER_SIZE, RENDER_SIZE], "faces": {}}
for direction, degrees in VIEWS:
    turn = (
        Matrix.Translation(BED_ANCHOR)
        @ Matrix.Rotation(math.radians(degrees), 4, "Z")
        @ Matrix.Translation(-BED_ANCHOR)
    )
    for obj, original in original_matrices.items():
        obj.matrix_world = turn @ original
    bpy.context.view_layer.update()

    scene.render.filepath = str(OUTPUT / f"press_{direction}.png")
    bpy.ops.render.render(write_still=True)
    metadata["faces"][direction] = {
        "anchor_px": anchor_px,
        "bed_bbox_px": projected_bounds(bed_object),
    }

(OUTPUT / "press_anchors.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
print(f"Rendered four press views with common anchor {anchor_px} to {OUTPUT}")
