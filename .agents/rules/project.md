---
trigger: always_on
---

# Project Rules (DarkShadowShell / dotfiles fork)

- Never push to or open PRs against `upstream` (`shadowww-dev/DarkShadowShell`); operate only on `origin` (which may be named `DarkShadowShell` or `dotfiles`).
- All changes must go into branches created from `dev` and via PRs targeting `dev`. Never push directly to `main` or decide version numbers / create tags or releases on your own (the user triggers `dev` → `main` PRs using `.github/workflows/release.yml`).
- Keep all repository code, comments, documentation, PR templates, and workflows in English by default (except i18n/translation files).
- Before committing or opening a PR, run and verify the full test suite (`tests/security.sh`, `tests/qml-shared.sh`, `tests/qml-syntax.sh`, `tests/dock.sh`, `tests/gentoo.sh`, `tests/infinite.sh`, `tests/sddm.sh`, `python3 tests/hotcorner.py`) plus `py_compile`, `bash -n`, and `luac -p` as applicable.
- Respect all technical invariants: hash-pinned downloads with SHA-256 in `install/checksums.txt`, atomic config writes, synced shared QML copies (`tests/qml-shared.sh`), never cache live `Toplevel`/`DesktopEntry` objects in QML models, and use the next free page index when adding a page in `quickshell/rice-settings/shell.qml`.
