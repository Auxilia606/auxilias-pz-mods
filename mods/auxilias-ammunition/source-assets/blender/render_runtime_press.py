"""Render four transparent views from the approved tabletop press model.

Run from the repository root with Blender 5.2::

    blender --background mods/auxilias-ammunition/source-assets/blender/AuxiliasAmmunitionPress.blend --python mods/auxilias-ammunition/source-assets/blender/render_runtime_press.py

The square, high-resolution renders are source art. ``tools/build-press-art.py``
fits them onto the game's 128 x 256 tile canvas.
"""

import math
from pathlib import Path

import bpy
from mathutils import Vector


HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parent / "tiles" / "renders"
OUTPUT.mkdir(parents=True, exist_ok=True)

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_x = 768
scene.render.resolution_y = 768
scene.render.resolution_percentage = 100

for name in ("STUDIO_PREVIEW_ONLY__NOT_PART_OF_PRESS", "DARK_REFERENCE_STAGE__NOT_PART_OF_PRESS"):
    bpy.data.collections[name].hide_render = True

target = Vector((0.08, -0.02, 0.28))
views = (
    ("south", (0.9, -0.9, 0.88)),
    ("east", (0.9, 0.9, 0.88)),
    ("north", (-0.9, 0.9, 0.88)),
    ("west", (-0.9, -0.9, 0.88)),
)

for direction, origin in views:
    camera = bpy.data.objects.new(f"Runtime {direction} camera", bpy.data.cameras.new(f"Runtime {direction}"))
    scene.collection.objects.link(camera)
    camera.location = origin
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 1.12
    scene.camera = camera
    scene.render.filepath = str(OUTPUT / f"press_{direction}.png")
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(camera, do_unlink=True)

print(f"Rendered press views to {OUTPUT}")
