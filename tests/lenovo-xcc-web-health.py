#!/usr/bin/env python3
import importlib.util
import io
import json
import pathlib
from unittest.mock import patch

path = pathlib.Path(__file__).resolve().parents[1] / 'boxes/lenovo-xcc/web-health.py'
spec = importlib.util.spec_from_file_location('xcc_web', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def run(fault=None):
    calls = []
    class Client:
        def open(self, request, timeout):
            route = request.full_url.rsplit('/', 1)[-1]
            calls.append(route)
            headers = {k.lower(): v for k, v in request.header_items()}
            if route in ('sessioninfo', 'logout'):
                assert request.data is None and 'content-type' not in headers
                assert headers['authorization'] == 'Bearer fixture-token'
            if route == 'login':
                assert headers['content-security-policy'] == 'nonce=fixture-nonce'
                assert json.loads(request.data) == {'username': 'USERID', 'password': 'fixture-password'}
            responses = {'get_nonce': {'return': 0, 'nonce': 'fixture-nonce'},
                'login': {'access_token': 'fixture-token'},
                'sessioninfo': {'return': 0, 'username': 'USERID'}, 'logout': {'return': 0}}
            if fault == 'identity':
                responses['sessioninfo']['username'] = 'other'
            if fault == 'restricted':
                responses['login']['reason'] = 2
            if fault == 'logout':
                responses['logout']['return'] = 1
            if fault == 'session_error' and route == 'sessioninfo':
                raise OSError('fixture transport failure')
            return io.StringIO(json.dumps(responses[route]))
    with patch.object(module.urllib.request, 'build_opener', return_value=Client()):
        try:
            module.check('https://fixture', 'USERID', 'fixture-password')
        except (ValueError, OSError):
            assert fault is not None
        else:
            assert fault is None
    assert calls[-1] == 'logout'

for fault in (None, 'identity', 'restricted', 'logout', 'session_error'):
    run(fault)
print('Lenovo native Web session health: PASS')
