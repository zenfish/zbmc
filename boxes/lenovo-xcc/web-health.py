#!/usr/bin/env python3
"""Validate native XCC Web login, session identity, and logout."""
import http.cookiejar
import json
import os
import ssl
import sys
import urllib.parse
import urllib.request


def check(base, username, password):
    cookies = http.cookiejar.CookieJar()
    # Preserved vendor image uses a self-signed HTTPS certificate, like curl -k.
    client = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(cookies),
        urllib.request.HTTPSHandler(context=ssl._create_unverified_context()))
    token = None

    def call(path, data=None, nonce=None):
        headers = {'Accept': 'application/json, text/plain, */*'}
        if data is not None:
            headers['Content-Type'] = 'application/json'
        if nonce is not None:
            headers['Content-Security-Policy'] = 'nonce=' + nonce
        if token:
            headers['Authorization'] = 'Bearer ' + token
        for cookie in cookies:
            if cookie.name == '_csrf_token':
                headers['X-XSRF-TOKEN'] = urllib.parse.unquote(cookie.value)
        request = urllib.request.Request(base + path, headers=headers,
            data=None if data is None else json.dumps(data).encode())
        with client.open(request, timeout=15) as response:
            return json.load(response)

    try:
        nonce = call('/api/providers/get_nonce', {})
        if nonce.get('return') != 0 or not nonce.get('nonce'):
            raise ValueError('nonce request failed')
        login = call('/api/login', {'username': username, 'password': password}, nonce['nonce'])
        token = login.get('access_token')
        if not token or 'reason' in login:
            raise ValueError('Web login did not grant an unrestricted session')
        session = call('/api/providers/sessioninfo')
        if session.get('return') != 0 or session.get('username') != username:
            raise ValueError('authenticated Web session identity did not match')
    finally:
        if token and call('/api/providers/logout').get('return') != 0:
            raise ValueError('Web session logout failed')


if __name__ == '__main__':
    try:
        check(os.environ['XCC_URL'], os.environ['XCC_USER'], os.environ['XCC_PASSWORD'])
    except Exception as error:
        # Do not include request/response bodies, credentials, or session tokens.
        print('native Web login/session/logout failed (' + type(error).__name__ + ')')
        sys.exit(1)
    print('AUTH OK (native Web login, session identity, logout)')
