# Fix GitHub contract workflow

- [x] Inspect the failed GitHub Actions log.
- [x] Reproduce the new iLO5 contract locally.
- [x] Add the missing Ubuntu test dependency.
- [x] Add targeted `.md` / `.html` arguments to `tools/sync-docs`.
- [x] Cover single-file, generated-file, and multiple-file selection.
- [x] Verify focused and full contract suites and inspect the final diff.

## Review

The GitHub run failed because the new iLO5 contract requires `Crypto.Cipher.AES`, while the clean Ubuntu runner installed only the cross-compiler. The workflow now installs Ubuntu's `python3-pycryptodome` package. `tools/sync-docs` also accepts one or more `.md` or `.html` selectors, preserves those selectors during post-write verification, and leaves its no-argument repository-wide behavior unchanged.

Verified with `python3 -m py_compile tools/sync-docs`, `bash tests/sync-docs-cli.sh`, targeted Markdown/HTML checks, `bash tests/run`, and `git diff --check`.
