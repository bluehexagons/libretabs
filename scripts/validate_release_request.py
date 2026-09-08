#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Resolve a prototype version and release notes before a release build."""
import argparse
from pathlib import Path
import re
import subprocess

from release import ROOT, VERSION


def version_key(version):
    if not VERSION.fullmatch(version):
        raise ValueError(
            f"Invalid prototype version {version!r}. Use "
            "MAJOR.MINOR.PATCH-prototype.NUMBER, for example "
            "0.0.1-prototype.1 (no leading 'v')."
        )
    numbers = version.replace('-prototype.', '.').split('.')
    return tuple(int(number) for number in numbers)


def release_tags(root=ROOT):
    result = subprocess.run(
        ['git', 'tag', '--merged', 'HEAD'], cwd=root, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True
    )
    tags = []
    for tag in result.stdout.splitlines():
        if tag.startswith('v') and VERSION.fullmatch(tag[1:]):
            tags.append((version_key(tag[1:]), tag))
    return sorted(tags)


def next_version(tags):
    if not tags:
        return '0.0.1-prototype.1'
    latest, _ = max(tags)
    return f'{latest[0]}.{latest[1]}.{latest[2]}-prototype.{latest[3] + 1}'


def next_available_version(tags, occupied_versions=()):
    occupied = set(occupied_versions)
    keys = [key for key, _ in tags] + [version_key(version) for version in occupied]
    if keys:
        latest = max(keys)
        candidate = f'{latest[0]}.{latest[1]}.{latest[2]}-prototype.{latest[3] + 1}'
    else:
        candidate = '0.0.1-prototype.1'
    while candidate in occupied:
        candidate = next_version([(version_key(candidate), 'v' + candidate)])
    return candidate


def github_release_versions(repository):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('GitHub repository must use OWNER/REPOSITORY')
    result = subprocess.run(
        ['gh', 'api', '--paginate', f'repos/{repository}/releases?per_page=100',
         '--jq', '.[].tag_name'], text=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if result.returncode:
        raise ValueError('Could not check existing GitHub releases before building')
    return {tag[1:] for tag in result.stdout.splitlines()
            if tag.startswith('v') and VERSION.fullmatch(tag[1:])}


def generated_notes(version, root=ROOT):
    tags = release_tags(root)
    previous = max(tags)[1] if tags else ''
    command = ['git', 'log', '--format=%h%x09%s']
    if previous:
        command.append(f'{previous}..HEAD')
    result = subprocess.run(
        command, cwd=root, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, check=True
    )
    changes = []
    for line in result.stdout.splitlines()[:60]:
        short_hash, subject = line.split('\t', 1)
        changes.append(f'- {subject.strip()} ({short_hash})')
    if not changes:
        changes.append('- No source changes were found since the previous prototype release.')
    since = f' since {previous}' if previous else ' from the project history'
    return f'''# LibreTabs {version}

Evaluation prototype, not the completed lesson-based MVP.

[Practice guide and troubleshooting](https://bluehexagons.github.io/libretabs/)

## Changes

Generated from commits{since}:

{chr(10).join(changes)}

## Downloads

- Web ZIP: for an HTTPS host or itch.io HTML upload; not a double-click offline app.
- Windows x86_64 ZIP: extract completely and run `LibreTabs.exe`.
- Linux x86_64 ZIP: extract completely and run `./libretabs.x86_64`.

Native builds are unsigned. Download only from this project's release page and
verify `SHA256SUMS`. Do not disable operating-system security protections; report
blocked launches with the OS and message. No Godot installation is required.

## Known limits and feedback

Procedural audio, simplified notation, and the lesson course remain under
evaluation. Imported MIDI is session-only and stays on the device. Report the
version, OS/browser, steps, expected result, and actual result through
https://github.com/bluehexagons/libretabs/issues. Use original or redistributable
MIDI reproductions and remove private filenames and personal details.
'''


def resolve(version='', root=ROOT, occupied_versions=()):
    tags = release_tags(root)
    occupied = set(occupied_versions) | {tag[1:] for _, tag in tags}
    resolved_version = version or next_available_version(tags, occupied)
    version_key(resolved_version)
    if resolved_version in occupied:
        raise ValueError(f'Prototype version {resolved_version} already has a GitHub release or tag; choose a new version.')
    note_path = Path(root) / 'release' / 'notes' / f'{resolved_version}.md'
    if note_path.is_file() and not note_path.is_symlink():
        return resolved_version, note_path.read_text(), 'committed'
    return resolved_version, generated_notes(resolved_version, root), 'generated'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('version', nargs='?', default='', help='optional MAJOR.MINOR.PATCH-prototype.NUMBER')
    parser.add_argument('--repository', help='check GitHub releases for this OWNER/REPOSITORY before building')
    parser.add_argument('--notes-output', type=Path, help='write the resolved Markdown notes here')
    parser.add_argument('--github-output', type=Path, help='append version and notes source for GitHub Actions')
    args = parser.parse_args()
    try:
        occupied = github_release_versions(args.repository) if args.repository else set()
        version, notes, source = resolve(args.version, occupied_versions=occupied)
    except (ValueError, subprocess.CalledProcessError) as error:
        parser.error(str(error))
    if args.notes_output:
        args.notes_output.parent.mkdir(parents=True, exist_ok=True)
        args.notes_output.write_text(notes)
    if args.github_output:
        with args.github_output.open('a') as output:
            output.write(f'version={version}\nnotes_source={source}\n')
    location = str(args.notes_output) if args.notes_output else f'{source} notes'
    print(f'Release request is valid; version {version}; using {source} release notes ({location}).')


if __name__ == '__main__':
    main()
