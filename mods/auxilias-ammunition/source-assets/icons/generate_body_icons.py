"""Draw distinct ammunition-body and powder-component icon masters.

The six 128px PNGs produced here are source assets. Run the repository's
sync-icons tool afterwards to generate the 32px Workshop textures.
"""

from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent
SCALE = 4
CANVAS = 128 * SCALE


def px(value):
    return round(value * SCALE)


def rect(values):
    return tuple(px(value) for value in values)


def points(values):
    return [(px(x), px(y)) for x, y in values]


def shaded_fill(mask, light, mid, dark, seed):
    """A warm left-hand highlight with subtle deterministic surface grain."""
    rng = random.Random(seed)
    image = Image.new("RGBA", (CANVAS, CANVAS))
    pixels = image.load()
    for y in range(CANVAS):
        for x in range(CANVAS):
            u = x / CANVAS
            v = y / CANVAS
            if u < 0.45:
                start, end, t = light, mid, u / 0.45
            else:
                start, end, t = mid, dark, (u - 0.45) / 0.55
            grain = rng.randint(-5, 5)
            wear = 3 * math.sin(v * 43 + u * 17)
            pixels[x, y] = tuple(
                max(0, min(255, round(start[i] * (1 - t) + end[i] * t + grain + wear)))
                for i in range(3)
            ) + (255,)
    image.putalpha(mask)
    return image


def draw_body(kind, width, body_top, body_bottom, tip_top, tip_shape, rotation):
    image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(rect((39, 103, 98, 119)), fill=(9, 6, 5, 90))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(px(4))))

    left, right = 64 - width / 2, 64 + width / 2
    mask = Image.new("L", image.size)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        rect((left, body_top, right, body_bottom)), radius=px(4), fill=255
    )
    casing = shaded_fill(mask, (229, 158, 70), (161, 91, 38), (64, 38, 25), 12 + width)
    image.alpha_composite(casing)
    d = ImageDraw.Draw(image)
    d.rounded_rectangle(
        rect((left, body_top, right, body_bottom)),
        radius=px(4), outline=(43, 25, 18, 255), width=px(2),
    )
    # One broad glint and several fine scratches keep the metal readable at 32px.
    d.line(points(((left + 5, body_top + 7), (left + 5, body_bottom - 12))),
           fill=(251, 198, 103, 185), width=px(2))
    d.line(points(((left + 9, body_top + 11), (left + 9, body_bottom - 20))),
           fill=(245, 173, 82, 110), width=px(1))
    rng = random.Random(40 + width)
    for _ in range(12):
        x = rng.uniform(left + 6, right - 6)
        y = rng.uniform(body_top + 13, body_bottom - 13)
        d.line(points(((x, y), (x + rng.uniform(2, 6), y - 0.5))),
               fill=(58, 38, 27, 85), width=px(1))

    # Dark neck band visually separates the inserted projectile from the casing.
    d.rectangle(rect((left + 1, body_top + 1, right - 1, body_top + 5)),
                fill=(53, 31, 25, 255))
    d.line(points(((left + 2, body_top + 6), (right - 2, body_top + 6))),
           fill=(255, 190, 98, 220), width=px(1))

    bullet_mask = Image.new("L", image.size)
    bullet_draw = ImageDraw.Draw(bullet_mask)
    bullet_draw.polygon(points(tip_shape), fill=255)
    bullet = shaded_fill(bullet_mask, (205, 151, 108), (116, 81, 68), (48, 45, 47), 65 + width)
    image.alpha_composite(bullet)
    d = ImageDraw.Draw(image)
    d.line(points(tip_shape + [tip_shape[0]]), fill=(44, 34, 35, 255), width=px(2))
    d.line(points(((left + 6, tip_top + 8), (left + 8, body_top - 4))),
           fill=(242, 190, 138, 165), width=px(2))

    # A plain closed base keeps the unfinished body distinct without a separate primer detail.
    d.ellipse(rect((left - 2, body_bottom - 7, right + 2, body_bottom + 5)),
              fill=(129, 72, 35, 255), outline=(41, 25, 20, 255), width=px(2))
    d.arc(rect((left + 3, body_bottom - 5, right - 3, body_bottom + 1)),
          182, 355, fill=(248, 175, 81, 215), width=px(1))

    image = image.rotate(rotation, resample=Image.Resampling.BICUBIC)
    return image.resize((128, 128), Image.Resampling.LANCZOS)


def draw_shotgun_body():
    image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    shadow = Image.new("RGBA", image.size)
    ImageDraw.Draw(shadow).ellipse(rect((30, 105, 101, 120)), fill=(5, 5, 6, 90))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(px(4))))
    d = ImageDraw.Draw(image)
    hull = Image.new("L", image.size)
    ImageDraw.Draw(hull).rounded_rectangle(rect((45, 36, 84, 104)), radius=px(5), fill=255)
    image.alpha_composite(shaded_fill(hull, (186, 69, 50), (123, 44, 37), (64, 32, 31), 181))
    d = ImageDraw.Draw(image)
    d.rounded_rectangle(rect((45, 36, 84, 104)), radius=px(5),
                        outline=(48, 27, 25, 255), width=px(2))
    d.line(points(((51, 43), (51, 89))), fill=(237, 116, 79, 175), width=px(2))
    d.line(points(((76, 43), (76, 89))), fill=(67, 28, 27, 175), width=px(2))
    # The open mouth and visible shot identify the paired charge and hull.
    d.ellipse(rect((44, 29, 85, 46)), fill=(34, 27, 27, 255),
              outline=(231, 110, 70, 255), width=px(3))
    for x, y, radius in ((55, 35, 5), (65, 33, 5), (75, 36, 5), (61, 40, 4), (70, 40, 4)):
        d.ellipse(rect((x - radius, y - radius, x + radius, y + radius)),
                  fill=(100, 103, 99, 255), outline=(35, 35, 37, 255), width=px(1))
        d.ellipse(rect((x - radius + 1, y - radius + 1, x, y)),
                  fill=(198, 183, 146, 205))
    d.rectangle(rect((45, 88, 84, 103)), fill=(158, 97, 45, 255),
                outline=(46, 28, 23, 255), width=px(2))
    d.line(points(((49, 91), (80, 91))), fill=(244, 182, 91, 215), width=px(2))
    d.ellipse(rect((43, 100, 86, 112)), fill=(122, 72, 35, 255),
              outline=(42, 27, 23, 255), width=px(2))
    image = image.rotate(27, resample=Image.Resampling.BICUBIC)
    return image.resize((128, 128), Image.Resampling.LANCZOS)


def draw_carbon_powder():
    image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    d.ellipse(rect((18, 93, 111, 116)), fill=(14, 12, 12, 95))
    rng = random.Random(804)
    fragments = [
        (20, 91, 40, 106), (32, 77, 53, 102), (46, 66, 69, 102),
        (62, 74, 88, 104), (80, 83, 109, 105), (39, 90, 64, 110),
        (63, 91, 91, 111), (51, 53, 68, 81), (69, 63, 87, 91),
    ]
    for i, (left, top, right, bottom) in enumerate(fragments):
        inset = rng.randint(3, 7)
        polygon = [
            (left + inset, top), (right - 5, top + 2), (right, top + inset),
            (right - 1, bottom - 4), (right - inset, bottom),
            (left + 4, bottom - 1), (left, bottom - inset),
        ]
        tones = [(108, 98, 88), (78, 76, 75), (122, 105, 87), (91, 87, 82)]
        d.polygon(points(polygon), fill=(*tones[i % len(tones)], 255))
        d.line(points(polygon + [polygon[0]]), fill=(28, 27, 27, 255), width=px(2))
        d.line(points(((left + inset + 2, top + 3), (right - 9, top + 5))),
               fill=(207, 170, 125, 205), width=px(2))
        d.line(points(((left + 4, bottom - 5), (right - 4, bottom - 7))),
               fill=(20, 20, 21, 140), width=px(2))
    for _ in range(24):
        x = rng.randrange(21, 109)
        y = rng.randrange(75, 111)
        radius = rng.choice((1, 2, 2))
        d.ellipse(rect((x - radius, y - radius, x + radius, y + radius)),
                  fill=rng.choice(((180, 149, 111, 225), (56, 55, 55, 235),
                                   (191, 132, 72, 185))))
    return image.resize((128, 128), Image.Resampling.LANCZOS)


def draw_nitrogenous_mix():
    """An olive granular mixture in a shallow bowl, distinct from both powder piles."""
    image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    d.ellipse(rect((23, 99, 110, 118)), fill=(12, 12, 10, 90))
    d.ellipse(rect((23, 64, 105, 108)), fill=(82, 51, 35, 255),
              outline=(35, 29, 25, 255), width=px(3))
    d.ellipse(rect((29, 68, 99, 94)), fill=(37, 34, 29, 255),
              outline=(177, 116, 65, 255), width=px(2))

    mound = Image.new("L", image.size)
    ImageDraw.Draw(mound).polygon(points([
        (31, 83), (38, 71), (47, 65), (54, 53), (69, 57),
        (77, 65), (90, 69), (98, 82), (92, 91), (37, 91),
    ]), fill=255)
    image.alpha_composite(shaded_fill(
        mound, (181, 175, 108), (111, 113, 67), (54, 64, 48), 921,
    ))
    d = ImageDraw.Draw(image)
    d.line(points(((34, 81), (44, 69), (55, 62), (69, 64))),
           fill=(223, 202, 124, 190), width=px(2))
    rng = random.Random(921)
    for _ in range(55):
        x = rng.randrange(36, 95)
        y = rng.randrange(68, 91)
        if mound.getpixel((px(x), px(y))) == 0:
            continue
        radius = rng.choice((1, 1, 2))
        d.ellipse(rect((x - radius, y - radius, x + radius, y + radius)),
                  fill=rng.choice(((48, 54, 37, 245), (213, 183, 111, 230),
                                   (139, 103, 61, 235))))

    d.arc(rect((24, 69, 104, 109)), 4, 177,
          fill=(30, 25, 22, 255), width=px(5))
    d.arc(rect((28, 71, 100, 105)), 8, 171,
          fill=(202, 137, 73, 230), width=px(3))
    d.arc(rect((32, 77, 96, 102)), 10, 170,
          fill=(103, 64, 40, 230), width=px(2))
    return image.resize((128, 128), Image.Resampling.LANCZOS)


def main():
    icons = {
        "AuxAmmoSmallPistolBody": draw_body(
            "small", 27, 45, 104, 18,
            [(52, 48), (51, 35), (53, 26), (59, 19), (69, 19), (76, 27),
             (77, 39), (76, 48)], 27,
        ),
        "AuxAmmoHeavyPistolBody": draw_body(
            "heavy", 35, 44, 106, 23,
            [(48, 48), (49, 30), (54, 24), (74, 24), (79, 31), (80, 48)], -25,
        ),
        "AuxAmmoRifleBody": draw_body(
            "rifle", 22, 52, 112, 11,
            [(55, 55), (55, 39), (60, 22), (64, 11), (68, 22), (73, 39),
             (73, 55)], 29,
        ),
        "AuxAmmoShotgunBody": draw_shotgun_body(),
        "AuxAmmoCarbonPowder": draw_carbon_powder(),
        "AuxAmmoNitrogenousMix": draw_nitrogenous_mix(),
    }
    for name, icon in icons.items():
        icon.save(ROOT / f"Item_{name}.png")


if __name__ == "__main__":
    main()
