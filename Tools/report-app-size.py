#!/usr/bin/env python3
"""Compare local .app bundles; ZIP sizes are proxies, not App Store sizes."""

import argparse
import io
import json
import plistlib
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


def measure(bundle):
    info = plistlib.loads((bundle / "Info.plist").read_bytes())
    files = sorted(path for path in bundle.rglob("*") if path.is_file())
    archive = io.BytesIO()
    with ZipFile(archive, "w", compression=ZIP_DEFLATED, compresslevel=9) as zipped:
        for path in files:
            entry = ZipInfo(str(Path("Payload") / bundle.name / path.relative_to(bundle)))
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = (0o100755 if path.name == info["CFBundleExecutable"] else 0o100644) << 16
            zipped.writestr(entry, path.read_bytes(), compresslevel=9)
    return {
        "bundle": str(bundle.resolve()),
        "bundle_bytes": sum(path.stat().st_size for path in files),
        "executable_bytes": (bundle / info["CFBundleExecutable"]).stat().st_size,
        "asset_catalog_bytes": (bundle / "Assets.car").stat().st_size,
        "time_zone_map_bytes": (bundle / "TimeZoneMap.json").stat().st_size,
        "local_zip_proxy_bytes": len(archive.getbuffer()),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundles", type=Path, nargs="+")
    args = parser.parse_args()
    print(json.dumps([measure(bundle) for bundle in args.bundles], indent=2))
