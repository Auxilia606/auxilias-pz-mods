"""Compatibility entry point for icons derived from editable Blender assets.

Run the model export/render steps first. Old procedural artwork is not rebuilt.
"""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).resolve().parents[2]/'tools/build-icons.py'),run_name='__main__')
