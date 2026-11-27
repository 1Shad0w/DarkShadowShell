---
trigger: always_on
---

# Reglas del proyecto (Fork DarkShadowShell / dotfiles)

- Nunca hagas `push` ni abras PRs hacia `upstream` (`shadowww-dev/DarkShadowShell`); opera solo sobre `origin` (cuyo nombre puede ser `DarkShadowShell` o `dotfiles`).
- Todos los cambios deben ir en ramas creadas desde `dev` y mediante PR hacia `dev`. Nunca subas cambios directos a `main` ni decidas el nombre de versión o creación de tags/releases por tu cuenta (el usuario lanza las PR de `dev` → `main` usando `.github/workflows/release.yml`).
- Antes de hacer commit o abrir PR, ejecuta y verifica todos los tests (`tests/security.sh`, `tests/qml-shared.sh`, `tests/qml-syntax.sh`, `tests/dock.sh`, `tests/gentoo.sh`, `tests/infinite.sh`, `tests/sddm.sh`, `python3 tests/hotcorner.py`) más `py_compile`, `bash -n` y `luac -p` según corresponda.
- Respeta los invariantes técnicos: descargas fijadas a tag/commit con SHA-256 en `install/checksums.txt`, escrituras atómicas de configuración, copias QML compartidas sincronizadas (`tests/qml-shared.sh`), no cachear objetos vivos `Toplevel`/`DesktopEntry` en modelos QML y usar el siguiente índice libre si se añade página en `quickshell/rice-settings/shell.qml`.
