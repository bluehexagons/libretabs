#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Embed the audited file bridge without an extra network dependency."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
presets=root/'export_presets.cfg'
head='<script>\n'+(root/'src/platform/bridge.js').read_text()+'\n</script>'
text=presets.read_text()
text=re.sub(r'^html/head_include=.*$',lambda _: 'html/head_include='+json.dumps(head),text,flags=re.M)
presets.write_text(text)

# Keep the comparison head identical while retaining its single-thread flags.
