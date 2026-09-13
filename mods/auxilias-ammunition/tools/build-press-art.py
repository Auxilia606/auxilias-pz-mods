"""Fit the four Blender press views onto Project Zomboid tabletop tiles.

Run ``source-assets/blender/render_runtime_press.py`` in Blender first. This
script writes the editable 128x256 source tiles and a 128px item icon, then
copies the 32px icon into the installable mod. ``build-press-tiles.py`` packs
the source tiles for the game.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source-assets"
TILES = SOURCE / "tiles"
RENDERS = TILES / "renders"
REPO = ROOT.parents[1]
CONFIG = json.loads((REPO / "config" / "project-zomboid.json").read_text(encoding="utf-8"))
RELEASE_LINE = CONFIG["target"]["releaseLine"]
TEXTURES = ROOT / "workshop" / "Contents" / "mods" / "AuxiliasAmmunition" / RELEASE_LINE / "media" / "textures"

DIRECTIONS = ("south", "east", "north", "west")
PIXEL_SCALE = 0.16  # One scale for every orientation; never fit each view separately.
TILE_ANCHOR = (64, 171)  # The projected center of the wooden base on a tabletop tile.
ALPHA_CUTOFF = 128  # Avoid the game's checkerboard dither on translucent render edges.


def source_render(direction: str) -> Image.Image:
    image = Image.open(RENDERS / f"press_{direction}.png").convert("RGBA")
    if image.getchannel("A").getbbox() is None:
        raise ValueError(f"Empty press render: {direction}")
    return image


def fit(image: Image.Image, width: int, height: int) -> Image.Image:
    result = image.copy()
    result.thumbnail((width, height), Image.Resampling.LANCZOS)
    return result


def main() -> None:
    TILES.mkdir(parents=True, exist_ok=True)
    TEXTURES.mkdir(parents=True, exist_ok=True)
    anchors = json.loads((RENDERS / "press_anchors.json").read_text(encoding="utf-8"))
    render_size = tuple(anchors["render_size"])
    source_images = []
    tiles = []
    for index, direction in enumerate(DIRECTIONS):
        source = source_render(direction)
        if source.size != render_size:
            raise ValueError(f"Inconsistent render size for {direction}: {source.size}")
        source_images.append(source)
        anchor_x, anchor_y = anchors["faces"][direction]["anchor_px"]
        sprite = source.resize(
            (round(source.width * PIXEL_SCALE), round(source.height * PIXEL_SCALE)),
            Image.Resampling.LANCZOS,
        )
        left = round(TILE_ANCHOR[0] - anchor_x * PIXEL_SCALE)
        top = round(TILE_ANCHOR[1] - anchor_y * PIXEL_SCALE)
        bounds = sprite.getchannel("A").getbbox()
        if bounds is None or left + bounds[0] < 0 or left + bounds[2] > 128 or top + bounds[1] < 0 or top + bounds[3] > 256:
            raise ValueError(f"Press art for {direction} leaves its 128x256 tile")
        tile = Image.new("RGBA", (128, 256))
        tile.alpha_composite(sprite, (left, top))
        tile.putalpha(tile.getchannel("A").point(lambda alpha: 255 if alpha >= ALPHA_CUTOFF else 0))
        tile.save(TILES / f"auxammo_press_01_{index}.png")
        tiles.append(tile)

    bounds = [tile.getchannel("A").getbbox() for tile in tiles]
    preview_top = max(0, min(box[1] for box in bounds) - 12)
    preview_bottom = min(256, max(box[3] for box in bounds) + 12)
    panel_height = preview_bottom - preview_top
    preview = Image.new("RGB", (4 * 144 + 16, panel_height + 40), "#ddd6c8")
    drawing = ImageDraw.Draw(preview)
    for index, (direction, tile) in enumerate(zip(DIRECTIONS, tiles)):
        x = 16 + index * 144
        drawing.text((x + 4, 8), direction.upper(), fill="#30291f")
        drawing.rectangle((x, 28, x + 127, 28 + panel_height - 1), fill="#aa9d88")
        cropped = tile.crop((0, preview_top, 128, preview_bottom))
        preview.paste(cropped, (x, 28), cropped)
    preview.save(TILES / "press_four_faces_preview.png")

    icon_source = source_images[0]
    icon = fit(icon_source.crop(icon_source.getchannel("A").getbbox()), 116, 116)
    master = Image.new("RGBA", (128, 128))
    master.alpha_composite(icon, ((128 - icon.width) // 2, (128 - icon.height) // 2))
    master.save(SOURCE / "icons" / "Item_AuxAmmoPress.png")
    master.resize((32, 32), Image.Resampling.LANCZOS).save(TEXTURES / "Item_AuxAmmoPress.png")
    print("Built four tabletop tiles and the ammunition press icon")


if __name__ == "__main__":
    main()
