#!/usr/bin/env python3
"""Populate regional English SwiftUI string tables from the shared English source."""

import argparse
from copy import deepcopy
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
ENTRY = re.compile(r'^    ("(?:[^"\\]|\\.)*") : \{\n.*?^    \},?$', re.M | re.S)
REGIONS = ("en-CA", "en-AU")
REGIONAL_ENTRY = re.compile(r'^        "(?:' + "|".join(REGIONS) + r')" : \{\n.*?^        \},?\n', re.M | re.S)
SPELLINGS = {"color": "colour", "colors": "colours", "gray": "grey"}
PRACTICE_VERBS = {
    "dino.practice.description": ("Keep practicing", "Keep practising"),
    "dino.practice.start": ("Start practicing", "Start practising"),
    "dino.practice.time": ("Times to practice", "Times to practise"),
}
AUSTRALIAN_COPY = {
    "dino.appearance.open": "Personalise your dino and clocks",
    "dino.friends.syncDone": "Your available results are synchronised.",
    "dino.example.rule.read24Hour": (
        "For hours above 12, subtract 12. For example, 17:05 is 5:05\u00a0pm. "
        "12:00 is midday and 00:00 is midnight."
    ),
}


def regional_text(region, key, text):
    if region == "en-AU" and key in AUSTRALIAN_COPY:
        return AUSTRALIAN_COPY[key]

    def spell(match):
        source = match.group()
        word = SPELLINGS[source.lower()]
        if source.isupper():
            return word.upper()
        return word.capitalize() if source[0].isupper() else word

    text = re.sub(r"\b(?:colors?|gray)\b", spell, text, flags=re.I)
    if key in PRACTICE_VERBS:
        source, translated = PRACTICE_VERBS[key]
        text = text.replace(source, translated)
    return text


def translate_units(region, key, value):
    for name, item in value.items():
        if name == "value" and isinstance(item, str):
            value[name] = regional_text(region, key, item)
        elif isinstance(item, dict):
            translate_units(region, key, item)


def sync_catalog(path):
    original = path.read_text(encoding="utf-8")
    strings = json.loads(original)["strings"]

    def write_entry(match):
        key = json.loads(match[1])
        english = strings[key].get("localizations", {}).get("en")
        if english is None:
            return match[0]
        rows = []
        for region in REGIONS:
            translated = deepcopy(english)
            translate_units(region, key, translated)
            lines = json.dumps(translated, ensure_ascii=False, indent=2, separators=(",", " : ")).splitlines()
            rows.append(f'        "{region}" : ' + lines[0] + "\n" + "\n".join("        " + line for line in lines[1:]) + ",\n")
        entry = REGIONAL_ENTRY.sub("", match[0])
        entry = entry.replace("\n        },\n      }", "\n        }\n      }", 1)
        anchor = '      "localizations" : {\n'
        return entry.replace(anchor, anchor + "".join(rows), 1)

    updated = ENTRY.sub(write_entry, original)
    built = json.loads(updated)["strings"]
    assert all(
        all(region in built[key].get("localizations", {}) for region in REGIONS)
        for key, entry in strings.items() if "en" in entry.get("localizations", {})
    )
    return original, updated


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report stale regional strings without writing")
    args = parser.parse_args()
    for name in ("Localizable.xcstrings", "InfoPlist.xcstrings"):
        path = ROOT / name
        original, updated = sync_catalog(path)
        if original == updated:
            continue
        if args.check:
            parser.exit(1, f"{name} is stale. Run python3 Tools/sync-english-localizations.py.\n")
        path.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    main()
