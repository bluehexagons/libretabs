# SPDX-License-Identifier: Apache-2.0
"""Validate the offline inventory produced by the Godot export plugin."""
import json
import re


REQUIRED_ASSETS = (
    'index.html', 'index.js', 'index.wasm', 'index.pck', 'index.offline.html',
    'index.icon.png', 'index.apple-touch-icon.png', 'index.audio.worklet.js',
    'index.audio.position.worklet.js',
)


def parse_assets(worker):
    match = re.search(r'^const ASSETS = (.+);$', worker, re.M)
    if match is None:
        raise ValueError('Missing offline asset manifest')
    try:
        assets = json.loads(match[1])
    except json.JSONDecodeError as error:
        raise ValueError('Invalid offline asset manifest JSON') from error
    if not isinstance(assets, dict):
        raise ValueError('Offline asset manifest must be an object')
    missing = sorted(set(REQUIRED_ASSETS) - assets.keys())
    if missing:
        raise ValueError('Offline asset manifest is missing: ' + ', '.join(missing))
    for name, expected in assets.items():
        # The export plugin emits flat filenames. Reject URL/path syntax before
        # either a local path lookup or an HTTPS request can use the manifest.
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]{0,239}', name):
            raise ValueError('Invalid manifest asset name')
        if not isinstance(expected, str) or not re.fullmatch(r'[0-9a-f]{64}', expected):
            raise ValueError(f'Invalid manifest asset SHA-256: {name}')
    return assets
