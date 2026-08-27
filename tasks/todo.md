# Fix GitHub contract workflow

- [x] Inspect the failed GitHub Actions log.
- [x] Reproduce the new iLO5 contract locally.
- [x] Add the missing Ubuntu test dependency.
- [x] Verify the contract suite and workflow diff.

## Review

The iLO5 contract requires `Crypto.Cipher.AES`, but the clean Ubuntu runner installed only the cross-compiler. The workflow now installs Ubuntu's existing `python3-pycryptodome` package alongside it. Verification: `bash tests/run` and `git diff --check`.
