[English](../LAYOUT.md) · **Español** · [Português](../pt/LAYOUT.md) · [← Inicio Docs](README.md)

# Estructura del repositorio

| Ruta | Contenido |
| --- | --- |
| `bin/` | Scripts auxiliares instalados en `~/.local/bin` (`rice-*`, `waybar-set`, `hypr-set`, etc.) |
| `quickshell/` | Aplicaciones Quickshell (`rice-desktop`, `rice-settings`, `rice-welcome`, `rice-lockscreen`, `rice-apps`, `rice-scene`) |
| `config/` | Dotfiles instalados en `~/.config` (Hyprland, Waybar, Kitty, Rofi, etc.; la config de niri se genera con `bin/rice-niri`) |
| `lua/` | Complementos Lua para Hyprland (atajos, Infinite Desktop, gestos, modo gaming, reglas de ventanas) |
| `install/` | Asistentes de instalación, soporte por distro (`install/gentoo.sh`) y hashes SHA-256 `checksums.txt` |
| `install.sh` | Instalador y actualizador interactivo (`install`, `update`, `choose`, `restore`) |
| `sync.sh` | Copia tu configuración local al repo (reemplazando `$HOME` por `@HOME@` y buscando secretos) |
| `settings/` | Archivos JSON con la configuración guardada o por defecto del shell |
| `sddm/` | Tema Material 3 para la pantalla de login SDDM |
| `wallpapers/` | Fondos incluidos por defecto, copiados a `~/Pictures/Wallpapers` |
| `sounds/` | Sonidos de interfaz y notificación (CC0) |
| `community/` | Índice de temas comunitarios (`index.json`) y guía para enviarlos |
| `nix/`, `flake.nix` | Módulo para NixOS y definición de flake |
| `tests/` | Suite de tests automatizados (`security.sh`, `qml-shared.sh`, `qml-syntax.sh`, `dock.sh`, `gentoo.sh`, `infinite.sh`, `sddm.sh`, `hotcorner.py`) |
| `docs/` | Documentación multilingüe (`en` en raíz, `es/`, `pt/`) |
| `.github/` | Workflows de CI (`ci.yml`, `release.yml`), plantilla de PR y plantillas de issues |
| `VERSION` | Versión actual del shell usada por el comprobador de actualizaciones |

## Sincronizar tu configuración

`./sync.sh` copia tu configuración actual desde tu máquina al repositorio (sustituyendo `$HOME` por `@HOME@` y comprobando que no haya secretos), mientras que `./install.sh` aplica `settings/` en otros equipos respetando archivos modificados (`./install.sh --update --use-saved-settings` aplica los guardados).

Para el flujo de ramas, PRs y publicación de versiones, consulta [CONTRIBUTING.md](../../CONTRIBUTING.md).
