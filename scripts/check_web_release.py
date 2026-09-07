#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Check a deployed HTTPS web package's headers, MIME and offline asset hashes."""
import argparse
import hashlib
import json
import re
import urllib.parse
import urllib.request

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('url', help='Final HTTPS directory URL, including trailing slash')
    args = parser.parse_args()
    if not args.url.startswith('https://') or not args.url.endswith('/'):
        parser.error('Use the final HTTPS directory URL ending in /')
    def fetch(name):
        with urllib.request.urlopen(urllib.parse.urljoin(args.url, name), timeout=60) as response:
            if response.headers.get('Cross-Origin-Opener-Policy') != 'same-origin' or response.headers.get('Cross-Origin-Embedder-Policy') != 'require-corp':
                raise SystemExit(f'Missing COOP/COEP headers: {name}')
            mime = response.headers.get_content_type()
            if name.endswith('.wasm') and mime != 'application/wasm':
                raise SystemExit('Serve WASM as application/wasm')
            if name.endswith('.js') and mime not in ['application/javascript', 'text/javascript']:
                raise SystemExit(f'Incorrect JavaScript MIME: {name}')
            return response.read()
    worker = fetch('index.service.worker.js').decode()
    assets = json.loads(re.search(r'const ASSETS = (.*);', worker)[1])
    for name, expected in assets.items():
        if '/' in name or name in ['.', '..']:
            raise SystemExit('Invalid manifest asset name')
        if hashlib.sha256(fetch(name)).hexdigest() != expected:
            raise SystemExit(f'Deployment mismatch: {name}')
    print(f'PASS: HTTPS, isolation headers, MIME and {len(assets)} offline asset hashes. Browser/audio checks still required.')

if __name__ == '__main__':
    main()
