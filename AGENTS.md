# AI Agent Guidelines (`AGENTS.md`)

These rules apply to any coding agent working in this repository.

## 1. Remotes, Branches & Releases

- **Never** push to or open Pull Requests against `upstream` (`shadowww-dev/DarkShadowShell`). Operate only on `origin` (the repo may be named `DarkShadowShell` or `dotfiles`).
- **All changes target `dev`**: always create branches from `dev` and open Pull Requests with base `dev`.
- **Do not touch `main` directly** or merge `dev` → `main` on your own.
- **Do not pick version numbers or create tags/releases** unless explicitly instructed by the user: the user controls `dev` → `main` PRs, the `Version tag`, and when releases are published via `.github/workflows/release.yml`.

## 2. Language

- Keep all repository code, comments, documentation, commit messages, PR templates, and workflows in **English** by default (excluding localized i18n/translation files).

## 3. Mandatory Verification Before Commit or PR

Run the full test suite and verify everything passes without errors:

```bash
bash tests/security.sh
bash tests/qml-shared.sh
bash tests/qml-syntax.sh
bash tests/dock.sh
bash tests/gentoo.sh
bash tests/infinite.sh
bash tests/sddm.sh
python3 tests/hotcorner.py
```

And validate syntax on touched files:
- Python: `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile <file>`
- Bash: `bash -n <file>`
- Lua: `luac -p <file>`

**Forbidden**: deleting, relaxing, or skipping checks in `tests/security.sh`, `tests/qml-shared.sh`, or `.github/workflows/ci.yml` to make changes pass.

## 4. Technical Invariants

- **Hash-pinned downloads**: every external URL in scripts (`bin/*`, `install.sh`, `install/lib/*`) must point to a fixed tag or commit and have its SHA-256 verified against `install/checksums.txt`.
- **Allowed origins**: remote checks (`install/lib/secure.sh`, `bin/rice-update`) accept GitHub repositories named `DarkShadowShell` or `dotfiles`.
- **Atomic writes**: configuration and state files must be written to a `.tmp` file and replaced with `os.replace` (preserving permissions and holding `~/.config/rice/.hypr.lock` when applicable).
- **QML live object safety (Issue #21)**: do not store live `Toplevel` or `DesktopEntry` object references in QML models/lists; store IDs/strings/booleans and look up the object at use time (`DesktopEntries.heuristicLookup(...)`, `ToplevelManager.toplevels.values`).
- **Shared QML components**: if you modify `Sfx.qml`, `SfxBank.qml`, `SfxTap.qml`, or `Fonts.qml` in `quickshell/rice-desktop/`, sync the copies in the other `quickshell/rice-*/` folders so `tests/qml-shared.sh` passes.
- **Settings page indices**: in `quickshell/rice-settings/shell.qml`, never reuse an already assigned page index; always use the next free index.
- **No secrets**: never commit tokens, passwords, or private local paths in code, commits, or PRs.
