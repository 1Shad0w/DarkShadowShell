# Normas de contribución (Fork)

Este repositorio mantiene un flujo basado en `dev` → `main` para mantener `main` siempre estable y probada.

## Flujo de ramas y releases

1. **Rama base para cambios**: crea siempre tu rama desde `dev` (`feat/...`, `fix/...`, `docs/...`, `refactor/...`) y abre la Pull Request contra **`dev`**.
2. **Promoción a `main` y releases**: solo el mantenedor decide cuándo lanzar una versión abriendo y mergeando una PR de **`dev` → `main`**.
   - En la descripción de esa PR de release indica:
     - `Version tag: vX.YY` (si se deja vacío, toma `v` + el contenido de `VERSION`).
     - Marca `- [x] Crear GitHub Release` si quieres publicar también la GitHub Release.
   - El workflow [release.yml](.github/workflows/release.yml) creará automáticamente el tag (y la Release si se marcó), y también puede lanzarse manualmente desde GitHub Actions (`workflow_dispatch`).
3. **Nombre del repositorio**: el fork puede llamarse tanto `DarkShadowShell` como `dotfiles` en GitHub (`github.com/<owner>/(DarkShadowShell|dotfiles)`).

## Commits y Pull Requests

- Usa mensajes de commit claros en formato convencional (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- Rellena la [plantilla de Pull Request](.github/PULL_REQUEST_TEMPLATE.md).
- No mezcles cambios no relacionados en la misma PR.

## Tests obligatorios

Antes de abrir o actualizar una PR, ejecuta y verifica localmente:

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

Además:
- Comprueba sintaxis Python (`python3 -m py_compile`) en scripts modificados de `bin/`.
- Comprueba sintaxis Bash (`bash -n`) en scripts shell modificados y Lua (`luac -p`) si tocas archivos `.lua`.

## Seguridad y reglas técnicas

- **Descargas externas**: toda descarga debe estar fijada a un tag o commit y verificada por SHA-256 en `install/checksums.txt`. No uses ramas móviles (`main`/`master`) ni `releases/latest`.
- **Privacidad**: cualquier nueva petición de red que envíe datos del usuario debe ser opt-in.
- **Escrituras atómicas**: escribe configuraciones y estados mediante archivo temporal + `os.replace` (y usando `~/.config/rice/.hypr.lock` cuando compartas ficheros con `hypr-set` / `fixup.py`).
- **QML compartido**: mantén idénticos los componentes validados por `tests/qml-shared.sh` (`Sfx`, `SfxBank`, `SfxTap`, `Fonts`).
- **Plantillas y seguridad**: nunca desactives o debilites checks de `tests/security.sh` o de CI para hacer pasar una PR.
