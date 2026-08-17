"""Generate, export, render, and validate Auxilia's Crossbow assets.

Run with Blender, not the system Python:
    blender --background --python generate_assets.py

Project Zomboid firearm meshes use X for width, Y for muzzle direction, and Z for
height. Their action/trigger sits close to the origin. The three crossbow tiers
share the compact vanilla sawn-off double-barrel shotgun hand envelope.
"""

import bpy
import json
import math
import os
import shutil
from mathutils import Vector


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
MOD_ROOT = os.path.join(REPO_ROOT, "workshop", "Contents", "mods", "AuxiliasCrossbow")
VERSION_ROOT = os.path.join(MOD_ROOT, "42.20")
MODEL_DIR = os.path.join(VERSION_ROOT, "media", "models_X", "weapons", "2handed")
MODEL_TEXTURE_DIR = os.path.join(VERSION_ROOT, "media", "textures", "weapons", "2handed")
ITEM_TEXTURE_DIR = os.path.join(VERSION_ROOT, "media", "textures")
VALIDATION_DIR = os.path.join(REPO_ROOT, "work", "model-validation")

for directory in (MODEL_DIR, MODEL_TEXTURE_DIR, ITEM_TEXTURE_DIR, VALIDATION_DIR, SCRIPT_DIR):
    os.makedirs(directory, exist_ok=True)


SWATCHES = {
    "Aged Oak": (0.02, 0.52, 0.52, 0.98),
    "Dark Stock": (0.52, 0.98, 0.52, 0.98),
    "Forged Iron": (0.02, 0.32, 0.02, 0.48),
    "Hemp Cord": (0.35, 0.64, 0.02, 0.48),
    "Leather": (0.67, 0.98, 0.02, 0.48),
}


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.collections):
        if block.name != "Collection":
            bpy.data.collections.remove(block)
    for block in list(bpy.data.materials):
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


def bevel(obj, width=0.006, segments=2):
    modifier = obj.modifiers.new("Edge bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments


def cube_part(coll, name, location, dimensions, mat, rotation=(0.0, 0.0, 0.0), edge=0.006):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel(obj, min(edge, min(dimensions) * 0.22))
    move_to_collection(obj, coll)
    return obj


def cylinder_part(coll, name, location, radius, depth, mat, rotation=(math.pi / 2, 0.0, 0.0), vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel(obj, min(radius * 0.16, 0.004), 1)
    move_to_collection(obj, coll)
    return obj


def cone_part(coll, name, location, radius, depth, mat, rotation=(-math.pi / 2, 0.0, 0.0), vertices=4):
    """Create a pointed low-poly cone, oriented along the weapon's Y axis by default."""
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0.0, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel(obj, min(radius * 0.10, 0.0025), 1)
    move_to_collection(obj, coll)
    return obj


def beam_between(coll, name, start, end, width, height, mat, edge=0.004):
    """Create a rectangular beam whose long local axis connects start to end."""
    start = Vector(start)
    end = Vector(end)
    direction = end - start
    obj = cube_part(coll, name, (start + end) * 0.5, (width, direction.length, height), mat, edge=edge)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 1.0, 0.0)).rotation_difference(direction.normalized())
    return obj


def profile_prism(coll, name, yz_profile, width, mat, edge=0.006):
    """Extrude a clockwise Y/Z silhouette along X."""
    vertices = []
    half = width * 0.5
    for x in (-half, half):
        vertices.extend((x, y, z) for y, z in yz_profile)
    count = len(yz_profile)
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
    for index in range(count):
        nxt = (index + 1) % count
        faces.append((index, nxt, count + nxt, count + index))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.data.materials.append(mat)
    bevel(obj, edge, 2)
    return obj


def tapered_tiller(coll, name, sections, mat, edge=0.004):
    """Build a continuous rectangular-section tiller that narrows over the support hand."""
    vertices = []
    for y, width, bottom, top in sections:
        half = width * 0.5
        vertices.extend((
            (-half, y, bottom),
            (half, y, bottom),
            (half, y, top),
            (-half, y, top),
        ))
    faces = [(0, 3, 2, 1)]
    for index in range(len(sections) - 1):
        a = index * 4
        b = (index + 1) * 4
        faces.extend((
            (a, b, b + 3, a + 3),
            (a + 1, a + 2, b + 2, b + 1),
            (a + 3, b + 3, b + 2, a + 2),
            (a, a + 1, b + 1, b),
        ))
    end = (len(sections) - 1) * 4
    faces.append((end, end + 1, end + 2, end + 3))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.data.materials.append(mat)
    bevel(obj, edge, 2)
    return obj


def curved_limb(coll, name, points, chord_widths, thicknesses, mat, edge=0.004):
    """Build one continuous, tapered crossbow limb from center to tip."""
    if not (len(points) == len(chord_widths) == len(thicknesses)):
        raise ValueError("Limb points, widths, and thicknesses must have equal length")
    vertices = []
    for index, point in enumerate(points):
        point = Vector(point)
        if index == 0:
            tangent = Vector(points[1]) - point
        elif index == len(points) - 1:
            tangent = point - Vector(points[index - 1])
        else:
            tangent = Vector(points[index + 1]) - Vector(points[index - 1])
        tangent.z = 0.0
        tangent.normalize()
        normal = Vector((-tangent.y, tangent.x, 0.0))
        half_chord = chord_widths[index] * 0.5
        half_height = thicknesses[index] * 0.5
        vertices.extend((
            point + normal * half_chord + Vector((0, 0, half_height)),
            point - normal * half_chord + Vector((0, 0, half_height)),
            point - normal * half_chord - Vector((0, 0, half_height)),
            point + normal * half_chord - Vector((0, 0, half_height)),
        ))
    faces = [(0, 3, 2, 1)]
    for index in range(len(points) - 1):
        a = index * 4
        b = (index + 1) * 4
        faces.extend(((a, a + 1, b + 1, b), (a + 1, a + 2, b + 2, b + 1), (a + 2, a + 3, b + 3, b + 2), (a + 3, a, b, b + 3)))
    end = (len(points) - 1) * 4
    faces.append((end, end + 1, end + 2, end + 3))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.data.materials.append(mat)
    bevel(obj, edge, 2)
    return obj


def string_part(coll, name, points, mat, thickness=0.0035):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
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


def add_wrapping(coll, prefix, center_y, z, width, radius, mat, turns=4):
    for index in range(turns):
        x = (index - (turns - 1) * 0.5) * width / max(turns - 1, 1)
        bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=0.003, major_segments=10, minor_segments=4, location=(x, center_y, z), rotation=(0.0, math.pi / 2, 0.0))
        obj = bpy.context.object
        obj.name = f"{prefix}_Lashing_{index}"
        obj.data.materials.append(mat)
        move_to_collection(obj, coll)


def build_crossbow(name, tier, spec, mats):
    coll = new_collection(name)
    wood, dark_wood, metal, cord, _leather = mats
    rear = spec["rear"]
    nose = spec["nose"]
    bow_y = spec["bow_y"]
    half_width = spec["width"] * 0.5

    # A low, continuous tiller avoids the large pistol grip/action mass that
    # visually merged with the character torso in the rifle aiming animation.
    stock_mat = metal if tier == 3 else wood
    trim_mat = dark_wood if tier == 1 else metal
    # Vanilla JS_2000_Sawn support-hand geometry is only about 0.016 m wide
    # and occupies Z 0.001..0.034. Keep the shoulder/action end full, then
    # lift and narrow the continuous tiller before it reaches the support hand.
    tiller_sections = (
        (-rear, spec["stock_width"], -0.030, 0.020),
        (-0.018, spec["stock_width"], -0.027, 0.027),
        (0.045, spec["stock_width"] - 0.002, -0.017, 0.029),
        (0.072, spec["body_width"], 0.002, 0.030),
        (0.150, spec["body_width"], 0.004, 0.028),
        (nose, spec["body_width"], 0.006, 0.021),
    )
    tapered_tiller(coll, f"{name}_Tiller", tiller_sections, stock_mat, edge=0.003)
    cube_part(coll, f"{name}_ButtCap", (0, -rear + 0.006, -0.003), (spec["stock_width"] + 0.004, 0.012, 0.046), dark_wood, edge=0.0025)

    rail_start = 0.020
    rail_end = nose + 0.006
    cube_part(coll, f"{name}_BoltRail", (0, (rail_start + rail_end) * 0.5, 0.035), (spec["rail_width"], rail_end - rail_start, 0.010), trim_mat, edge=0.0015)
    cube_part(coll, f"{name}_Lock", (0, 0.010, 0.029), (spec["lock_width"], 0.046, 0.014), trim_mat, edge=0.002)
    cube_part(coll, f"{name}_Trigger", (0, 0.006, -0.030), (0.006, 0.014, 0.014), metal, rotation=(math.radians(-12), 0, 0), edge=0.001)
    # Keep the prod collar subordinate to the limbs. The previous deep block
    # interrupted the bow silhouette and made the center resemble a clamp.
    cube_part(coll, f"{name}_ProdSocket", (0, bow_y + 0.002, 0.029), (spec["stock_width"] + 0.018, 0.038, 0.034), trim_mat, edge=0.003)

    limb_mat = wood if tier == 1 else metal
    curve = spec["curve"]
    # A single monotonic sweep reads as a traditional crossbow prod from the
    # isometric game camera. Avoid a reversed final segment: at game scale it
    # looked like a hook or an open pair of pincers.
    positive = tuple(
        (half_width * fraction, bow_y + curve * sweep, 0.034)
        for fraction, sweep in (
            (0.00, 0.10),
            (0.18, 0.07),
            (0.38, 0.00),
            (0.58, -0.10),
            (0.77, -0.22),
            (0.91, -0.34),
            (1.00, -0.42),
        )
    )
    negative = tuple((-x, y, z) for x, y, z in positive)
    chord = spec["limb_chord"]
    height = spec["limb_height"]
    # `limb_chord` controls only the prod's front-to-back width in top view.
    # Keep span, sweep, and vertical thickness independent so the prod reads
    # as a narrow curved band without shrinking the complete weapon.
    chord_widths = tuple(chord * factor for factor in (1.00, 0.96, 0.88, 0.76, 0.63, 0.52, 0.40))
    thicknesses = tuple(height * factor for factor in (1.00, 0.98, 0.93, 0.84, 0.73, 0.62, 0.50))
    curved_limb(coll, f"{name}_Limb_R", positive, chord_widths, thicknesses, limb_mat)
    curved_limb(coll, f"{name}_Limb_L", negative, chord_widths, thicknesses, limb_mat)

    right_tip = positive[-1]
    left_tip = negative[-1]
    latch = (0.0, 0.035, 0.042)
    string_part(coll, f"{name}_String", (left_tip, latch, right_tip), cord, spec["string_thickness"])

    if tier == 1:
        cube_part(coll, f"{name}_ProdBinding", (0, bow_y - 0.004, 0.029), (spec["stock_width"] + 0.022, 0.010, 0.038), cord, edge=0.002)
    elif tier == 2:
        cube_part(coll, f"{name}_ProdBand", (0, bow_y - 0.004, 0.029), (spec["stock_width"] + 0.022, 0.010, 0.038), metal, edge=0.002)
    # The top tier is intentionally mechanism-free. Its heavier silhouette
    # comes from the iron tiller and thicker steel prod alone.

    return coll


def build_bolt(name, broken, mats):
    wood, dark_wood, metal, cord, leather = mats
    coll = new_collection(name)
    if not broken:
        # A short, heavy quarrel silhouette matches the compact crossbows and
        # stays legible both as a 128 px icon and as a single placed world item.
        # The old square-prism "head" read as a blunt cap, while its two broad
        # overlapping fletchings merged into one rectangular block.
        cylinder_part(coll, f"{name}_Shaft", (0, -0.010, 0), 0.006, 0.210, wood, vertices=10)

        # Low-poly bodkin point with a separate socket/collar.  The point faces
        # +Y, the same direction as the crossbows' rails and muzzles.
        cylinder_part(coll, f"{name}_HeadSocket", (0, 0.088, 0), 0.009, 0.028, metal, vertices=8)
        cone_part(coll, f"{name}_BodkinPoint", (0, 0.130, 0), 0.015, 0.070, metal, vertices=4)

        # Three slim radial vanes form a recognisable feather silhouette without
        # making the bolt wider than the crossbow rail.  One vane sits uppermost;
        # the other two give the placed model stable, visible ground contact.
        vane_profile = (
            (-0.110, 0.005),
            (-0.102, 0.018),
            (-0.066, 0.014),
            (-0.050, 0.005),
        )
        for index, angle in enumerate((0.0, 120.0, 240.0), start=1):
            vane = profile_prism(coll, f"{name}_Fletching_{index}", vane_profile, 0.003, leather, edge=0.0007)
            vane.rotation_euler.y = math.radians(angle)

        # Dark rear nock and two cord whippings visually separate the tail from
        # the shaft when the asset is reduced to inventory scale.
        cylinder_part(coll, f"{name}_Nock", (0, -0.115, 0), 0.0075, 0.014, dark_wood, vertices=10)
        cylinder_part(coll, f"{name}_FletchingWrapRear", (0, -0.104, 0), 0.0068, 0.007, cord, vertices=10)
        cylinder_part(coll, f"{name}_FletchingWrapFront", (0, -0.048, 0), 0.0068, 0.008, cord, vertices=10)
    else:
        length = 0.18
        cylinder_part(coll, f"{name}_Shaft", (0, 0, 0), 0.008, length, wood, vertices=10)
        beam_between(coll, f"{name}_Splinter", (0.010, -0.035, 0), (0.035, -0.095, 0.005), 0.009, 0.009, wood, edge=0.001)
    return coll


def build_bolt_component_icons(mats):
    """Build icon-only geometry for the two crafting components."""
    wood, dark_wood, metal, cord, _leather = mats

    shaft = new_collection("AuxiliaBoltShaft")
    cylinder_part(shaft, "AuxiliaBoltShaft_Shaft", (0, 0, 0), 0.009, 0.30, wood, vertices=10)
    cylinder_part(shaft, "AuxiliaBoltShaft_Nock", (0, -0.142, 0), 0.0115, 0.020, dark_wood, vertices=10)
    cylinder_part(shaft, "AuxiliaBoltShaft_Wrap", (0, 0.105, 0), 0.011, 0.018, cord, vertices=10)

    head = new_collection("AuxiliaBoltHead")
    cone_part(head, "AuxiliaBoltHead_Point", (0, 0.025, 0), 0.042, 0.105, metal, vertices=4)
    cylinder_part(head, "AuxiliaBoltHead_Tang", (0, -0.050, 0), 0.009, 0.070, metal, vertices=8)
    return shaft, head


def collection_objects(coll):
    result = list(coll.objects)
    for child in coll.children:
        result.extend(collection_objects(child))
    return result


def apply_modifiers_and_transforms(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if obj.type != "MESH":
        bpy.ops.object.convert(target="MESH")
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)


def assign_palette_uv(obj):
    uv_layer = obj.data.uv_layers.get("UVMap") or obj.data.uv_layers.new(name="UVMap")
    coords = [vertex.co for vertex in obj.data.vertices]
    min_x = min(co.x for co in coords)
    max_x = max(co.x for co in coords)
    min_y = min(co.y for co in coords)
    max_y = max(co.y for co in coords)
    size_x = max(max_x - min_x, 1e-6)
    size_y = max(max_y - min_y, 1e-6)
    for polygon in obj.data.polygons:
        mat = obj.data.materials[polygon.material_index]
        u0, u1, v0, v1 = SWATCHES[mat.name]
        margin = 0.035
        for loop_index in polygon.loop_indices:
            co = obj.data.vertices[obj.data.loops[loop_index].vertex_index].co
            u = u0 + margin + ((co.x - min_x) / size_x) * (u1 - u0 - margin * 2)
            v = v0 + margin + ((co.y - min_y) / size_y) * (v1 - v0 - margin * 2)
            uv_layer.data[loop_index].uv = (u, v)


def collapse_game_materials(obj):
    """Keep one FBX material while preserving per-face colors in the UV atlas.

    Project Zomboid's static weapon path expects the same single-material layout
    used by the vanilla firearm meshes.  Multiple FBX material slots can make
    every face outside slot zero disappear in game even though Blender renders
    the export correctly.  UVs have already encoded each face's palette swatch,
    so all polygons can safely share one material here.
    """
    if not obj.data.materials:
        raise RuntimeError(f"{obj.name}: expected at least one material")
    game_material = obj.data.materials[0]
    for polygon in obj.data.polygons:
        polygon.material_index = 0
    obj.data.materials.clear()
    obj.data.materials.append(game_material)


def finalize_collection(coll):
    objects = [obj for obj in collection_objects(coll) if obj.type in {"MESH", "CURVE"}]
    if not objects:
        raise RuntimeError(f"No geometry in {coll.name}")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        apply_modifiers_and_transforms(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.object
    joined.name = coll.name
    joined.data.name = f"{coll.name}Mesh"
    assign_palette_uv(joined)
    collapse_game_materials(joined)
    triangulate = joined.modifiers.new("Game triangulation", "TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    joined.data.validate(verbose=True)
    joined.data.update()
    return joined


def object_bounds(obj):
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
    maximum = Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
    return minimum, maximum


def apply_gameplay_fit(obj, scale, offset):
    """Fit equipped models to the vanilla sawn-off shotgun hand envelope."""
    scale = Vector(scale)
    offset = Vector(offset)
    for vertex in obj.data.vertices:
        vertex.co.x = vertex.co.x * scale.x + offset.x
        vertex.co.y = vertex.co.y * scale.y + offset.y
        vertex.co.z = vertex.co.z * scale.z + offset.z
    obj.data.update()


def export_object(obj, filename):
    # Blender's FBX metadata restores the authored +Y-forward/Z-up direction
    # when imported back into Blender, but Project Zomboid consumes both axes
    # reversed.  Bake a half turn around X into the game copy so the prod/muzzle
    # points away from the character while the grip remains below the rail.
    # Work on a copy to keep icons and source previews in authored orientation.
    game_obj = obj.copy()
    game_obj.data = obj.data.copy()
    bpy.context.scene.collection.objects.link(game_obj)
    game_obj.name = f"{obj.name}_GameExport"
    game_obj.rotation_euler.x += math.pi
    bpy.ops.object.select_all(action="DESELECT")
    game_obj.select_set(True)
    bpy.context.view_layer.objects.active = game_obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    # PZ consumes the FBX vertex axes directly for static weapon meshes. Keep
    # Blender's native -Y-forward/Z-up basis so X=width, Y=weapon length and
    # Z=height remain unchanged in game.
    bpy.ops.export_scene.fbx(filepath=os.path.join(MODEL_DIR, f"{filename}.fbx"), use_selection=True, object_types={"MESH"}, global_scale=1.0, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE", use_space_transform=True, bake_space_transform=False, axis_forward="-Y", axis_up="Z", add_leaf_bones=False, bake_anim=False, path_mode="STRIP")
    game_mesh = game_obj.data
    bpy.data.objects.remove(game_obj, do_unlink=True)
    bpy.data.meshes.remove(game_mesh)


def make_palette_texture(filename):
    width = height = 128
    # Vanilla wood-stock firearms cluster around sRGB 121/58/7, with dark
    # walnut shadows around 80/35/10 and neutral gunmetal around 60/62/64.
    colors = {"Aged Oak": (0.475, 0.225, 0.028), "Dark Stock": (0.31, 0.14, 0.040), "Forged Iron": (0.22, 0.24, 0.25), "Hemp Cord": (0.28, 0.20, 0.08), "Leather": (0.32, 0.105, 0.035)}
    pixels = []
    for y in range(height):
        v = y / (height - 1)
        for x in range(width):
            u = x / (width - 1)
            swatch_name = "Dark Stock"
            for name, (u0, u1, v0, v1) in SWATCHES.items():
                if u0 <= u <= u1 and v0 <= v <= v1:
                    swatch_name = name
                    break
            base = colors[swatch_name]
            grain = (((x * 17 + y * 11) % 19) - 9) / 420.0
            if swatch_name in {"Aged Oak", "Dark Stock", "Leather"}:
                grain += math.sin(y * 0.42 + x * 0.06) * 0.018
            if swatch_name == "Forged Iron":
                grain += (((x * 5 + y * 3) % 7) - 3) / 600.0
            pixels.extend((max(0, min(1, base[0] + grain)), max(0, min(1, base[1] + grain)), max(0, min(1, base[2] + grain)), 1.0))
    image = bpy.data.images.new(filename, width=width, height=height, alpha=True)
    image.pixels = pixels
    image.filepath_raw = os.path.join(MODEL_TEXTURE_DIR, f"{filename}.png")
    image.file_format = "PNG"
    image.save()


def apply_palette_to_preview_materials(image):
    """Render with the same atlas/UV path the game uses, not diffuse colors alone."""
    for mat in (WOOD, DARK_WOOD, METAL, CORD, LEATHER):
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        principled = nodes.get("Principled BSDF")
        texture = nodes.get("Game palette") or nodes.new("ShaderNodeTexImage")
        texture.name = "Game palette"
        texture.label = "Project Zomboid texture atlas"
        texture.image = image
        links.new(texture.outputs["Color"], principled.inputs["Base Color"])


def look_at(obj, point=(0, 0, 0)):
    direction = Vector(point) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_render():
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.object.camera_add(location=(0.85, -0.90, 0.72))
    camera = bpy.context.object
    camera.name = "AssetCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 0.92
    look_at(camera, (0, 0.10, 0.015))
    scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(0.65, -0.55, 1.20))
    key = bpy.context.object
    key.name = "AssetKey"
    key.data.energy = 560
    key.data.shape = "DISK"
    key.data.size = 1.6
    look_at(key, (0, 0.10, 0))
    bpy.ops.object.light_add(type="AREA", location=(-0.90, 0.45, 0.65))
    fill = bpy.context.object
    fill.name = "AssetFill"
    fill.data.energy = 220
    fill.data.size = 1.5
    look_at(fill, (0, 0.10, 0))
    scene.render.use_freestyle = False
    freestyle = scene.view_layers[0].freestyle_settings.linesets[0].linestyle
    freestyle.color = (0.028, 0.018, 0.012)
    freestyle.alpha = 0.90
    freestyle.thickness = 1.05
    return camera


def set_visible(target, asset_collections):
    for coll in asset_collections:
        coll.hide_render = coll is not target


def render_icon(coll, asset_collections, filename, camera, scale, target=(0, 0.10, 0.015)):
    scene = bpy.context.scene
    set_visible(coll, asset_collections)
    scene.render.film_transparent = True
    scene.render.use_freestyle = True
    scene.render.resolution_x = 128
    scene.render.resolution_y = 128
    camera.data.ortho_scale = scale
    camera.location = (0.75, -0.82, 0.68)
    look_at(camera, target)
    scene.render.filepath = os.path.join(ITEM_TEXTURE_DIR, f"Item_{filename}.png")
    bpy.ops.render.render(write_still=True)


def render_validation(coll, asset_collections, filename, camera):
    scene = bpy.context.scene
    set_visible(coll, asset_collections)
    scene.render.film_transparent = False
    scene.render.use_freestyle = False
    scene.world.color = (0.012, 0.016, 0.014)
    scene.render.resolution_x = 640
    scene.render.resolution_y = 480
    scales = {
        "AuxiliaImprovisedCrossbow": (0.50, 0.42, 0.42),
        "AuxiliaReinforcedCrossbow": (0.52, 0.44, 0.42),
        "AuxiliaHeavyArbalest": (0.56, 0.48, 0.44),
    }[filename]
    views = {"iso": ((0.82, -0.84, 0.68), (0, 0.10, 0.015), scales[0]), "top": ((0.0, 0.10, 1.35), (0, 0.10, 0.0), scales[1]), "side": ((1.30, 0.10, 0.06), (0, 0.10, 0.0), scales[2])}
    for view_name, (location, target, scale) in views.items():
        camera.location = location
        camera.data.ortho_scale = scale
        look_at(camera, target)
        scene.render.filepath = os.path.join(VALIDATION_DIR, f"{filename}_{view_name}.png")
        bpy.ops.render.render(write_still=True)


def render_bolt_placement(coll, asset_collections, camera):
    """Render the intact bolt resting on a ground plane like Place Item."""
    scene = bpy.context.scene
    set_visible(coll, asset_collections)
    scene.render.film_transparent = False
    scene.render.use_freestyle = False
    scene.world.color = (0.012, 0.016, 0.014)
    scene.render.resolution_x = 640
    scene.render.resolution_y = 480

    bolt_obj = next(obj for obj in coll.objects if obj.type == "MESH")
    original_location = bolt_obj.location.copy()
    original_rotation = bolt_obj.rotation_euler.copy()
    bolt_obj.rotation_euler.z = math.radians(-28.0)
    bolt_obj.rotation_euler.y = math.radians(7.0)
    bpy.context.view_layer.update()
    minimum, _maximum = object_bounds(bolt_obj)
    bolt_obj.location.z += 0.004 - minimum.z

    bpy.ops.mesh.primitive_plane_add(size=0.70, location=(0, 0, 0))
    ground = bpy.context.object
    ground.name = "BoltPlacementGround"
    ground_mat = material("Bolt placement ground", (0.055, 0.065, 0.060), roughness=1.0)
    ground.data.materials.append(ground_mat)

    camera.location = (0.47, -0.54, 0.36)
    camera.data.ortho_scale = 0.43
    look_at(camera, (0, 0.005, 0.012))
    scene.render.filepath = os.path.join(VALIDATION_DIR, "AuxiliaCrossbowBolt_placed.png")
    bpy.ops.render.render(write_still=True)

    bpy.data.objects.remove(ground, do_unlink=True)
    bpy.data.materials.remove(ground_mat)
    bolt_obj.location = original_location
    bolt_obj.rotation_euler = original_rotation
    bpy.context.view_layer.update()


def render_promo(heavy, asset_collections, camera):
    scene = bpy.context.scene
    set_visible(heavy, asset_collections)
    scene.render.film_transparent = False
    scene.render.use_freestyle = False
    scene.world.color = (0.012, 0.016, 0.014)
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    camera.data.ortho_scale = 0.56
    camera.location = (0.82, -0.88, 0.72)
    look_at(camera, (0, 0.10, 0.015))
    poster = os.path.join(MOD_ROOT, "poster.png")
    scene.render.filepath = poster
    bpy.ops.render.render(write_still=True)
    shutil.copy2(poster, os.path.join(MOD_ROOT, "icon.png"))
    shutil.copy2(poster, os.path.join(REPO_ROOT, "workshop", "preview.png"))


def import_fbx(filepath):
    before = set(bpy.context.scene.objects)
    try:
        bpy.ops.wm.fbx_import(filepath=filepath)
    except (AttributeError, RuntimeError):
        bpy.ops.import_scene.fbx(filepath=filepath)
    return [obj for obj in bpy.context.scene.objects if obj not in before and obj.type == "MESH"]


def validate_exports(asset_objects, icon_names):
    report = {"coordinate_system": "X width, Y forward, Z up; action at origin", "assets": {}, "icons": {}}
    expected_ranges = {
        "AuxiliaImprovisedCrossbow": ((0.24, 0.27), (0.35, 0.38), (0.07, 0.10)),
        "AuxiliaReinforcedCrossbow": ((0.27, 0.30), (0.35, 0.38), (0.07, 0.10)),
        "AuxiliaHeavyArbalest": ((0.30, 0.34), (0.35, 0.38), (0.08, 0.11)),
        "AuxiliaCrossbowBolt": ((0.02, 0.04), (0.27, 0.29), (0.025, 0.045)),
    }
    for filename, original in asset_objects.items():
        source_min, source_max = object_bounds(original)
        source_dimensions = source_max - source_min
        imported = import_fbx(os.path.join(MODEL_DIR, f"{filename}.fbx"))
        if len(imported) != 1:
            raise RuntimeError(f"{filename}: expected one imported mesh, got {len(imported)}")
        if len(original.data.materials) != 1 or len(imported[0].data.materials) != 1:
            raise RuntimeError(f"{filename}: Project Zomboid exports must contain exactly one material")
        if len(imported[0].data.uv_layers) != 1:
            raise RuntimeError(f"{filename}: FBX must contain exactly one UV layer")
        if not imported[0].data.materials:
            raise RuntimeError(f"{filename}: FBX lost all material slots")
        imported_min, imported_max = object_bounds(imported[0])
        imported_dimensions = imported_max - imported_min
        delta = imported_dimensions - source_dimensions
        if max(abs(delta.x), abs(delta.y), abs(delta.z)) > 0.002:
            raise RuntimeError(f"{filename}: FBX round-trip changed dimensions by {tuple(delta)}")
        if filename in expected_ranges:
            for axis, value, limits in zip("XYZ", source_dimensions, expected_ranges[filename]):
                if not limits[0] <= value <= limits[1]:
                    raise RuntimeError(f"{filename}: {axis} dimension {value:.4f} outside {limits}")
        report["assets"][filename] = {
            "single_mesh": True,
            "vertices": len(original.data.vertices),
            "triangles": len(original.data.polygons),
            "materials": [mat.name for mat in original.data.materials],
            "uv_layers": len(original.data.uv_layers),
            "bounds_min": [round(value, 5) for value in source_min],
            "bounds_max": [round(value, 5) for value in source_max],
            "dimensions": [round(value, 5) for value in source_dimensions],
            "fbx_round_trip_dimensions": [round(value, 5) for value in imported_dimensions],
            "fbx_uv_layers": len(imported[0].data.uv_layers),
            "fbx_materials": [mat.name for mat in imported[0].data.materials],
        }
        for obj in imported:
            bpy.data.objects.remove(obj, do_unlink=True)
    for icon_name in icon_names:
        icon_path = os.path.join(ITEM_TEXTURE_DIR, f"Item_{icon_name}.png")
        icon = bpy.data.images.load(icon_path, check_existing=False)
        width, height = icon.size
        if (width, height) != (128, 128):
            raise RuntimeError(f"{icon_name}: icon must be 128x128, got {width}x{height}")
        pixels = icon.pixels[:]
        visible = []
        for index in range(width * height):
            if pixels[index * 4 + 3] >= 0.05:
                visible.append((index % width, index // width))
        if not visible:
            raise RuntimeError(f"{icon_name}: icon is fully transparent")
        xs = [point[0] for point in visible]
        ys = [point[1] for point in visible]
        bounds = (min(xs), min(ys), max(xs), max(ys))
        edge_margin = min(bounds[0], bounds[1], width - 1 - bounds[2], height - 1 - bounds[3])
        coverage = len(visible) / (width * height)
        if edge_margin < 3:
            raise RuntimeError(f"{icon_name}: icon touches the canvas edge (margin {edge_margin}px)")
        if not 0.015 <= coverage <= 0.55:
            raise RuntimeError(f"{icon_name}: visible coverage {coverage:.3f} is outside the expected range")
        report["icons"][icon_name] = {
            "size": [width, height],
            "visible_bounds": list(bounds),
            "edge_margin": edge_margin,
            "visible_coverage": round(coverage, 4),
        }
        bpy.data.images.remove(icon)
    report_path = os.path.join(VALIDATION_DIR, "report.json")
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, ensure_ascii=False, indent=2)
    return report_path


reset_scene()
WOOD = material("Aged Oak", (0.475, 0.225, 0.028), roughness=0.84)
DARK_WOOD = material("Dark Stock", (0.31, 0.14, 0.040), roughness=0.82)
METAL = material("Forged Iron", (0.22, 0.24, 0.25), metallic=0.35, roughness=0.64)
CORD = material("Hemp Cord", (0.28, 0.20, 0.08), roughness=0.95)
LEATHER = material("Leather", (0.32, 0.105, 0.035), roughness=0.88)
MATERIALS = (WOOD, DARK_WOOD, METAL, CORD, LEATHER)

SPECS = {
    "AuxiliaImprovisedCrossbow": {"rear": 0.052, "nose": 0.305, "bow_y": 0.262, "width": 0.250, "curve": 0.034, "stock_width": 0.024, "body_width": 0.016, "lock_width": 0.020, "rail_width": 0.014, "limb_chord": 0.009, "limb_height": 0.014, "string_thickness": 0.0024},
    "AuxiliaReinforcedCrossbow": {"rear": 0.052, "nose": 0.305, "bow_y": 0.262, "width": 0.280, "curve": 0.038, "stock_width": 0.026, "body_width": 0.018, "lock_width": 0.022, "rail_width": 0.016, "limb_chord": 0.010, "limb_height": 0.017, "string_thickness": 0.0027},
    "AuxiliaHeavyArbalest": {"rear": 0.052, "nose": 0.305, "bow_y": 0.262, "width": 0.315, "curve": 0.042, "stock_width": 0.028, "body_width": 0.020, "lock_width": 0.024, "rail_width": 0.018, "limb_chord": 0.012, "limb_height": 0.022, "string_thickness": 0.0032},
}

improvised = build_crossbow("AuxiliaImprovisedCrossbow", 1, SPECS["AuxiliaImprovisedCrossbow"], MATERIALS)
reinforced = build_crossbow("AuxiliaReinforcedCrossbow", 2, SPECS["AuxiliaReinforcedCrossbow"], MATERIALS)
heavy = build_crossbow("AuxiliaHeavyArbalest", 3, SPECS["AuxiliaHeavyArbalest"], MATERIALS)
bolt = build_bolt("AuxiliaCrossbowBolt", False, MATERIALS)
broken_bolt = build_bolt("AuxiliaBrokenBolt", True, MATERIALS)
bolt_shaft_icon, bolt_head_icon = build_bolt_component_icons(MATERIALS)
assets = [improvised, reinforced, heavy, bolt, broken_bolt]
icon_assets = assets + [bolt_shaft_icon, bolt_head_icon]

asset_objects = {}
for collection in assets:
    asset_objects[collection.name] = finalize_collection(collection)
for collection in (bolt_shaft_icon, bolt_head_icon):
    finalize_collection(collection)
for filename, obj in asset_objects.items():
    export_object(obj, filename)
    make_palette_texture(filename)

apply_palette_to_preview_materials(bpy.data.images["AuxiliaImprovisedCrossbow"])

camera = setup_render()
render_icon(improvised, icon_assets, "AuxiliaImprovisedCrossbow", camera, 0.48)
render_icon(reinforced, icon_assets, "AuxiliaReinforcedCrossbow", camera, 0.51)
render_icon(heavy, icon_assets, "AuxiliaHeavyArbalest", camera, 0.55)
render_icon(bolt, icon_assets, "AuxiliaCrossbowBolt", camera, 0.30, (0, 0.015, 0))
render_icon(broken_bolt, icon_assets, "AuxiliaBrokenBolt", camera, 0.30, (0, 0.00, 0))
render_icon(bolt_shaft_icon, icon_assets, "AuxiliaBoltShaft", camera, 0.38, (0, 0.00, 0))
render_icon(bolt_head_icon, icon_assets, "AuxiliaBoltHead", camera, 0.21, (0, 0.00, 0))
for collection in (improvised, reinforced, heavy):
    render_validation(collection, icon_assets, collection.name, camera)
render_bolt_placement(bolt, icon_assets, camera)
render_promo(heavy, icon_assets, camera)

# Headless Windows runs do not need an Explorer/File Browser thumbnail for the
# generated source file. Blender 5.2's automatic preview cache can misdecode
# the project path and create mojibake-named .thumbnails trees beside the repo.
bpy.context.preferences.filepaths.file_preview_type = "NONE"
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "AuxiliasCrossbowAssets.blend"))
report_path = validate_exports(asset_objects, [collection.name for collection in icon_assets])
print(f"Auxilia's Crossbow assets generated under: {VERSION_ROOT}")
print(f"Model validation report: {report_path}")
