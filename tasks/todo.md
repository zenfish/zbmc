# Fix GitHub contract workflow

- [x] Inspect the original and follow-up GitHub Actions logs.
- [x] Reproduce the new iLO5 contract locally.
- [x] Replace Ubuntu's incompatible `Cryptodome` package with an isolated PyPI `Crypto` environment.
- [x] Add targeted `.md` / `.html` arguments to `tools/sync-docs`.
- [x] Cover single-file, generated-file, and multiple-file selection.
- [x] Verify focused and full contract suites and inspect the final diff.

## Review

The original GitHub run failed because the new iLO5 contract requires `Crypto.Cipher.AES`, while the clean runner lacked that module. Two follow-up runs proved Ubuntu's `python3-pycryptodome` package was installed and its Python selected, but Debian-family packaging exposes `Cryptodome`, not the upstream toolbox's `Crypto` namespace. CI now creates an isolated venv with pinned PyPI `pycryptodome` 3.23.0, and the iLO5 reproduction guide uses the same dependency boundary.

`tools/sync-docs` also accepts one or more `.md` or `.html` selectors, preserves those selectors during post-write verification, and leaves its no-argument repository-wide behavior unchanged.

Verified with `python3 -m py_compile tools/sync-docs`, `bash tests/sync-docs-cli.sh`, targeted Markdown/HTML checks, `bash tests/run`, and `git diff --check`.
