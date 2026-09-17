"""Compatibility entry point: export the authored .blend without regenerating it.

Geometry, UVs and the packed atlas are edited in AuxiliasCrossbowAssets.blend.
The former procedural generator has been retired to prevent overwriting edits.
Prefer running tools/export_assets.py directly with Blender.
"""
from pathlib import Path
import runpy

if __name__ == '__main__':
    print('Exporting the authored .blend; source geometry will not be regenerated.')
    runpy.run_path(str(Path(__file__).resolve().parents[2] / 'tools/export_assets.py'), run_name='__main__')
