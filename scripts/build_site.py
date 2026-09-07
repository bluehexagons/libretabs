#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Build only the instructional Pages site; never publish repository contents."""
from pathlib import Path
import argparse
import html
import os
import shutil
import stat
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


def copy_player(source, destination):
    if not source.is_dir() or source.is_symlink():
        raise ValueError(f'Player export must be a directory: {source}')
    count = total = 0
    for path in source.rglob('*'):
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode) or not (stat.S_ISREG(mode) or stat.S_ISDIR(mode)):
            raise ValueError(f'Player export contains a symlink or special file: {path.name}')
        count += 1
        if stat.S_ISREG(mode):
            total += path.stat().st_size
        if count > 4096 or total > 500_000_000:
            raise ValueError('Player export exceeds Pages limits')
    for name in ('index.html', 'index.js', 'index.wasm', 'index.pck', 'index.service.worker.js'):
        path = source / name
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f'Player export is missing {name}')
    shutil.copytree(source, destination)


def build(output, player_url='', itch_url='', threaded_player=None, compatibility_player=None):
    page = (ROOT / 'site/index.html').read_text()
    bundled = threaded_player is not None
    page = page.replace('{{PAGES_NAV}}', '<a href="play/">Play</a>' if bundled else '')
    page = page.replace('{{PAGES_PLAYER_LINK}}', '<a class="button" href="play/">Play on GitHub Pages</a>' if bundled else '')
    compatibility = ''
    if compatibility_player is not None:
        compatibility = '<p class="compatibility">If the main player does not start in your browser, <a class="text-action" href="play-compatible/">try the compatibility player</a>. It supports more browser configurations, but timing and audio response may be less consistent.</p>'
    page = page.replace('{{COMPATIBILITY_NOTE}}', compatibility)
    page = page.replace('{{PLAYER_LINK}}', player_link(player_url, 'Alternate browser host'))
    page = page.replace('{{ITCH_LINK}}', player_link(itch_url, 'LibreTabs on itch.io'))
    if bundled:
        note = 'The player may reload once on its first visit while it prepares secure browser features and offline files.'
    elif player_url or itch_url:
        note = 'Browser play opens on a separate host.'
    else:
        note = 'Browser-play links will appear here when the hosted versions are ready.'
    page = page.replace('{{HOSTING_NOTE}}', note)
    if '{{' in page:
        raise ValueError('Unresolved site placeholder')
    # Require a new directory so stale exports cannot accidentally enter Pages.
    output.mkdir(parents=True, exist_ok=False)
    (output / 'index.html').write_text(page)
    shutil.copy2(ROOT / 'site/style.css', output / 'style.css')
    (output / '.nojekyll').touch()
    if threaded_player is not None:
        copy_player(threaded_player.resolve(), output / 'play')
    if compatibility_player is not None:
        if threaded_player is None:
            raise ValueError('Compatibility player requires the primary player')
        copy_player(compatibility_player.resolve(), output / 'play-compatible')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/site')
    parser.add_argument('--threaded-player', type=Path)
    parser.add_argument('--compatibility-player', type=Path)
    args = parser.parse_args()
    build(args.output, os.environ.get('PLAYER_URL', ''), os.environ.get('ITCH_URL', ''),
          args.threaded_player, args.compatibility_player)
    print(args.output)
