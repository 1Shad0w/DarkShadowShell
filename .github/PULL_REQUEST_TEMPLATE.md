## Resumen

<!-- Describe brevemente qué cambia esta PR y por qué. -->

## Rama destino

- [ ] Cambio normal hacia `dev` (features, fixes, docs, refactors)
- [ ] Release de `dev` hacia `main`

## Datos de release (solo para PR de `dev` → `main`)

<!-- Si dejas Version tag vacío, el workflow usará v<VERSION>. -->
Version tag:
- [ ] Crear GitHub Release

## Checklist de verificación

- [ ] `bash tests/security.sh`
- [ ] `bash tests/qml-shared.sh`
- [ ] `bash tests/qml-syntax.sh`
- [ ] `bash tests/dock.sh`
- [ ] `bash tests/gentoo.sh`
- [ ] `bash tests/infinite.sh`
- [ ] `bash tests/sddm.sh`
- [ ] `python3 tests/hotcorner.py`
- [ ] `python3 -m py_compile` en scripts Python modificados
- [ ] `bash -n` en scripts shell modificados (y `luac -p` si se tocó Lua)

## Seguridad y compatibilidad

- [ ] Si añade descargas externas, están fijadas a tag/commit y con su SHA-256 en `install/checksums.txt`
- [ ] Las escrituras de configuración son atómicas (`.tmp` + `os.replace`)
- [ ] No se han eliminado ni debilitado checks de seguridad o CI
- [ ] No contiene secretos ni credenciales
