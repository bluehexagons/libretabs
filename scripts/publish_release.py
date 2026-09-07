#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Promote existing checked packages; print commands unless --execute is supplied."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def verified_manifest(folder):
    def regular_file(name):
        path = folder / name
        if path.is_symlink() or not path.is_file():
            raise ValueError(f'Release input must be a regular file: {name}')
        return path

    manifest = json.loads(regular_file('manifest.json').read_text())
    if not isinstance(manifest, dict):
        raise ValueError('Release manifest must be an object')
    if not isinstance(manifest.get('version'), str) or not re.fullmatch(r'\d+\.\d+\.\d+-prototype\.\d+', manifest['version']):
        raise ValueError('Invalid prototype version')
    if not isinstance(manifest.get('commit'), str) or not re.fullmatch(r'[0-9a-f]{40}', manifest['commit']):
        raise ValueError('Invalid source commit')
    targets = json.loads((ROOT / 'release/targets.json').read_text())
    artifacts = manifest.get('artifacts')
    if not isinstance(artifacts, list) or not 1 <= len(artifacts) <= len(targets):
        raise ValueError('Invalid release artifact count')
    expected_files = {'manifest.json'}
    seen = set()
    for artifact in artifacts:
        if not isinstance(artifact, dict):
            raise ValueError('Invalid artifact entry')
        target = artifact.get('target')
        name = artifact.get('file')
        if not isinstance(target, str) or target not in targets or target in seen or name != f"libretabs-{manifest['version']}-{target}.zip":
            raise ValueError('Invalid or duplicate artifact target')
        if (type(artifact.get('bytes')) is not int or artifact['bytes'] <= 0
                or not isinstance(artifact.get('sha256'), str)
                or not re.fullmatch(r'[0-9a-f]{64}', artifact['sha256'])):
            raise ValueError('Invalid artifact size or SHA-256')
        seen.add(target)
        expected_files.add(name)
    checksums = {}
    for line in regular_file('SHA256SUMS').read_text().splitlines():
        if not re.fullmatch(r'[0-9a-f]{64}  [A-Za-z0-9._-]+', line):
            raise ValueError('Invalid checksum entry')
        expected, name = line.split('  ', 1)
        if name not in expected_files or name in checksums:
            raise ValueError('Invalid checksum filename')
        with regular_file(name).open('rb') as source:
            if hashlib.file_digest(source, 'sha256').hexdigest() != expected:
                raise ValueError(f'Checksum mismatch: {name}')
        checksums[name] = expected
    if set(checksums) != expected_files:
        raise ValueError('Checksums must cover exactly the manifest and declared artifacts')
    for artifact in manifest['artifacts']:
        name = artifact['file']
        if checksums.get(name) != artifact['sha256'] or (folder / name).stat().st_size != artifact['bytes']:
            raise ValueError(f'Artifact does not match manifest: {name}')
    return manifest

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', choices=['github', 'itch'])
    parser.add_argument('directory', type=Path)
    parser.add_argument('--repository', default='bluehexagons/libretabs')
    parser.add_argument('--itch-project', help='owner/project')
    parser.add_argument('--notes', type=Path)
    parser.add_argument('--execute', action='store_true')
    args = parser.parse_args()
    folder = args.directory.resolve()
    manifest = verified_manifest(folder)
    version = manifest['version']
    if args.destination == 'github':
        if not args.notes or not args.notes.is_file():
            parser.error('--notes must name a reviewed release-notes file')
        commands = [['gh', 'release', 'create', 'v' + version, '--repo', args.repository,
                     '--target', manifest['commit'], '--draft', '--prerelease', '--latest=false', '--title', 'LibreTabs ' + version,
                     '--notes-file', str(args.notes.resolve()), *[str(folder / a['file']) for a in manifest['artifacts']],
                     str(folder / 'manifest.json'), str(folder / 'SHA256SUMS')]]
        if args.execute:
            # Never attach files to an existing tag/release with an ambiguous source.
            result = subprocess.run(['gh', 'api', f'repos/{args.repository}/git/ref/tags/v{version}'], capture_output=True, text=True)
            if result.returncode == 0 or '404' not in result.stderr:
                parser.error('Tag exists or its absence cannot be confirmed; choose a new version')
    else:
        if not args.itch_project or not re.fullmatch(r'[A-Za-z0-9_-]+/[A-Za-z0-9_-]+', args.itch_project):
            parser.error('--itch-project must be owner/project')
        targets = json.loads((ROOT / 'release/targets.json').read_text())
        commands = [['butler', 'push', str(folder / a['file']), args.itch_project + ':' + targets[a['target']]['itch_channel'], '--userversion', version] for a in manifest['artifacts']]
    for command in commands:
        print(shlex.join(command), flush=True)
        if args.execute:
            subprocess.run(command, check=True)

if __name__ == '__main__':
    main()
