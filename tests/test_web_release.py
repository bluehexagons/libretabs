# SPDX-License-Identifier: Apache-2.0
import hashlib
from email.message import Message
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import check_web_release
import release
from web_manifest import REQUIRED_ASSETS, parse_assets


class WebReleaseTests(unittest.TestCase):
    def setUp(self):
        self.files = {name: ('fixture: ' + name).encode() for name in REQUIRED_ASSETS}
        self.assets = {name: hashlib.sha256(data).hexdigest() for name, data in self.files.items()}

    def worker(self, assets):
        return 'const ASSETS = ' + json.dumps(assets) + ';\n'

    def check_deployment(self, worker=None, *, bad_mime=None, missing_headers=None):
        files = dict(self.files)
        files['index.service.worker.js'] = (worker if worker is not None else self.worker(self.assets)).encode()
        base = 'https://example.test/libretabs/'

        def fetch(url, **kwargs):
            self.assertTrue(url.startswith(base))
            name = url[len(base):]
            response = io.BytesIO(files[name])
            response.headers = Message()
            if name != missing_headers:
                response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
                response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
            mime = 'application/wasm' if name.endswith('.wasm') else 'application/javascript'
            response.headers['Content-Type'] = 'text/plain' if name == bad_mime else mime
            return response

        with patch('sys.argv', ['check_web_release.py', base]), \
                patch.object(check_web_release.urllib.request, 'urlopen', side_effect=fetch) as fetched, \
                patch('builtins.print') as printed:
            check_web_release.main()
        self.assertEqual(fetched.call_count, len(self.files) + 1)
        self.assertIn(f'{len(self.files)} offline asset hashes', printed.call_args.args[0])

    def test_complete_deployment_checks_every_hash_and_rejects_changed_resources(self):
        self.check_deployment()
        self.files['index.pck'] = b'wrong release'
        with self.assertRaisesRegex(SystemExit, 'Deployment mismatch: index.pck'):
            self.check_deployment()

    def test_invalid_manifest_never_reaches_application_requests(self):
        for worker in ('// missing inventory', 'const ASSETS = invalid;\n', self.worker([]),
                       self.worker({}), self.worker({'index.html': self.assets['index.html']})):
            with self.subTest(worker=worker), \
                    patch.object(check_web_release.urllib.request, 'urlopen') as fetch, \
                    patch('sys.argv', ['check_web_release.py', 'https://example.test/']):
                response = io.BytesIO(worker.encode())
                response.headers = Message()
                response.headers['Content-Type'] = 'application/javascript'
                response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
                response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
                fetch.return_value = response
                with self.assertRaisesRegex(SystemExit, '(manifest|Manifest)'):
                    check_web_release.main()
                self.assertEqual(fetch.call_count, 1)

    def test_unsafe_names_and_invalid_hashes_are_rejected_before_use(self):
        for name in ('../secret', '/index.js', 'https://other.test/file', 'file?query',
                     'file#fragment', 'file%2ejs', 'file\\path', '.', '..', 'file\nname'):
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, 'asset name'):
                parse_assets(self.worker({**self.assets, name: 'a' * 64}))
        for value in ('', 'not a hash', 'a' * 63, 123, None):
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, 'SHA-256'):
                parse_assets(self.worker({**self.assets, 'index.pck': value}))

    def test_deployment_retains_header_and_mime_checks(self):
        with self.assertRaisesRegex(SystemExit, 'COOP/COEP'):
            self.check_deployment(missing_headers='index.html')
        for name in ('index.js', 'index.wasm'):
            with self.subTest(name=name), self.assertRaisesRegex(SystemExit, 'MIME|application/wasm'):
                self.check_deployment(bad_mime=name)

    def test_local_release_rejects_the_same_incomplete_or_tampered_inventory(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            for name, data in self.files.items():
                (folder / name).write_bytes(data)
            worker = folder / 'index.service.worker.js'
            for inventory in ({}, {'index.html': self.assets['index.html']}):
                worker.write_text(self.worker(inventory))
                with self.assertRaisesRegex(ValueError, 'manifest is missing'):
                    release.validate_payload(folder, release.TARGETS['web'])
            worker.write_text(self.worker(self.assets))
            release.validate_payload(folder, release.TARGETS['web'])
            (folder / 'index.pck').write_bytes(b'tampered')
            with self.assertRaisesRegex(ValueError, 'Offline manifest mismatch: index.pck'):
                release.validate_payload(folder, release.TARGETS['web'])


if __name__ == '__main__':
    unittest.main()
