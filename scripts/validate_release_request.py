#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Validate a manual prototype-release request before CI downloads tools."""
import argparse
from pathlib import Path

from release import ROOT, VERSION


def validate(version, root=ROOT):
    if not VERSION.fullmatch(version):
        raise ValueError(
            f"Invalid prototype version {version!r}. Use "
            "MAJOR.MINOR.PATCH-prototype.NUMBER, for example "
            "0.0.1-prototype.1 (no leading 'v')."
        )
    notes = Path(root) / 'release' / 'notes' / f'{version}.md'
    if notes.is_symlink() or not notes.is_file():
        raise ValueError(
            f"Missing release notes: release/notes/{version}.md. Copy "
            "release/notes/TEMPLATE.md, edit it, and commit it before running "
            "the workflow."
        )
    return notes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('version', help='MAJOR.MINOR.PATCH-prototype.NUMBER')
    args = parser.parse_args()
    try:
        notes = validate(args.version)
    except ValueError as error:
        parser.error(str(error))
    print(f'Release request is valid; using {notes.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
