"""Derive crisp 32px icons and 128px pixel masters from the authored Blender renders.

Run export-parts.py and render_runtime_press.py in Blender first. This tool only
prepares render derivatives; it never draws substitute shapes or edits 3D sources.
"""
from pathlib import Path
import json
from PIL import Image

MOD = Path(__file__).resolve().parents[1]
SOURCE = MOD/'source-assets'
IDS = ('SmallPistolBody', 'HeavyPistolBody', 'RifleBody', 'ShotgunBody',
       'MineralSalts', 'CarbonPowder', 'NitrogenousMix', 'SurvivalPropellant')


def pixel_master(path, destination):
    source = Image.open(path).convert('RGBA')
    mask = source.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError(f'Empty render: {path}')
    source = source.crop(bounds)
    source.thumbnail((28,28), Image.Resampling.LANCZOS)
    alpha = source.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    # A compact palette and opaque clusters match the inspected native sprites.
    source = source.convert('RGB').quantize(colors=24, method=Image.Quantize.MEDIANCUT,
                                           dither=Image.Dither.NONE).convert('RGBA')
    source.putalpha(alpha)
    icon = Image.new('RGBA',(32,32))
    icon.alpha_composite(source,((32-source.width)//2,(32-source.height)//2))
    icon.resize((128,128),Image.Resampling.NEAREST).save(destination)
    return {'render': str(path.relative_to(MOD)), 'bounds': icon.getchannel('A').getbbox(),
            'visible_colors': len({p[:3] for p in icon.getdata() if p[3]}), 'alpha': [0,255]}


def main():
    icons = {f'AuxAmmo{name}': SOURCE/f'blender/previews/parts/{name}_iso.png' for name in IDS}
    icons['AuxAmmoPress'] = SOURCE/'tiles/renders/press_south.png'
    report = {}
    for name, source in icons.items():
        report[name] = pixel_master(source,SOURCE/f'icons/Item_{name}.png')
    (SOURCE/'icons/render-sources.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('Prepared nine pixel masters from the authored 3D renders; run sync-icons.ps1.')


if __name__ == '__main__':
    main()
