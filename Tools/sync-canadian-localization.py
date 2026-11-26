#!/usr/bin/env python3
"""Keep the original command for synchronising regional English resources."""

from pathlib import Path
import runpy


if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).with_name("sync-english-localizations.py")), run_name="__main__")
