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
    """Subtle lengthwise oak grain, scaled for the beam rather than the studio desk."""
    mat = material(name, light_color, 0.0, 0.87)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    coords = nodes.new("ShaderNodeTexCoord")
    stretch = nodes.new("ShaderNodeVectorMath")
    stretch.operation = "MULTIPLY"
    stretch.inputs[1].default_value = tuple(1.5 if i == grain_axis else 35.0 for i in range(3))
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.0
    noise.inputs["Detail"].default_value = 4.0
    noise.inputs["Roughness"].default_value = 0.70
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.25
    ramp.color_ramp.elements[0].color = (*dark_color, 1)
    ramp.color_ramp.elements[1].position = 0.77
    ramp.color_ramp.elements[1].color = (*light_color, 1)
    middle = ramp.color_ramp.elements.new(0.51)
    middle.color = (*tuple((dark_color[i] + light_color[i]) * 0.45 for i in range(3)), 1)
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.32
    bump.inputs["Distance"].default_value = 0.0012
    stains = nodes.new("ShaderNodeTexNoise")
    stains.inputs["Scale"].default_value = 6.0
    stains.inputs["Detail"].default_value = 3.0
    stain_range = nodes.new("ShaderNodeValToRGB")
    stain_range.color_ramp.elements[0].position = 0.32
    stain_range.color_ramp.elements[0].color = (0.35, 0.30, 0.25, 1)
    stain_range.color_ramp.elements[1].position = 0.67
    stain_range.color_ramp.elements[1].color = (1, 1, 1, 1)
    stained_color = nodes.new("ShaderNodeMixRGB")
    stained_color.blend_type = "MULTIPLY"
    stained_color.inputs[0].default_value = 0.45
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
    """Extrude a single open-throat X/Z silhouette into a solid forged frame."""
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

oak_base = timber("01 / weathered oak bed", (0.056, 0.025, 0.011), (0.16, 0.074, 0.032), 0)
oak_upright = timber("02 / old oak buttress", (0.050, 0.022, 0.010), (0.15, 0.069, 0.029), 2)
oak_handle = timber("03 / dark oak lever", (0.040, 0.018, 0.008), (0.115, 0.053, 0.022), 2)
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

# A broad oak bed carries an asymmetrical oak buttress and a forged-iron C throat.
# The desk is a separate preview prop. X and Y are the press-bed plane.
cube("Solid weathered oak press bed", (-0.019, 0.002, 0.037),
     (0.400, 0.246, 0.066), oak_base, press, 0.006)
for x in (-0.190, 0.153):
    cube("Front forged corner wrap", (x, -0.105, 0.048),
         (0.049, 0.038, 0.040), iron, press, 0.004)
    cube("Corner wrap over front edge", (x, -0.124, 0.031),
         (0.049, 0.007, 0.057), iron, press, 0.002)
    bolt("Corner through-bolt", x, -0.106, 0.071, bolts, press)
    face_rivet("Corner wrap side pin", x, -0.130, 0.032, bolts, press)
cube("Rear iron bed tie", (-0.019, 0.113, 0.051),
     (0.348, 0.014, 0.031), iron, press, 0.002)

# One angled oak strut supports the pivot. Its narrow front iron strap and
# two large pins echo rough blacksmith work rather than a clean factory frame.
profile_prism("Broad tapered oak buttress",
              [(-0.208, 0.070), (-0.130, 0.070),
               (-0.139, 0.365), (-0.177, 0.365)],
              -0.094, -0.015, oak_upright, press, 0.005)
square_beam("Broad forged buttress strap", (-0.190, -0.101, 0.087),
            (-0.160, -0.101, 0.349), 0.036, 0.010, iron, press)
for x, z in ((-0.185, 0.118), (-0.169, 0.252), (-0.158, 0.328)):
    face_rivet("Buttress through-pin", x, -0.108, z, bolts, press)
cube("Strut foot bracket", (-0.170, -0.050, 0.079),
     (0.090, 0.098, 0.026), iron, press, 0.003)

# A single open C profile is the metal load path. The central air gap and
# narrow right-facing nose are important for the silhouette at sprite scale.
c_outline = [
    (0.105, 0.069), (-0.025, 0.069), (-0.078, 0.076),
    (-0.119, 0.099), (-0.145, 0.135), (-0.154, 0.178),
    (-0.151, 0.225), (-0.138, 0.273), (-0.110, 0.311),
    (-0.071, 0.336), (-0.025, 0.345), (0.090, 0.345),
    (0.090, 0.292), (-0.011, 0.292), (-0.043, 0.283),
    (-0.070, 0.263), (-0.087, 0.233), (-0.094, 0.200),
    (-0.090, 0.163), (-0.071, 0.133), (-0.042, 0.117),
    (0.105, 0.117),
]
profile_prism("One-piece forged iron C-frame", c_outline,
              -0.076, 0.013, iron, press, 0.007)
cube("Rear C-frame foot anchor", (-0.102, 0.002, 0.088),
     (0.072, 0.092, 0.020), edge_iron, press, 0.002)
for x, z in ((-0.122, 0.141), (-0.124, 0.257), (0.025, 0.317)):
    face_rivet("Frame forge-rivet", x, -0.079, z, bolts, press)

# Both dies and the sliding ram share one centerline, inside the C throat.
die_x, die_y = 0.063, -0.045
cube("Lower die iron bed", (die_x, die_y, 0.108),
     (0.091, 0.092, 0.019), edge_iron, press, 0.002)
cube("Removable lower die block", (die_x, die_y, 0.132),
     (0.041, 0.044, 0.029), steel, press, 0.002)
cylinder("Small lower die socket", (die_x, die_y, 0.148),
         0.009, 0.002, dark, press, 16, 0)
cube("Compact iron ram guide at C nose", (die_x, -0.055, 0.296),
     (0.047, 0.063, 0.061), iron, press, 0.003)
for x in (die_x - 0.025, die_x + 0.025):
    cube("Ram guide cheek", (x, -0.089, 0.280),
         (0.009, 0.015, 0.045), iron, press, 0.001)
    face_rivet("Guide cheek bolt", x, -0.100, 0.293, bolts, press)
cylinder("Vertical working ram", (die_x, die_y, 0.295),
         0.017, 0.150, steel, press, 20, 0.001)
cube("Upper stamping die", (die_x, die_y, 0.206),
     (0.040, 0.044, 0.029), edge_iron, press, 0.002)
cube("Moving upper ram fork", (die_x, -0.074, 0.380),
     (0.039, 0.047, 0.026), iron, press, 0.002)
cube("Frontward moving link clevis", (die_x, -0.128, 0.380),
     (0.036, 0.071, 0.024), iron, press, 0.002)

# Pivot on the oak strut -> short broad forged lever -> pinned link ->
# moving ram fork -> die. The long dark timber grip projects to the right.
square_beam("C-frame to pivot iron tie", (-0.100, -0.052, 0.330),
            (-0.158, -0.052, 0.389), 0.025, 0.035, iron, press)
cube("Pivot iron saddle", (-0.158, -0.095, 0.379),
     (0.065, 0.087, 0.045), iron, press, 0.003)
cylinder("Main lever pivot", (-0.158, -0.143, 0.391),
         0.020, 0.040, edge_iron, press, 20, 0.001,
         rotation=(math.pi / 2, 0, 0))
cylinder("Visible pivot pin", (-0.158, -0.168, 0.391),
         0.011, 0.006, bolts, press, 16, 0.0006,
         rotation=(math.pi / 2, 0, 0))
lever_outline = [(-0.168, 0.378), (0.044, 0.435),
                 (0.042, 0.458), (-0.167, 0.407)]
profile_prism("Flat forged lever arm", lever_outline,
              -0.163, -0.131, iron, press, 0.003)
cylinder("Link top pin", (0.011, -0.172, 0.436),
         0.010, 0.007, bolts, press, 16, 0.0005,
         rotation=(math.pi / 2, 0, 0))
rod("Short exposed connecting link", (0.011, -0.170, 0.436),
    (die_x, -0.164, 0.383), 0.009, edge_iron, press)
cylinder("Moving ram fork pin", (die_x, -0.175, 0.383),
         0.010, 0.008, bolts, press, 16, 0.0005,
         rotation=(math.pi / 2, 0, 0))
lever_pivot_x = (lever_outline[0][0] + lever_outline[3][0]) / 2
lever_pivot_z = (lever_outline[0][1] + lever_outline[3][1]) / 2
lever_tip_x = (lever_outline[1][0] + lever_outline[2][0]) / 2
lever_tip_z = (lever_outline[1][1] + lever_outline[2][1]) / 2
lever_slope = (lever_tip_z - lever_pivot_z) / (lever_tip_x - lever_pivot_x)
handle_start_x, handle_end_x = 0.040, 0.290
handle_start_z = lever_tip_z + (handle_start_x - lever_tip_x) * lever_slope
handle_end_z = handle_start_z + (handle_end_x - handle_start_x) * lever_slope
rod("Long dark oak lever", (handle_start_x, -0.146, handle_start_z),
    (handle_end_x, -0.146, handle_end_z), 0.024, oak_handle, press, 18)
rod("Forged ferrule on lever joint", (0.039, -0.146, handle_start_z),
    (0.069, -0.146, handle_start_z + (0.069 - handle_start_x) * lever_slope),
    0.026, iron, press, 18)
uv_sphere("Rounded timber handle end", (handle_end_x + 0.002, -0.146, handle_end_z + 0.0005),
          (0.024, 0.024, 0.024), oak_handle, press)

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

hero = camera("Concept B comparison hero", (0.78, -1.18, 0.54), (0.025, 0, 0.28), 0.76)
tabletop = camera("Tabletop scale preview", (0.75, -0.96, 0.69), (0, 0, 0.20), 0.92)
south = camera("South isometric - sprite source", (0.70, -0.80, 0.68), (0, 0, 0.226), 0.66)
east = camera("East isometric - sprite source", (0.80, 0.70, 0.68), (0, 0, 0.226), 0.66)

lo, hi = world_bounds(press.objects)
report = {
    "asset": "Auxilia's Ammunition / manual tabletop ammunition press",
    "concept_reference": "source-assets/concepts/ammo-press-concept-b-lever.png",
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

# The dark close-up mirrors concept B; a separate worktop render establishes table scale.
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
