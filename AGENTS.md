# Normas para Agentes de IA (`AGENTS.md`)

Estas normas aplican a cualquier agente de código que trabaje en este repositorio.

## 1. Remotos, ramas y versiones

- **Nunca** hagas `push` ni abras Pull Requests contra `upstream` (`shadowww-dev/DarkShadowShell`). Trabaja únicamente sobre `origin` (el repo puede llamarse `DarkShadowShell` o `dotfiles`).
- **Todos los cambios van a `dev`**: crea siempre ramas desde `dev` y abre Pull Requests con base `dev`.
- **No toques `main` directamente** ni hagas merge de `dev` → `main` por tu cuenta.
- **No decidas números de versión ni crees tags/releases** salvo instrucción explícita del usuario: el usuario controla las PR de `dev` → `main`, el `Version tag` y cuándo se publica una release mediante `.github/workflows/release.yml`.

## 2. Verificación obligatoria antes de commit o PR

Ejecuta la suite completa y asegúrate de que todo pase sin errores:

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

Y valida sintaxis de los archivos tocados:
- Python: `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile <archivo>`
- Bash: `bash -n <archivo>`
- Lua: `luac -p <archivo>`

**Prohibido** eliminar, relajar o saltarse checks de `tests/security.sh`, `tests/qml-shared.sh` o `.github/workflows/ci.yml` para hacer pasar cambios.

## 3. Reglas técnicas del proyecto

- **Descargas fijadas por hash**: toda URL externa en scripts (`bin/*`, `install.sh`, `install/lib/*`) debe apuntar a un tag o commit fijo y tener su SHA-256 verificado contra `install/checksums.txt`.
- **Orígenes permitidos**: los checks de remoto (`install/lib/secure.sh`, `bin/rice-update`) aceptan repositorios en GitHub llamados `DarkShadowShell` o `dotfiles`.
- **Escrituras atómicas**: las configuraciones y archivos de estado se escriben en un `.tmp` y se reemplazan con `os.replace` (manteniendo permisos y tomando `~/.config/rice/.hypr.lock` cuando aplique).
- **QML y objetos vivos (Issue #21)**: en modelos/listas QML no guardes referencias vivas a `Toplevel` ni `DesktopEntry`; guarda IDs/strings/booleanos y busca el objeto en el momento de usarlo (`DesktopEntries.heuristicLookup(...)`, `ToplevelManager.toplevels.values`).
- **Componentes QML compartidos**: si modificas `Sfx.qml`, `SfxBank.qml`, `SfxTap.qml` o `Fonts.qml` en `quickshell/rice-desktop/`, sincroniza las copias de los demás `quickshell/rice-*/` para que `tests/qml-shared.sh` pase.
- **Páginas en Settings**: en `quickshell/rice-settings/shell.qml` no reutilices índices ya asignados; usa siempre el siguiente índice libre.
- **Sin secretos**: no añadas tokens, contraseñas ni rutas locales privadas en código, commits o PRs.
