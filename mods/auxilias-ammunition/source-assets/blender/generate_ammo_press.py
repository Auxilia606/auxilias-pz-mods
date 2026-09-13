"""Generate an editable tabletop ammunition-press concept and isometric previews.

Run with Blender 5.2:
    blender --background --python source-assets/blender/generate_ammo_press.py

This is a model-first source asset. It deliberately writes nothing into workshop/.
The studio stage and wooden worktop are preview props, never part of the press.
"""

import bpy
import json
import math
import os
from mathutils import Vector


HERE = os.path.dirname(os.path.abspath(__file__))
PREVIEWS = os.path.join(HERE, "previews")
os.makedirs(PREVIEWS, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)


def collection(name):
    result = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(result)
    return result


def put(obj, group):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    group.objects.link(obj)
    return obj


def material(name, color, metallic, roughness, grain=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if grain:
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = grain
        noise.inputs["Detail"].default_value = 3
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].position = 0.18
        ramp.color_ramp.elements[0].color = (*tuple(c * 0.58 for c in color), 1)
        ramp.color_ramp.elements[1].position = 0.82
        ramp.color_ramp.elements[1].color = (*tuple(min(1, c * 1.34) for c in color), 1)
        links = mat.node_tree.links
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], principled.inputs["Base Color"])
    return mat


def timber(name, dark_color, light_color, grain_axis):
    """Low-contrast lengthwise grain for wood stained like dark mahogany furniture."""
    mat = material(name, light_color, 0.0, 0.87)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    coords = nodes.new("ShaderNodeTexCoord")
    stretch = nodes.new("ShaderNodeVectorMath")
    stretch.operation = "MULTIPLY"
    stretch.inputs[1].default_value = tuple(1.5 if i == grain_axis else 12.0 for i in range(3))
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.0
    noise.inputs["Detail"].default_value = 4.0
    noise.inputs["Roughness"].default_value = 0.70
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.28
    ramp.color_ramp.elements[0].color = (*dark_color, 1)
    ramp.color_ramp.elements[1].position = 0.72
    ramp.color_ramp.elements[1].color = (*light_color, 1)
    middle = ramp.color_ramp.elements.new(0.51)
    middle.color = (*tuple((dark_color[i] + light_color[i]) * 0.50 for i in range(3)), 1)
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.12
    bump.inputs["Distance"].default_value = 0.00045
    stains = nodes.new("ShaderNodeTexNoise")
    stains.inputs["Scale"].default_value = 6.0
    stains.inputs["Detail"].default_value = 3.0
    stain_range = nodes.new("ShaderNodeValToRGB")
    stain_range.color_ramp.elements[0].position = 0.32
    stain_range.color_ramp.elements[0].color = (0.80, 0.77, 0.73, 1)
    stain_range.color_ramp.elements[1].position = 0.67
    stain_range.color_ramp.elements[1].color = (1, 1, 1, 1)
    stained_color = nodes.new("ShaderNodeMixRGB")
    stained_color.blend_type = "MULTIPLY"
    stained_color.inputs[0].default_value = 0.22
    links.new(coords.outputs["Generated"], stretch.inputs[0])
    links.new(stretch.outputs["Vector"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(coords.outputs["Generated"], stains.inputs["Vector"])
    links.new(stains.outputs["Fac"], stain_range.inputs["Fac"])
    links.new(ramp.outputs["Color"], stained_color.inputs[1])
    links.new(stain_range.outputs["Color"], stained_color.inputs[2])
    links.new(stained_color.outputs["Color"], nodes.get("Principled BSDF").inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], nodes.get("Principled BSDF").inputs["Normal"])
    return mat


def bevel(obj, width, segments=2):
    mod = obj.modifiers.new("Soft machined edges", "BEVEL")
    mod.width = width
    mod.segments = segments
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def cube(name, loc, size, mat, group, edge=0.002):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if edge:
        bevel(obj, edge)
    return put(obj, group)


def cylinder(name, loc, radius, depth, mat, group, vertices=24, edge=0.0015, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    if rotation is not None:
        obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    if edge:
        bevel(obj, edge)
    return put(obj, group)


def rod(name, start, end, radius, mat, group, vertices=16):
    a, b = Vector(start), Vector(end)
    center = (a + b) / 2
    direction = b - a
    obj = cylinder(name, center, radius, direction.length, mat, group, vertices, edge=min(radius * 0.13, 0.0015))
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


def square_beam(name, start, end, width, depth, mat, group):
    a, b = Vector(start), Vector(end)
    obj = cube(name, (a + b) / 2, (width, depth, (b - a).length),
               mat, group, edge=0.003)
    obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    return obj


def profile_prism(name, outline, front_y, rear_y, mat, group, edge=0.003):
    """Extrude an X/Z silhouette into a solid forged frame."""
    count = len(outline)
    vertices = [(x, front_y, z) for x, z in outline]
    vertices += [(x, rear_y, z) for x, z in outline]
    faces = [tuple(reversed(range(count))), tuple(range(count, 2 * count))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count)
              for i in range(count)]
    mesh = bpy.data.meshes.new(name + " mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    group.objects.link(obj)
    obj.data.materials.append(mat)
    bevel(obj, edge, segments=3)
    return obj


def forge_surface(mat, dark_color, light_color, scale=160):
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    patina = nodes.new("ShaderNodeTexNoise")
    patina.inputs["Scale"].default_value = 9
    patina.inputs["Detail"].default_value = 4
    patina.inputs["Roughness"].default_value = 0.72
    colors = nodes.new("ShaderNodeValToRGB")
    colors.color_ramp.elements[0].position = 0.23
    colors.color_ramp.elements[0].color = (*dark_color, 1)
    colors.color_ramp.elements[1].position = 0.76
    colors.color_ramp.elements[1].color = (*light_color, 1)
    links.new(patina.outputs["Fac"], colors.inputs["Fac"])
    links.new(colors.outputs["Color"], nodes.get("Principled BSDF").inputs["Base Color"])
    roughness = nodes.new("ShaderNodeMapRange")
    roughness.inputs["To Min"].default_value = 0.56
    roughness.inputs["To Max"].default_value = 0.82
    links.new(patina.outputs["Fac"], roughness.inputs["Value"])
    links.new(roughness.outputs["Result"], nodes.get("Principled BSDF").inputs["Roughness"])
    pits = nodes.new("ShaderNodeTexNoise")
    pits.inputs["Scale"].default_value = scale
    pits.inputs["Detail"].default_value = 2
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.40
    bump.inputs["Distance"].default_value = 0.003
    links.new(pits.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], nodes.get("Principled BSDF").inputs["Normal"])


def torus(name, loc, major, minor, mat, group, rotation=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                     major_segments=32, minor_segments=8, location=loc)
    obj = bpy.context.object
    obj.name = name
    if rotation:
        obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    return put(obj, group)


def uv_sphere(name, loc, scale, mat, group):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    return put(obj, group)


def bolt(name, x, y, z, mat, group):
    cylinder(f"{name} head", (x, y, z), 0.006, 0.003, mat, group, vertices=12, edge=0.0004)
    cube(f"{name} slot", (x, y, z + 0.00165), (0.0065, 0.00085, 0.0004), dark, group, 0)


def face_rivet(name, x, y, z, mat, group):
    cylinder(name, (x, y, z), 0.0055, 0.0035, mat, group, vertices=12,
             edge=0.0005, rotation=(math.pi / 2, 0, 0))


def look_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def camera(name, loc, target, ortho):
    bpy.ops.object.camera_add(location=loc)
    result = bpy.context.object
    result.name = name
    result.data.type = "ORTHO"
    result.data.ortho_scale = ortho
    look_at(result, target)
    return result


def area_light(name, loc, energy, size, target):
    bpy.ops.object.light_add(type="AREA", location=loc)
    light = bpy.context.object
    light.name = name
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    look_at(light, target)
    return light


def world_bounds(objects):
    points = []
    for obj in objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ Vector(corner))
    lo = [min(point[i] for point in points) for i in range(3)]
    hi = [max(point[i] for point in points) for i in range(3)]
    return lo, hi


def render(path, cam, transparent, width, height, samples):
    scene.camera = cam
    scene.render.film_transparent = transparent
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.cycles.samples = samples
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print(f"RENDERED {path}")


clear_scene()
press = collection("AMMUNITION_PRESS__MODEL")
studio = collection("STUDIO_PREVIEW_ONLY__NOT_PART_OF_PRESS")
concept_stage = collection("DARK_REFERENCE_STAGE__NOT_PART_OF_PRESS")

oak_base = timber("01 / dark-stained oak bed", (0.035, 0.009, 0.002), (0.060, 0.017, 0.004), 0)
oak_upright = timber("02 / dark-stained oak buttress", (0.033, 0.008, 0.002), (0.058, 0.016, 0.004), 2)
oak_handle = timber("03 / dark finished oak lever", (0.047, 0.015, 0.005), (0.077, 0.029, 0.010), 2)
iron = material("04 / rough blacksmith-forged iron", (0.053, 0.051, 0.045), 0.66, 0.76, 75)
edge_iron = material("05 / rubbed iron edges", (0.11, 0.105, 0.093), 0.71, 0.64, 105)
steel = material("06 / oiled ram steel", (0.085, 0.079, 0.069), 0.60, 0.75)
dark = material("07 / die recess", (0.018, 0.017, 0.015), 0.39, 0.85)
bolts = material("08 / worn through-bolts", (0.12, 0.10, 0.08), 0.55, 0.72)
wood = material("09 / preview-only old worktop", (0.105, 0.052, 0.029), 0.0, 0.90, 14)
work_edge = material("10 / aged preview cut edge", (0.068, 0.032, 0.018), 0, 0.92, 25)
ground = material("12 / charcoal studio floor", (0.035, 0.041, 0.044), 0, 0.9)
forge_surface(iron, (0.018, 0.015, 0.012), (0.075, 0.064, 0.054))
forge_surface(edge_iron, (0.045, 0.038, 0.031), (0.13, 0.11, 0.092))

# The square bed and paired uprights carry one centered arch, ram, and short
# front-facing lever. Every load-bearing form is mirrored across X=0. The grip
# remains inside the bed's front edge, so turning the model changes the view
# without creating a one-sided oversized sprite.
cube("Solid weathered oak press bed", (0, 0, 0.037),
     (0.323, 0.323, 0.066), oak_base, press, 0.006)
for x in (-0.142, 0.142):
    for y in (-0.142, 0.142):
        bolt("Bed corner through-bolt", x, y, 0.072, bolts, press)
cube("Centered front iron inset", (0, -0.161, 0.036),
     (0.043, 0.006, 0.019), iron, press, 0.001)

for side in (-1, 1):
    x = side * 0.105
    cube("Paired dark oak upright", (x, 0, 0.212),
         (0.049, 0.074, 0.298), oak_upright, press, 0.005)
    cube("Inner upright iron strap", (side * 0.079, 0, 0.211),
         (0.013, 0.077, 0.274), iron, press, 0.002)
    cube("Forged upright foot", (x, 0, 0.071),
         (0.069, 0.086, 0.018), edge_iron, press, 0.002)
    cube("Forged upright crown", (x, 0, 0.354),
         (0.069, 0.085, 0.024), edge_iron, press, 0.003)
    for z in (0.095, 0.322):
        face_rivet("Upright front through-pin", x, -0.039, z, bolts, press)

# A single continuous arch replaces the bulky C-frame and separate diagonal
# iron tie. Its broad opening stays legible after downscaling to game tiles.
arch_outline = [
    (-0.137, 0.339), (-0.137, 0.371), (-0.092, 0.388),
    (-0.049, 0.423), (0, 0.440), (0.049, 0.423),
    (0.092, 0.388), (0.137, 0.371), (0.137, 0.339),
    (0.092, 0.351), (0.049, 0.381), (0, 0.396),
    (-0.049, 0.381), (-0.092, 0.351),
]
profile_prism("Symmetric forged iron arch", arch_outline,
              -0.030, 0.030, iron, press, 0.005)
for x in (-0.108, 0.108):
    face_rivet("Arch front pin", x, -0.032, 0.360, bolts, press)

# The top and bottom tooling share the origin. The cam is enclosed by the arch
# so only a compact pivot and continuous vertical ram are visible.
cube("Lower die platform", (0, 0, 0.077),
     (0.072, 0.068, 0.024), edge_iron, press, 0.002)
cylinder("Removable lower die", (0, 0, 0.092),
         0.017, 0.008, steel, press, 8, 0.001)
cylinder("Small lower die socket", (0, 0, 0.0965),
         0.006, 0.001, dark, press, 12, 0)
cube("Upper press plate", (0, 0, 0.159),
     (0.061, 0.057, 0.017), edge_iron, press, 0.002)
cylinder("Centered vertical ram", (0, 0, 0.254),
         0.013, 0.173, steel, press, 20, 0.001)
cylinder("Ram guide inside arch", (0, 0, 0.367),
         0.022, 0.072, iron, press, 20, 0.002)

lever_pivot = (0, -0.041, 0.397)
cylinder("Central lever axle", lever_pivot,
         0.024, 0.060, edge_iron, press, 20, 0.001,
         rotation=(0, math.pi / 2, 0))
for x in (-0.032, 0.032):
    cylinder("Visible lever axle end", (x, lever_pivot[1], lever_pivot[2]),
             0.011, 0.006, bolts, press, 16, 0.0005,
             rotation=(0, math.pi / 2, 0))
rod("Short centered iron lever", lever_pivot, (0, -0.076, 0.367),
    0.014, iron, press, 16)
rod("Forged grip ferrule", (0, -0.072, 0.371), (0, -0.087, 0.360),
    0.020, edge_iron, press, 16)
rod("Short centered dark-oak grip", (0, -0.084, 0.362),
    (0, -0.132, 0.324), 0.019, oak_handle, press, 18)
uv_sphere("Rounded central grip end", (0, -0.133, 0.323),
          (0.019, 0.019, 0.019), oak_handle, press)

# Worktop and floor exist only for the scale/hero image; transparent sprite previews exclude them.
cube("PREVIEW ONLY - oak worktop", (0, 0, -0.031), (0.80, 0.55, 0.062), wood, studio, 0.006)
cube("PREVIEW ONLY - dark front cut edge", (0, -0.277, -0.031), (0.80, 0.005, 0.056), work_edge, studio, 0.001)
for x in (-0.35, 0.35):
    cube("PREVIEW ONLY - steel bench foot", (x, 0.18, -0.15), (0.035, 0.035, 0.22), dark, studio, 0.004)
cube("PREVIEW ONLY - backdrop floor", (0, 0, -0.265), (200, 200, 0.012), ground, studio, 0)
cube("PREVIEW ONLY - dark concept stage", (0, 0, -0.018),
     (200, 200, 0.036), ground, concept_stage, 0)

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.use_denoising = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.view_settings.exposure = -1.3
scene.world.color = (0.10, 0.10, 0.10)
area_light("Warm large key / upper left", (-0.65, -0.80, 1.12), 78, 0.72, (0, 0, 0.2))
area_light("Narrow rear rim", (0.54, 0.55, 0.78), 15, 0.46, (0, 0, 0.2))
area_light("Low front bounce", (0.30, -0.45, 0.24), 5, 0.35, (0, 0, 0.17))

hero = camera("Centered-lever concept hero", (0.78, -1.18, 0.54), (0, 0, 0.28), 0.76)
tabletop = camera("Tabletop scale preview", (0.75, -0.96, 0.69), (0, 0, 0.20), 0.92)
south = camera("South isometric - sprite source", (0.70, -0.80, 0.68), (0, 0, 0.226), 0.66)
east = camera("East isometric - sprite source", (0.80, 0.70, 0.68), (0, 0, 0.226), 0.66)

lo, hi = world_bounds(press.objects)
report = {
    "asset": "Auxilia's Ammunition / manual tabletop ammunition press",
    "concept_reference": "source-assets/concepts/press-redesign-02-center-lever.png",
    "units": "metres",
    "press_bounds_min": [round(v, 5) for v in lo],
    "press_bounds_max": [round(v, 5) for v in hi],
    "press_dimensions": [round(hi[i] - lo[i], 5) for i in range(3)],
    "press_mesh_objects": sum(obj.type == "MESH" for obj in press.objects),
    "preview_worktop_in_prop_collection": False,
    "runtime_assets_written": False,
}
with open(os.path.join(PREVIEWS, "AuxAmmoPress_model_report.json"), "w", encoding="utf-8") as handle:
    json.dump(report, handle, indent=2, ensure_ascii=False)
print("PRESS_REPORT " + json.dumps(report))

# The dark close-up follows the selected centered-lever concept; the worktop
# render establishes scale without becoming part of the model.
studio.hide_render = True
render(os.path.join(PREVIEWS, "AuxAmmoPress_hero.png"), hero, False, 1100, 1200, 64)
studio.hide_render = False
concept_stage.hide_render = True
render(os.path.join(PREVIEWS, "AuxAmmoPress_tabletop.png"), tabletop, False, 1200, 900, 40)
studio.hide_render = True
south_path = os.path.join(PREVIEWS, "AuxAmmoPress_south_transparent.png")
render(south_path, south, True, 900, 900, 40)
small_preview = bpy.data.images.load(south_path, check_existing=False)
small_preview.scale(128, 128)
small_preview.filepath_raw = os.path.join(PREVIEWS, "AuxAmmoPress_south_128px.png")
small_preview.file_format = "PNG"
small_preview.save()
bpy.data.images.remove(small_preview)
render(os.path.join(PREVIEWS, "AuxAmmoPress_east_transparent.png"), east, True, 900, 900, 40)

# Store an immediately usable clean modeling view. The worktop can be toggled back on for art review.
studio.hide_render = True
studio.hide_viewport = True
concept_stage.hide_render = True
concept_stage.hide_viewport = True
scene.camera = south
for obj in bpy.context.selected_objects:
    obj.select_set(False)
for obj in press.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = next(iter(press.objects))
bpy.context.preferences.filepaths.file_preview_type = "NONE"
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "AuxiliasAmmunitionPress.blend"))
print("MODEL_COMPLETE " + os.path.join(HERE, "AuxiliasAmmunitionPress.blend"))
