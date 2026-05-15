#!/usr/bin/env python3
"""
scan-icons.py — find Nerd Font glyphs in QML files not routed through Icons.qml

Nerd Font Private Use Area ranges:
  U+E000–U+F8FF   BMP PUA (powerline, seti-ui, devicons, fa, etc.)
  U+F0000–U+FFFFF Supplementary PUA-A (MDI — nf-md-*)
  U+100000–U+10FFFF Supplementary PUA-B

Usage:
  python3 scripts/scan-icons.py [quickshell-root]
"""

import re
import sys
from pathlib import Path

QUICKSHELL_ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent.parent

ICONS_QML = QUICKSHELL_ROOT / "Icons.qml"

NF_RANGES = [
    (0xE000, 0xF8FF),
    (0xF0000, 0xFFFFF),
    (0x100000, 0x10FFFF),
]


def is_nf(cp: int) -> bool:
    return any(lo <= cp <= hi for lo, hi in NF_RANGES)


def extract_glyphs(text: str) -> set[int]:
    return {ord(ch) for ch in text if is_nf(ord(ch))}


def load_known_glyphs() -> set[int]:
    text = ICONS_QML.read_text(encoding="utf-8")
    return extract_glyphs(text)


def scan_file(path: Path, known: set[int]) -> list[tuple[int, str, set[int]]]:
    hits = []
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        glyphs = extract_glyphs(line)
        unknown = glyphs - known
        if unknown:
            hits.append((lineno, line.rstrip(), unknown))
    return hits


def codepoint_label(cp: int) -> str:
    return f"U+{cp:05X}"


def main():
    if not ICONS_QML.exists():
        print(f"ERROR: Icons.qml not found at {ICONS_QML}", file=sys.stderr)
        sys.exit(1)

    known = load_known_glyphs()
    print(f"Icons.qml: {len(known)} known glyph codepoints\n")

    qml_files = sorted(QUICKSHELL_ROOT.rglob("*.qml"))
    total_hits = 0

    for path in qml_files:
        if path.resolve() == ICONS_QML.resolve():
            continue

        hits = scan_file(path, known)
        if not hits:
            continue

        rel = path.relative_to(QUICKSHELL_ROOT)
        print(f"  {rel}")
        for lineno, line, unknown in hits:
            cps = "  ".join(codepoint_label(cp) for cp in sorted(unknown))
            # trim long lines
            display = line.strip()
            if len(display) > 80:
                display = display[:77] + "..."
            print(f"    line {lineno:4d}  [{cps}]  {display}")
        print()
        total_hits += len(hits)

    if total_hits == 0:
        print("No unmigrated Nerd Font glyphs found.")
    else:
        print(f"{total_hits} line(s) with unmigrated glyphs across {sum(1 for p in qml_files if p.resolve() != ICONS_QML.resolve() and scan_file(p, known))} file(s).")
        print("\nFor each hit: open the file, identify the glyph's name/purpose,")
        print("add it to Icons.qml, then replace the inline literal with shellRoot.icons.<name>.")


if __name__ == "__main__":
    main()
