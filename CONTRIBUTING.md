# Contributing Guidelines

This repository follows a `dev` → `main` workflow to keep `main` stable and tested at all times.

## Branching & Release Workflow

1. **Base branch for changes**: always create your branch from `dev` (`feat/...`, `fix/...`, `docs/...`, `refactor/...`) and open Pull Requests against **`dev`**.
2. **Promoting to `main` & releases**: only the maintainer decides when to ship a release by opening and merging a PR from **`dev` → `main`**.
   - In that release PR description, specify:
     - `Version tag: vX.YY` (if left blank, the workflow uses `v` + the contents of `VERSION`).
     - Check `- [x] Create GitHub Release` if you also want a GitHub Release published.
   - The [release.yml](.github/workflows/release.yml) workflow automatically creates the git tag (and the GitHub Release if checked), and can also be triggered manually via GitHub Actions (`workflow_dispatch`).
3. **Repository name**: this fork may be named either `DarkShadowShell` or `dotfiles` on GitHub (`github.com/<owner>/(DarkShadowShell|dotfiles)`).

## Language, Commits & Pull Requests

- Keep all repository code, comments, documentation, templates, and workflows in **English** by default (unless translating UI/i18n files).
- Use clear Conventional Commit messages (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- Fill out the [Pull Request template](.github/PULL_REQUEST_TEMPLATE.md).
- Do not mix unrelated changes in the same PR.

## Mandatory Local Checks

Before opening or updating a PR, run and verify the full test suite locally:

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

Also validate syntax for any modified files:
- Python: `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile <file>`
- Bash: `bash -n <file>`
- Lua: `luac -p <file>`

## Security & Technical Rules

- **Pinned external downloads**: every external download must target a fixed tag or commit and be SHA-256 verified against `install/checksums.txt`. Never use moving branches (`main`/`master`) or `releases/latest`.
- **Privacy**: any new network feature that sends user data must be opt-in.
- **Atomic writes**: write configuration and state files via a `.tmp` file + `os.replace` (holding `~/.config/rice/.hypr.lock` when sharing files with `hypr-set` / `fixup.py`).
- **Shared QML components**: keep the shared QML copies checked by `tests/qml-shared.sh` (`Sfx`, `SfxBank`, `SfxTap`, `Fonts`) byte-identical across apps.
- **No weakened checks**: never delete, relax, or bypass checks in `tests/security.sh` or CI to make a PR pass.
