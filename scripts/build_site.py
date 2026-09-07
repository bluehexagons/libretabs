#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Build only the instructional Pages site; never publish repository contents."""
from pathlib import Path
import argparse
import html
import os
import shutil
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]


def player_link(url, label):
    if not url:
        return ''
    parsed = urlsplit(url)
    if (parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password
            or any(char.isspace() or ord(char) < 32 for char in url) or '\\' in url):
        raise ValueError('Player links must be public HTTPS URLs without credentials or whitespace')
    return f'<a class="button" href="{html.escape(url, quote=True)}">{html.escape(label)}</a>'


def build(output, player_url='', itch_url=''):
    page = (ROOT / 'site/index.html').read_text()
    page = page.replace('{{PLAYER_LINK}}', player_link(player_url, 'Play in your browser'))
    page = page.replace('{{ITCH_LINK}}', player_link(itch_url, 'LibreTabs on itch.io'))
    page = page.replace('{{HOSTING_NOTE}}', 'Browser play opens on a separate host.' if player_url or itch_url else 'Browser-play links will appear here when the hosted versions are ready.')
    if '{{' in page:
        raise ValueError('Unresolved site placeholder')
    # Require a new directory so stale exports cannot accidentally enter Pages.
    output.mkdir(parents=True, exist_ok=False)
    (output / 'index.html').write_text(page)
    shutil.copy2(ROOT / 'site/style.css', output / 'style.css')
    (output / '.nojekyll').touch()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/site')
    args = parser.parse_args()
    build(args.output, os.environ.get('PLAYER_URL', ''), os.environ.get('ITCH_URL', ''))
    print(args.output)
