"""Fit the four Blender press views onto Project Zomboid tabletop tiles.

Run ``source-assets/blender/render_runtime_press.py`` in Blender first. This
script writes the editable 128x256 source tiles and a 128px item icon, then
copies the 32px icon into the installable mod. ``build-press-tiles.py`` packs
the source tiles for the game.
"""

import json
from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source-assets"
TILES = SOURCE / "tiles"
RENDERS = TILES / "renders"
REPO = ROOT.parents[1]
CONFIG = json.loads((REPO / "config" / "project-zomboid.json").read_text(encoding="utf-8"))
RELEASE_LINE = CONFIG["target"]["releaseLine"]
TEXTURES = ROOT / "workshop" / "Contents" / "mods" / "AuxiliasAmmunition" / RELEASE_LINE / "media" / "textures"

DIRECTIONS = ("south", "east", "north", "west")
SPRITE_SIZE = (68, 65)  # Match the footprint of vanilla small tabletop machinery.
BOTTOM = 181  # Key Duplicator art ends near y=181 on a 128x256 tile.
ALPHA_CUTOFF = 128  # Avoid the game's checkerboard dither on translucent render edges.


def cutout(direction: str) -> Image.Image:
    image = Image.open(RENDERS / f"press_{direction}.png").convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"Empty press render: {direction}")
    return image.crop(bounds)


def brighten(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = ImageEnhance.Brightness(image.convert("RGB")).enhance(1.35)
    rgb.putalpha(alpha)
    return rgb


def fit(image: Image.Image, width: int, height: int) -> Image.Image:
    result = image.copy()
    result.thumbnail((width, height), Image.Resampling.LANCZOS)
    return result


def main() -> None:
    TILES.mkdir(parents=True, exist_ok=True)
    TEXTURES.mkdir(parents=True, exist_ok=True)
    cutouts = []
    for index, direction in enumerate(DIRECTIONS):
        cut = brighten(cutout(direction))
        cutouts.append(cut)
        sprite = fit(cut, *SPRITE_SIZE)
        tile = Image.new("RGBA", (128, 256))
        tile.alpha_composite(sprite, ((128 - sprite.width) // 2, BOTTOM - sprite.height))
        tile.putalpha(tile.getchannel("A").point(lambda alpha: 255 if alpha >= ALPHA_CUTOFF else 0))
        tile.save(TILES / f"auxammo_press_01_{index}.png")

    icon = fit(cutouts[0], 116, 116)
    master = Image.new("RGBA", (128, 128))
    master.alpha_composite(icon, ((128 - icon.width) // 2, (128 - icon.height) // 2))
    master.save(SOURCE / "icons" / "Item_AuxAmmoPress.png")
    master.resize((32, 32), Image.Resampling.LANCZOS).save(TEXTURES / "Item_AuxAmmoPress.png")
    print("Built four tabletop tiles and the ammunition press icon")


if __name__ == "__main__":
    main()
