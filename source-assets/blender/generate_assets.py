import bpy
import math
import os
import shutil
from mathutils import Vector


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
MOD_ROOT = os.path.join(
    REPO_ROOT,
    "workshop",
    "Contents",
    "mods",
    "AuxiliasCrossbow",
)
VERSION_ROOT = os.path.join(MOD_ROOT, "42.20")
MODEL_DIR = os.path.join(VERSION_ROOT, "media", "models_X", "weapons", "2handed")
MODEL_TEXTURE_DIR = os.path.join(VERSION_ROOT, "media", "textures", "weapons", "2handed")
ITEM_TEXTURE_DIR = os.path.join(VERSION_ROOT, "media", "textures")

for directory in (MODEL_DIR, MODEL_TEXTURE_DIR, ITEM_TEXTURE_DIR, SCRIPT_DIR):
    os.makedirs(directory, exist_ok=True)


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.collections:
        if block.name != "Collection":
            bpy.data.collections.remove(block)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)


def material(name, color, metallic=0.0, roughness=0.7):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    return mat


def new_collection(name):
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    return coll


def move_to_collection(obj, coll):
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    coll.objects.link(obj)


def bevel(obj, width=0.012, segments=2):
    modifier = obj.modifiers.new("Soft workshop edges", "BEVEL")
    modifier.width = width
    modifier.segments = segments


def cube_part(coll, name, location, dimensions, mat, rotation=(0.0, 0.0, 0.0), edge=0.01):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel(obj, min(edge, min(dimensions) * 0.25))
    move_to_collection(obj, coll)
    return obj


def cylinder_part(coll, name, location, radius, depth, mat, rotation=(math.pi / 2, 0.0, 0.0), vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel(obj, radius * 0.18, 1)
    move_to_collection(obj, coll)
    return obj


def string_part(coll, name, points, mat, thickness=0.006):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = thickness
    curve.bevel_resolution = 1
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coordinate in zip(spline.points, points):
        point.co = (*coordinate, 1.0)
    obj = bpy.data.objects.new(name, curve)
    coll.objects.link(obj)
    obj.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
    return bpy.context.object


def build_crossbow(name, tier, width, length, wood, dark_wood, metal, cord):
    coll = new_collection(name)
    bow_y = length * 0.33
    stock_z = 0.0

    # Stock, shoulder pad, grip, rail and trigger housing.
    cube_part(coll, f"{name}_Stock", (0, -0.05, stock_z), (0.105, length, 0.105), wood, edge=0.014)
    cube_part(coll, f"{name}_Shoulder", (0, -length * 0.48, -0.015), (0.18, 0.13, 0.15), dark_wood, rotation=(math.radians(-8), 0, 0), edge=0.018)
    cube_part(coll, f"{name}_Rail", (0, 0.12, 0.065), (0.055, length * 0.62, 0.035), metal, edge=0.006)
    cube_part(coll, f"{name}_Grip", (0, -length * 0.18, -0.105), (0.085, 0.15, 0.20), dark_wood, rotation=(math.radians(-18), 0, 0), edge=0.012)
    cube_part(coll, f"{name}_Trigger", (0, -length * 0.08, -0.06), (0.025, 0.07, 0.10), metal, rotation=(math.radians(-12), 0, 0), edge=0.004)

    # Three low-poly segments per limb suggest a historical recurved prod.
    limb_mat = wood if tier == 1 else metal
    segment = width / 6.1
    for side in (-1, 1):
        for index in range(3):
            x = side * segment * (index + 0.55)
            y = bow_y + (0.015 * index)
            angle = math.radians(side * (-7 - index * 7))
            thickness = 0.055 if tier < 3 else 0.07
            cube_part(
                coll,
                f"{name}_Limb_{side}_{index}",
                (x, y, 0.035 + index * 0.003),
                (segment * 1.16, thickness, 0.055 if tier < 3 else 0.065),
                limb_mat,
                rotation=(0, 0, angle),
                edge=0.009,
            )

    string_y = bow_y - 0.05
    string_part(
        coll,
        f"{name}_String",
        [(-width / 2, bow_y + 0.035, 0.038), (0, string_y, 0.07), (width / 2, bow_y + 0.035, 0.038)],
        cord,
        0.005 if tier < 3 else 0.007,
    )

    if tier >= 2:
        cube_part(coll, f"{name}_Stirrup", (0, length * 0.49, -0.035), (0.22, 0.045, 0.05), metal, edge=0.008)
        cube_part(coll, f"{name}_SideBraceL", (-0.075, bow_y - 0.08, 0), (0.035, 0.24, 0.055), metal, edge=0.006)
        cube_part(coll, f"{name}_SideBraceR", (0.075, bow_y - 0.08, 0), (0.035, 0.24, 0.055), metal, edge=0.006)

    if tier == 3:
        cylinder_part(coll, f"{name}_Windlass", (0, -0.12, 0.095), 0.045, 0.30, metal, rotation=(0, math.pi / 2, 0), vertices=16)
        cylinder_part(coll, f"{name}_CrankL", (-0.18, -0.12, 0.095), 0.012, 0.18, metal, rotation=(0, math.pi / 2, 0), vertices=10)

    return coll


def build_bolt(name, broken, wood, metal, feather):
    coll = new_collection(name)
    length = 0.34 if not broken else 0.19
    cylinder_part(coll, f"{name}_Shaft", (0, 0, 0), 0.012, length, wood, vertices=10)
    if not broken:
        cylinder_part(coll, f"{name}_Head", (0, length * 0.52, 0), 0.022, 0.065, metal, vertices=4)
        cube_part(coll, f"{name}_FletchingL", (-0.02, -length * 0.40, 0), (0.04, 0.08, 0.008), feather, edge=0.002)
        cube_part(coll, f"{name}_FletchingR", (0.02, -length * 0.40, 0), (0.04, 0.08, 0.008), feather, edge=0.002)
    else:
        cube_part(coll, f"{name}_Splinter", (0.018, -0.055, 0), (0.018, 0.12, 0.015), wood, rotation=(0, 0, math.radians(18)), edge=0.002)
    return coll


def collection_objects(coll):
    result = list(coll.objects)
    for child in coll.children:
        result.extend(collection_objects(child))
    return result


def export_collection(coll, filename):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection_objects(coll):
        if obj.type == "MESH":
            obj.select_set(True)
    bpy.context.view_layer.objects.active = next(obj for obj in collection_objects(coll) if obj.type == "MESH")
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(MODEL_DIR, f"{filename}.fbx"),
        use_selection=True,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="AUTO",
    )


def look_at(obj, point=(0, 0, 0)):
    direction = Vector(point) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.view_settings.look = "AgX - Medium High Contrast"

    bpy.ops.object.camera_add(location=(1.1, -1.35, 1.5))
    camera = bpy.context.object
    camera.name = "AssetCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 1.35
    look_at(camera, (0, 0, 0))
    scene.camera = camera

    bpy.ops.object.light_add(type="AREA", location=(1.2, -0.8, 2.2))
    key = bpy.context.object
    key.data.energy = 900
    key.data.shape = "DISK"
    key.data.size = 2.2
    look_at(key)

    bpy.ops.object.light_add(type="AREA", location=(-1.6, 0.8, 1.1))
    fill = bpy.context.object
    fill.data.energy = 550
    fill.data.size = 2.0
    look_at(fill)
    return camera


def set_visible(target, asset_collections):
    for coll in asset_collections:
        coll.hide_render = coll is not target


def render_icon(coll, asset_collections, filename, scale):
    scene = bpy.context.scene
    set_visible(coll, asset_collections)
    scene.render.film_transparent = True
    scene.render.resolution_x = 128
    scene.render.resolution_y = 128
    scene.camera.data.ortho_scale = scale
    scene.render.filepath = os.path.join(ITEM_TEXTURE_DIR, f"Item_{filename}.png")
    bpy.ops.render.render(write_still=True)


def make_flat_texture(filename, color):
    image = bpy.data.images.new(filename, width=32, height=32, alpha=True)
    pixels = []
    for y in range(32):
        for x in range(32):
            noise = (((x * 13 + y * 7) % 11) - 5) / 255.0
            pixels.extend((max(0, min(1, color[0] + noise)), max(0, min(1, color[1] + noise)), max(0, min(1, color[2] + noise)), 1.0))
    image.pixels = pixels
    image.filepath_raw = os.path.join(MODEL_TEXTURE_DIR, f"{filename}.png")
    image.file_format = "PNG"
    image.save()


def render_promo(heavy, asset_collections, camera):
    scene = bpy.context.scene
    set_visible(heavy, asset_collections)
    scene.render.film_transparent = False
    scene.world.color = (0.018, 0.024, 0.02)
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    camera.data.ortho_scale = 1.55
    camera.location = (1.1, -1.35, 1.5)
    look_at(camera, (0, 0.02, 0))
    poster = os.path.join(MOD_ROOT, "poster.png")
    scene.render.filepath = poster
    bpy.ops.render.render(write_still=True)
    shutil.copy2(poster, os.path.join(MOD_ROOT, "icon.png"))
    shutil.copy2(poster, os.path.join(REPO_ROOT, "workshop", "preview.png"))


reset_scene()

WOOD = material("Aged Oak", (0.27, 0.12, 0.045), roughness=0.82)
DARK_WOOD = material("Dark Stock", (0.11, 0.045, 0.018), roughness=0.78)
METAL = material("Forged Iron", (0.11, 0.13, 0.14), metallic=0.72, roughness=0.48)
CORD = material("Hemp Cord", (0.35, 0.28, 0.15), roughness=0.95)
FEATHER = material("Fletching", (0.55, 0.48, 0.30), roughness=0.90)

improvised = build_crossbow("AuxiliaImprovisedCrossbow", 1, 0.62, 0.78, WOOD, DARK_WOOD, METAL, CORD)
reinforced = build_crossbow("AuxiliaReinforcedCrossbow", 2, 0.72, 0.84, WOOD, DARK_WOOD, METAL, CORD)
heavy = build_crossbow("AuxiliaHeavyArbalest", 3, 0.82, 0.91, WOOD, DARK_WOOD, METAL, CORD)
bolt = build_bolt("AuxiliaCrossbowBolt", False, WOOD, METAL, FEATHER)
broken_bolt = build_bolt("AuxiliaBrokenBolt", True, WOOD, METAL, FEATHER)
assets = [improvised, reinforced, heavy, bolt, broken_bolt]

for collection, filename in (
    (improvised, "AuxiliaImprovisedCrossbow"),
    (reinforced, "AuxiliaReinforcedCrossbow"),
    (heavy, "AuxiliaHeavyArbalest"),
    (bolt, "AuxiliaCrossbowBolt"),
    (broken_bolt, "AuxiliaBrokenBolt"),
):
    export_collection(collection, filename)

make_flat_texture("AuxiliaImprovisedCrossbow", (0.28, 0.13, 0.05))
make_flat_texture("AuxiliaReinforcedCrossbow", (0.22, 0.12, 0.06))
make_flat_texture("AuxiliaHeavyArbalest", (0.16, 0.15, 0.12))
make_flat_texture("AuxiliaCrossbowBolt", (0.27, 0.15, 0.07))
make_flat_texture("AuxiliaBrokenBolt", (0.22, 0.11, 0.05))

camera = setup_render()
render_icon(improvised, assets, "AuxiliaImprovisedCrossbow", 1.28)
render_icon(reinforced, assets, "AuxiliaReinforcedCrossbow", 1.35)
render_icon(heavy, assets, "AuxiliaHeavyArbalest", 1.48)
render_icon(bolt, assets, "AuxiliaCrossbowBolt", 0.58)
render_icon(broken_bolt, assets, "AuxiliaBrokenBolt", 0.42)
render_promo(heavy, assets, camera)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "AuxiliasCrossbowAssets.blend"))
print(f"Auxilia's Crossbow assets generated under: {VERSION_ROOT}")
