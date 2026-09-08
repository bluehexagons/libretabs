#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Embed the audited file bridge without an extra network dependency."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]


def prepare(presets=None):
    presets = presets or root / 'export_presets.cfg'
    head = '<script>\n' + (root / 'src/platform/bridge.js').read_text() + '\n</script>'
    text = presets.read_text()
    updated, count = re.subn(
        r'^html/head_include=.*$',
        lambda _: 'html/head_include=' + json.dumps(head),
        text,
        flags=re.M,
    )
    if count == 0:
        raise ValueError(f'No web export head includes found in {presets}')
    if updated != text:
        presets.write_text(updated)
    return count


if __name__ == '__main__':
    prepare()
