"""Compatibility entry point: render the authored press, never reconstruct it.

The .blend is the source of truth. Former procedural geometry generation was
retired after direct model edits; this entry point cannot overwrite those edits.
"""
from pathlib import Path
import runpy
import bpy

HERE = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(HERE/'AuxiliasAmmunitionPress.blend'))
runpy.run_path(str(HERE/'render_runtime_press.py'), run_name='__main__')
