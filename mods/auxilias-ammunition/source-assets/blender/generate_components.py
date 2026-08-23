"""Generate dedicated ground models for ammunition components.

Run with Blender, not the system Python:
    blender --background --python generate_components.py

The meshes are authored in metres with X/Y on the ground plane and Z up. Each
projectile and empty hull model represents exactly one counted inventory item;
only Shot Charge contains multiple pellets because it is one shell's charge.
"""

import bpy
import json
import math
import os
from mathutils import Vector


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MOD_PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
MONOREPO_ROOT = os.path.abspath(os.path.join(MOD_PROJECT_ROOT, "..", ".."))
with open(os.path.join(MONOREPO_ROOT, "config", "project-zomboid.json"), "r", encoding="utf-8") as handle:
    RELEASE_LINE = json.load(handle)["target"]["releaseLine"]

VERSION_ROOT = os.path.join(
    MOD_PROJECT_ROOT,
    "workshop",
    "Contents",
    "mods",
    "AuxiliasAmmunition",
    RELEASE_LINE,
)
MODEL_DIR = os.path.join(VERSION_ROOT, "media", "models_X", "WorldItems")
TEXTURE_DIR = os.path.join(VERSION_ROOT, "media", "textures", "WorldItems")
VALIDATION_DIR = os.path.join(MOD_PROJECT_ROOT, "work", "model-validation")
ATLAS_NAME = "AuxAmmoComponentAtlas"

for directory in (MODEL_DIR, TEXTURE_DIR, VALIDATION_DIR, SCRIPT_DIR):
    os.makedirs(directory, exist_ok=True)


ASSET_NAMES = (
    "AuxAmmoSmallPistolProjectile_Ground",
    "AuxAmmoHeavyPistolProjectile_Ground",
    "AuxAmmoRifleProjectile_Ground",
    "AuxAmmoShotCharge_Ground",
    "AuxAmmoShotgunHull_Ground",
)

SWATCH_CENTERS = {
    "Lead": (0.10, 0.50),
    "Copper Jacket": (0.30, 0.50),
    "Brass": (0.50, 0.50),
    "Hull Red": (0.70, 0.50),
    "Hull Interior": (0.90, 0.50),
}

EXPECTED_DIMENSIONS = {
    "AuxAmmoSmallPistolProjectile_Ground": ((0.012, 0.020), (0.008, 0.014), (0.008, 0.012)),
    "AuxAmmoHeavyPistolProjectile_Ground": ((0.014, 0.024), (0.010, 0.018), (0.010, 0.015)),
    "AuxAmmoRifleProjectile_Ground": ((0.025, 0.035), (0.008, 0.017), (0.008, 0.012)),
    "AuxAmmoShotCharge_Ground": ((0.030, 0.060), (0.025, 0.055), (0.010, 0.025)),
    "AuxAmmoShotgunHull_Ground": ((0.055, 0.070), (0.020, 0.040), (0.018, 0.030)),
}


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    for material_block in list(bpy.data.materials):
        bpy.data.materials.remove(material_block)


def material(name, color, metallic=0.0, roughness=0.7):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1.0)
    result.use_nodes = True
    principled = result.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    return result


def new_collection(name):
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def move_to_collection(obj, collection):
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)


def add_bevel(obj, width, segments=1):
    modifier = obj.modifiers.new("Edge bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments


def rotate_xy(point, angle):
    x, y, z = point
    cosine = math.cos(angle)
    sine = math.sin(angle)
    return (x * cosine - y * sine, x * sine + y * cosine, z)


def translated(point, origin, angle=0.0):
    rotated = rotate_xy(point, angle)
    return tuple(rotated[index] + origin[index] for index in range(3))


def cylinder_part(collection, name, origin, local_x, radius, depth, mat, angle=0.0, vertices=12):
    location = translated((local_x, 0.0, radius), origin, angle)
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=(0.0, math.pi / 2, angle),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    add_bevel(obj, min(radius * 0.12, 0.0008), 1)
    move_to_collection(obj, collection)
    return obj


def cone_part(collection, name, origin, local_x, radius_back, radius_front, depth, mat, angle=0.0, vertices=12):
    location = translated((local_x, 0.0, radius_back), origin, angle)
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius_back,
        radius2=radius_front,
        depth=depth,
        location=location,
        rotation=(0.0, math.pi / 2, angle),
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    add_bevel(obj, min(radius_back * 0.10, 0.0007), 1)
    move_to_collection(obj, collection)
    return obj


def build_projectile(collection, prefix, origin, angle, radius, body_length, nose_length, nose_ratio, mats):
    lead, copper = mats
    total_length = body_length + nose_length
    base_x = -total_length * 0.5
    cylinder_part(
        collection,
        f"{prefix}_Jacket",
        origin,
        base_x + body_length * 0.5,
        radius,
        body_length,
        copper,
        angle,
        vertices=12,
    )
    cone_part(
        collection,
        f"{prefix}_Nose",
        origin,
        base_x + body_length + nose_length * 0.5,
        radius,
        radius * nose_ratio,
        nose_length,
        lead if nose_ratio > 0.45 else copper,
        angle,
        vertices=12,
    )


def build_single_projectile_model(name, radius, body_length, nose_length, nose_ratio, mats, angle):
    collection = new_collection(name)
    build_projectile(
        collection,
        name,
        (0.0, 0.0, 0.0),
        angle,
        radius,
        body_length,
        nose_length,
        nose_ratio,
        mats,
    )
    return collection


def build_shot_charge(name, lead):
    collection = new_collection(name)
    radius = 0.0042
    positions = (
        (-0.0126, -0.0084, radius), (-0.0042, -0.0084, radius),
        (0.0042, -0.0084, radius), (0.0126, -0.0084, radius),
        (-0.0126, 0.0000, radius), (-0.0042, 0.0000, radius),
        (0.0042, 0.0000, radius), (0.0126, 0.0000, radius),
        (-0.0084, 0.0084, radius), (0.0000, 0.0084, radius),
        (0.0084, 0.0084, radius),
        (-0.0042, -0.0042, radius * 2.55), (0.0042, -0.0042, radius * 2.55),
        (0.0000, 0.0042, radius * 2.55),
    )
    for index, location in enumerate(positions, start=1):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=radius, location=location)
        pellet = bpy.context.object
        pellet.name = f"{name}_Pellet_{index}"
        pellet.data.materials.append(lead)
        move_to_collection(pellet, collection)
    return collection


def build_hull(collection, prefix, origin, angle, mats):
    brass, red, dark = mats
    body_length = 0.046
    base_length = 0.012
    radius = 0.010
    total_length = body_length + base_length
    back_x = -total_length * 0.5
    cylinder_part(collection, f"{prefix}_BrassBase", origin, back_x + base_length * 0.5, radius * 1.03, base_length, brass, angle, vertices=16)
    cylinder_part(collection, f"{prefix}_PlasticHull", origin, back_x + base_length + body_length * 0.5, radius, body_length, red, angle, vertices=16)
    mouth_x = back_x + total_length + 0.0005
    cylinder_part(collection, f"{prefix}_OpenMouth", origin, mouth_x, radius * 0.72, 0.0015, dark, angle, vertices=16)

    location = translated((mouth_x, 0.0, radius), origin, angle)
    bpy.ops.mesh.primitive_torus_add(
        major_radius=radius * 0.82,
        minor_radius=radius * 0.18,
        major_segments=16,
        minor_segments=6,
        location=location,
        rotation=(0.0, math.pi / 2, angle),
    )
    rim = bpy.context.object
    rim.name = f"{prefix}_MouthRim"
    rim.data.materials.append(red)
    move_to_collection(rim, collection)


def build_single_shotgun_hull(name, mats):
    collection = new_collection(name)
    build_hull(collection, name, (0.0, 0.0, 0.0), math.radians(-12), mats)
    return collection


def collection_objects(collection):
    result = list(collection.objects)
    for child in collection.children:
        result.extend(collection_objects(child))
    return result


def apply_modifiers_and_transforms(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)


def assign_palette_uv(obj):
    uv_layer = obj.data.uv_layers.get("UVMap") or obj.data.uv_layers.new(name="UVMap")
    for polygon in obj.data.polygons:
        material_name = obj.data.materials[polygon.material_index].name
        uv = SWATCH_CENTERS[material_name]
        for loop_index in polygon.loop_indices:
            uv_layer.data[loop_index].uv = uv


def collapse_game_materials(obj):
    if not obj.data.materials:
        raise RuntimeError(f"{obj.name}: no material assigned")
    game_material = obj.data.materials[0]
    for polygon in obj.data.polygons:
        polygon.material_index = 0
    obj.data.materials.clear()
    obj.data.materials.append(game_material)


def finalize_collection(collection):
    objects = [obj for obj in collection_objects(collection) if obj.type == "MESH"]
    if not objects:
        raise RuntimeError(f"{collection.name}: no mesh geometry")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        apply_modifiers_and_transforms(obj)
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.object
    joined.name = collection.name
    joined.data.name = f"{collection.name}Mesh"
    assign_palette_uv(joined)
    collapse_game_materials(joined)
    triangulate = joined.modifiers.new("Game triangulation", "TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    joined.data.validate(verbose=True)
    joined.data.update()
    return joined


def object_bounds(obj):
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector(tuple(min(vertex[index] for vertex in corners) for index in range(3)))
    maximum = Vector(tuple(max(vertex[index] for vertex in corners) for index in range(3)))
    return minimum, maximum


def export_object(obj, filename):
    game_obj = obj.copy()
    game_obj.data = obj.data.copy()
    bpy.context.scene.collection.objects.link(game_obj)
    game_obj.name = f"{filename}_GameExport"
    game_obj.rotation_euler.x += math.pi
    bpy.ops.object.select_all(action="DESELECT")
    game_obj.select_set(True)
    bpy.context.view_layer.objects.active = game_obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(MODEL_DIR, f"{filename}.fbx"),
        use_selection=True,
        object_types={"MESH"},
        global_scale=1.0,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_NONE",
        use_space_transform=True,
        bake_space_transform=False,
        axis_forward="-Y",
        axis_up="Z",
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="STRIP",
    )
    game_mesh = game_obj.data
    bpy.data.objects.remove(game_obj, do_unlink=True)
    bpy.data.meshes.remove(game_mesh)


def make_atlas():
    width = height = 128
    colors = {
        "Lead": (0.30, 0.32, 0.33),
        "Copper Jacket": (0.48, 0.22, 0.065),
        "Brass": (0.55, 0.34, 0.075),
        "Hull Red": (0.39, 0.020, 0.014),
        "Hull Interior": (0.025, 0.020, 0.018),
    }
    pixels = []
    ordered = tuple(colors)
    for y in range(height):
        for x in range(width):
            swatch = ordered[min(len(ordered) - 1, x * len(ordered) // width)]
            base = colors[swatch]
            grain = (((x * 13 + y * 7) % 17) - 8) / 600.0
            pixels.extend(tuple(max(0.0, min(1.0, channel + grain)) for channel in base) + (1.0,))
    image = bpy.data.images.new(ATLAS_NAME, width=width, height=height, alpha=True)
    image.pixels = pixels
    image.filepath_raw = os.path.join(TEXTURE_DIR, f"{ATLAS_NAME}.png")
    image.file_format = "PNG"
    image.save()
    return image


def apply_atlas(image, materials):
    for mat in materials:
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        principled = nodes.get("Principled BSDF")
        texture = nodes.new("ShaderNodeTexImage")
        texture.name = "Game atlas"
        texture.image = image
        links.new(texture.outputs["Color"], principled.inputs["Base Color"])


def import_fbx(filepath):
    before = set(bpy.context.scene.objects)
    try:
        bpy.ops.wm.fbx_import(filepath=filepath)
    except (AttributeError, RuntimeError):
        bpy.ops.import_scene.fbx(filepath=filepath)
    return [obj for obj in bpy.context.scene.objects if obj not in before and obj.type == "MESH"]


def validate_exports(asset_objects):
    report = {"coordinate_system": "X/Y ground plane, Z up", "assets": {}}
    for name, source in asset_objects.items():
        minimum, maximum = object_bounds(source)
        dimensions = maximum - minimum
        for axis, value, limits in zip("XYZ", dimensions, EXPECTED_DIMENSIONS[name]):
            if not limits[0] <= value <= limits[1]:
                raise RuntimeError(f"{name}: {axis} dimension {value:.5f} outside {limits}")
        imported = import_fbx(os.path.join(MODEL_DIR, f"{name}.fbx"))
        if len(imported) != 1:
            raise RuntimeError(f"{name}: expected one imported mesh, got {len(imported)}")
        imported_obj = imported[0]
        if len(imported_obj.data.materials) != 1 or len(imported_obj.data.uv_layers) != 1:
            raise RuntimeError(f"{name}: FBX must retain one material and one UV layer")
        imported_minimum, imported_maximum = object_bounds(imported_obj)
        imported_dimensions = imported_maximum - imported_minimum
        if max(abs(imported_dimensions[index] - dimensions[index]) for index in range(3)) > 0.002:
            raise RuntimeError(f"{name}: FBX round trip changed dimensions")
        report["assets"][name] = {
            "vertices": len(source.data.vertices),
            "triangles": len(source.data.polygons),
            "materials": len(source.data.materials),
            "uv_layers": len(source.data.uv_layers),
            "bounds_min": [round(value, 5) for value in minimum],
            "bounds_max": [round(value, 5) for value in maximum],
            "dimensions": [round(value, 5) for value in dimensions],
            "fbx_round_trip_dimensions": [round(value, 5) for value in imported_dimensions],
        }
        bpy.data.objects.remove(imported_obj, do_unlink=True)
    report_path = os.path.join(VALIDATION_DIR, "report.json")
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, ensure_ascii=False, indent=2)
    return report_path


def look_at(obj, target=(0.0, 0.0, 0.0)):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_validation(collections, camera):
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.image_settings.file_format = "PNG"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 384
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.world.color = (0.012, 0.016, 0.014)
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = -1.3
    for collection in collections:
        for candidate in collections:
            candidate.hide_render = candidate is not collection
        camera.location = (0.12, -0.15, 0.12)
        if "Hull" in collection.name:
            camera.data.ortho_scale = 0.095
        elif "ShotCharge" in collection.name:
            camera.data.ortho_scale = 0.060
        elif "Rifle" in collection.name:
            camera.data.ortho_scale = 0.065
        else:
            camera.data.ortho_scale = 0.050
        look_at(camera, (0.0, 0.0, 0.006))
        scene.render.filepath = os.path.join(VALIDATION_DIR, f"{collection.name}.png")
        bpy.ops.render.render(write_still=True)


reset_scene()
LEAD = material("Lead", (0.30, 0.32, 0.33), metallic=0.55, roughness=0.58)
COPPER = material("Copper Jacket", (0.48, 0.22, 0.065), metallic=0.48, roughness=0.52)
BRASS = material("Brass", (0.55, 0.34, 0.075), metallic=0.55, roughness=0.50)
HULL_RED = material("Hull Red", (0.39, 0.020, 0.014), roughness=0.72)
HULL_DARK = material("Hull Interior", (0.025, 0.020, 0.018), roughness=0.95)
MATERIALS = (LEAD, COPPER, BRASS, HULL_RED, HULL_DARK)

small = build_single_projectile_model(ASSET_NAMES[0], 0.0044, 0.0085, 0.0065, 0.42, (LEAD, COPPER), math.radians(15))
heavy = build_single_projectile_model(ASSET_NAMES[1], 0.0055, 0.0105, 0.0065, 0.72, (LEAD, COPPER), math.radians(-12))
rifle = build_single_projectile_model(ASSET_NAMES[2], 0.0042, 0.0130, 0.0150, 0.05, (LEAD, COPPER), math.radians(10))
shot = build_shot_charge(ASSET_NAMES[3], LEAD)
hulls = build_single_shotgun_hull(ASSET_NAMES[4], (BRASS, HULL_RED, HULL_DARK))
collections = (small, heavy, rifle, shot, hulls)

asset_objects = {collection.name: finalize_collection(collection) for collection in collections}
for asset_name, asset_object in asset_objects.items():
    export_object(asset_object, asset_name)

atlas = make_atlas()
apply_atlas(atlas, MATERIALS)

bpy.ops.object.camera_add(location=(0.12, -0.15, 0.12))
camera = bpy.context.object
camera.data.type = "ORTHO"
bpy.context.scene.camera = camera
bpy.ops.object.light_add(type="AREA", location=(-0.08, -0.10, 0.20))
key = bpy.context.object
key.data.energy = 85
key.data.size = 0.35
look_at(key)
render_validation(collections, camera)

bpy.context.preferences.filepaths.file_preview_type = "NONE"
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "AuxiliasAmmunitionComponents.blend"))
report_path = validate_exports(asset_objects)
print(f"Auxilia's Ammunition component models generated under: {VERSION_ROOT}")
print(f"Model validation report: {report_path}")
