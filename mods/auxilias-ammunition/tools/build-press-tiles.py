"""Build the four-facing tabletop press tile assets for Project Zomboid 42.

Source cells are 128x256 RGBA PNGs named auxammo_press_01_0.png through
auxammo_press_01_3.png (south, east, north, west). The output uses the same
PZPK v1 and tdef v1 formats as the installed Build 42.20 game assets.

The ``tiledef=auxammo_press_01 7713`` value belongs in mod.info. It is a
namespace number for the mod and is distinct from the tileset's internal id=1.
Changing either after release would break placed sprites in existing saves.
"""

from __future__ import annotations

import argparse
import io
import json
import struct
from pathlib import Path

from PIL import Image


MOD_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = Path(__file__).resolve().parents[3]
TILESET = "auxammo_press_01"
CELL_SIZE = (128, 256)
FACES = ("S", "E", "N", "W")
TILEDEF_NUMBER = 7713  # Registration in mod.info; not the binary tileset id.
TILESET_ID = 1


def default_media_dir() -> Path:
    config = json.loads((REPO_ROOT / "config/project-zomboid.json").read_text(encoding="utf-8"))
    release_line = config["target"]["releaseLine"]
    return MOD_ROOT / "workshop/Contents/mods/AuxiliasAmmunition" / release_line / "media"


def u32(value: int) -> bytes:
    return struct.pack("<I", value)


def length_string(value: str) -> bytes:
    encoded = value.encode("utf-8")
    return u32(len(encoded)) + encoded


def line_string(value: str) -> bytes:
    if "\n" in value:
        raise ValueError("tdef strings cannot contain newlines")
    return value.encode("utf-8") + b"\n"


def tile_properties(face: str) -> tuple[tuple[str, str], ...]:
    """Mirror vanilla Key Duplicator's tabletop moveable properties."""
    return (
        ("BlocksPlacement", ""),
        ("CustomItem", "AuxiliasAmmunition.Mov_AmmoPress"),
        ("CustomName", "Press"),
        ("Facing", face),
        ("GenericCraftingSurface", "false"),
        ("GroupName", "Ammo"),
        ("IsMoveAble", ""),
        ("IsSurfaceOffset", ""),
        ("IsTableTop", ""),
        ("Material", "Mechanical"),
        ("PickUpWeight", "200"),
        ("ScrapSize", "Small"),
        ("Surface", "31"),
    )


def read_cells(source_dir: Path) -> list[Image.Image]:
    cells = []
    for index in range(len(FACES)):
        path = source_dir / f"{TILESET}_{index}.png"
        with Image.open(path) as original:
            if original.size != CELL_SIZE:
                raise ValueError(f"{path}: expected {CELL_SIZE}, got {original.size}")
            cell = original.convert("RGBA")
        if cell.getchannel("A").getbbox() is None:
            raise ValueError(f"{path}: fully transparent tile")
        cells.append(cell)
    return cells


def make_pack(cells: list[Image.Image]) -> bytes:
    """Pack one 4x1 atlas, keeping each cell's original 128x256 anchor."""
    atlas = Image.new("RGBA", (CELL_SIZE[0] * len(cells), CELL_SIZE[1]))
    entries = []
    for index, cell in enumerate(cells):
        cell_left = index * CELL_SIZE[0]
        atlas.alpha_composite(cell, (cell_left, 0))
        left, top, right, bottom = cell.getchannel("A").getbbox()
        entries.append(
            (
                f"{TILESET}_{index}",
                (cell_left + left, top, right - left, bottom - top, left, top, *CELL_SIZE),
            )
        )

    stream = io.BytesIO()
    atlas.save(stream, format="PNG")
    png = stream.getvalue()

    pack = io.BytesIO()
    pack.write(b"PZPK")
    pack.write(u32(1))  # Format version.
    pack.write(u32(1))  # Atlas page count.
    pack.write(length_string(TILESET))
    pack.write(u32(len(entries)))
    pack.write(u32(1))  # B42 page field, as in vanilla Tiles2x.pack.
    for name, values in entries:
        pack.write(length_string(name))
        pack.write(struct.pack("<8I", *values))
    pack.write(u32(len(png)))
    pack.write(png)
    return pack.getvalue()


def make_tiles() -> bytes:
    tiles = io.BytesIO()
    tiles.write(b"tdef")
    tiles.write(u32(1))  # Format version.
    tiles.write(u32(1))  # Tileset count.
    tiles.write(line_string(TILESET))
    tiles.write(line_string(f"{TILESET}.png"))
    tiles.write(struct.pack("<4I", len(FACES), 1, TILESET_ID, len(FACES)))
    for face in FACES:
        properties = tile_properties(face)
        tiles.write(u32(len(properties)))
        for key, value in properties:
            tiles.write(line_string(key))
            tiles.write(line_string(value))
    return tiles.getvalue()


def make_tiles_text() -> str:
    lines = [
        "version = 1",
        "tileset",
        "{",
        f"    file = {TILESET}",
        f"    size = {len(FACES)},1",
        f"    id = {TILESET_ID}",
    ]
    for index, face in enumerate(FACES):
        lines.extend((f"    // {TILESET}_{index}", "    tile", "    {", f"        xy = {index},0"))
        lines.extend(
            f"        {key} = {value}" if value else f"        {key} ="
            for key, value in tile_properties(face)
        )
        lines.append("    }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=MOD_ROOT / "source-assets/tiles")
    parser.add_argument("--media-dir", type=Path, default=default_media_dir())
    args = parser.parse_args()

    cells = read_cells(args.source_dir)
    pack = make_pack(cells)
    tiles = make_tiles()
    tiles_text = make_tiles_text()

    (args.media_dir / "texturepacks").mkdir(parents=True, exist_ok=True)
    (args.media_dir / "texturepacks" / f"{TILESET}.pack").write_bytes(pack)
    (args.media_dir / f"{TILESET}.tiles").write_bytes(tiles)
    (args.media_dir / f"{TILESET}.tiles.txt").write_text(tiles_text, encoding="utf-8", newline="\n")
    print(
        f"Wrote {TILESET}: 4 tabletop tiles, {len(pack)}-byte PZPK, "
        f"{len(tiles)}-byte tdef; mod.info needs pack={TILESET} and "
        f"tiledef={TILESET} {TILEDEF_NUMBER}"
    )


if __name__ == "__main__":
    main()
