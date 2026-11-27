## Summary

<!-- Briefly describe what this PR changes and why. -->

## Target Branch

- [ ] Regular change targeting `dev` (features, fixes, docs, refactors)
- [ ] Release PR from `dev` into `main`

## Release Metadata (only for `dev` → `main` PRs)

<!-- If Version tag is left blank, the workflow falls back to v<VERSION>. -->
Version tag:
- [ ] Create GitHub Release

## Verification Checklist

- [ ] `bash tests/security.sh`
- [ ] `bash tests/qml-shared.sh`
- [ ] `bash tests/qml-syntax.sh`
- [ ] `bash tests/dock.sh`
- [ ] `bash tests/gentoo.sh`
- [ ] `bash tests/infinite.sh`
- [ ] `bash tests/sddm.sh`
- [ ] `python3 tests/hotcorner.py`
- [ ] `python3 -m py_compile` on modified Python scripts
- [ ] `bash -n` on modified shell scripts (and `luac -p` if Lua files were changed)

## Security & Compatibility

- [ ] Any new external downloads are pinned to a tag/commit and SHA-256 verified in `install/checksums.txt`
- [ ] Config/state writes are atomic (`.tmp` + `os.replace`)
- [ ] No security or CI checks were removed or weakened
- [ ] No secrets or private credentials included
