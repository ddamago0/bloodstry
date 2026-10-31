#!/usr/bin/env python3
"""Regenerate every visual asset used by Bloodsty.

Usage:
    python3 tools/generate_assets.py
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from artgen import characters, environment, ui  # noqa: E402


def main() -> None:
    print("Bloodsty asset pipeline")
    print("=======================")
    ui.build_all()
    characters.build_all()
    environment.build_all()
    print("Done.")


if __name__ == "__main__":
    main()
