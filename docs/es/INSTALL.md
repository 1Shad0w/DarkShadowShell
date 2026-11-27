[English](../INSTALL.md) · **Español** · [Português](../pt/INSTALL.md) · [← Inicio Docs](README.md)

# Instalación

Clona el repositorio con `git clone` (no uses el ZIP de Releases, para que `rice-update` pueda actualizarse limpiamente). Cada archivo que el instalador reemplaza se guarda en `~/.config/darkshadows-shell-backup-<fecha>/`.

---

## Sistemas soportados

La barra, la pantalla de bienvenida y Ajustes muestran automáticamente **el logo de tu distribución**.

| Sistema | Estado | Notas |
| --- | --- | --- |
| **Arch Linux** | Soportado | `./install.sh` |
| **CachyOS** | Soportado | Usa los repos de CachyOS y `paru` |
| **EndeavourOS / Garuda** | Soportado | Ruta de Arch con `./install.sh` |
| **Artix Linux** | Soportado | OpenRC, runit, s6 o dinit (`artix-archlinux-support` + sesión D-Bus) |
| **Fedora / Nobara** | Soportado | Usa COPR para Hyprland, Quickshell y `awww` |
| **Fedora Atomic (Bazzite, Silverblue)** | Solo comandos | El instalador imprime los comandos `rpm-ostree` |
| **Gentoo** | Soportado | OpenRC o systemd mediante `install/gentoo.sh` |
| **NixOS** | Soportado | Módulo declarativo en `nix/module.nix` o flake |
| **Manjaro** | Puede fallar | Sus paquetes retrasados pueden traer Hyprland anterior a 0.55 |

**El Centro de actualizaciones funciona en todos**: muestra las actualizaciones del shell y los paquetes del sistema (`pacman`, `dnf`, `emerge`, `xbps`, `zypper`, `apt`, `flatpak`, `snap`) y los actualiza en una terminal donde introducir la contraseña. NixOS y las Fedora atómicas muestran sus propios comandos (`nixos-rebuild`, `rpm-ostree`) en lugar de ejecutarlos automáticamente.

---

## Hyprland o niri

El shell soporta tanto **Hyprland (0.55+)** como **niri (25.05+)** en cualquiera de las distros anteriores:

- Por defecto: Hyprland
- `./install.sh --wm=niri`: configura niri
- `./install.sh --wm=both`: configura ambos (eliges en la pantalla de login)

En **niri**, la barra, isla, espacios de trabajo, widgets, dock, lanzador, bloqueo y deslizadores de Ajustes funcionan igual. El shell genera `~/.config/niri/config.kdl` (`rice-niri`) y lo valida con `niri validate`; tus ajustes propios van en `~/.config/niri/user.kdl` y siempre tienen prioridad. El desenfoque requiere niri 26.04+.

---

## Instrucciones por distribución

### Arch Linux, CachyOS, EndeavourOS, Garuda
```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh
```
No necesitas helper de AUR previo: se usa `paru` o `yay` si ya tienes uno; si no, `yay` se instala solo cuando hace falta. Los cursores Bibata se descargan de GitHub (verificados por SHA-256) si no hay helper de AUR.

### Artix Linux (OpenRC, runit, s6, dinit)
Mismos comandos que Arch. Sin systemd, el instalador además:
- Activa el repositorio `[extra]` de Arch (`artix-archlinux-support`) si Hyprland no está en los repos de Artix.
- Instala los scripts de servicio para tu init (`networkmanager-openrc`, `bluez-openrc`, etc.) y activa D-Bus, elogind, NetworkManager, Bluetooth y perfiles de energía.
- Añade las sesiones **Hyprland (DarkShadow)** y **niri (DarkShadow)** con su propio D-Bus (`dbus-run-session Hyprland` desde TTY).

PipeWire y el agente de contraseñas se inician automáticamente al entrar (`rice-sys session`). En NVIDIA, añade primero `nvidia-drm.modeset=1` a los parámetros del kernel.

### Fedora / Nobara
```bash
sudo dnf install -y git
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh
```
Hyprland, sus herramientas y Quickshell se instalan desde el COPR `nett00n/hyprland`, y `awww` desde `scottames/awww`. En Fedora Atomic (Bazzite, Silverblue), el instalador imprime los comandos `rpm-ostree`.

### Gentoo
```bash
sudo emerge --noreplace dev-vcs/git
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh            # o solo los paquetes primero: bash install/gentoo.sh (--pretend previsualiza)
```
`install/gentoo.sh` activa los repositorios `guru` y `hyproverlay`, escribe keywords y USE flags en `/etc/portage/package.accept_keywords/darkshadow-shell` y `/etc/portage/package.use/darkshadow-shell`, usa `--autounmask` solo sobre archivos `package.*` y compila todo (usando tu binhost si tienes uno) con servicios OpenRC o systemd.

### NixOS
Los paquetes se declaran en la configuración del sistema:

- **Sin flakes** (`configuration.nix`):
  ```nix
  imports = [ /ruta/a/shadows-shell/nix/module.nix ];
  programs.shadows-shell.user = "tunombre";
  programs.shadows-shell.inputGroup = true;   # opcional: solo para empujar ventanas al borde en Infinite Desktop
  ```
- **Con flakes**:
  ```nix
  inputs.DarkShadowShell.url = "github:1Shad0w/DarkShadowShell";
  # en tus módulos de nixosSystem:
  DarkShadowShell.nixosModules.default
  ```
Ejecuta `sudo nixos-rebuild switch && ./install.sh` (pon `programs.niri.enable = false;` si no quieres niri).

### Otras distribuciones
El instalador lista las dependencias que faltan (`Hyprland`, `Waybar`, `Quickshell qs`, `swaync`, `cava`, `rofi`, `jq`, `python3`, `awww`, `hyprlock`). Instálalas con tu gestor de paquetes y vuelve a ejecutar `./install.sh`.

---

## Opciones del instalador

| Opción | Qué hace |
| --- | --- |
| `--wm=hyprland` / `--wm=niri` / `--wm=both` | Elige el gestor de ventanas sin preguntar |
| `--yes` | Ejecuta todo sin preguntas interactivas |
| `--aur` / `--no-aur` | Arch: compilar `yay` y paquetes AUR / no compilar nunca `yay` |
| `--no-packages` | Salta la instalación de paquetes |
| `--dry-run` | Muestra qué ocurriría sin modificar nada |
| `--restore` | Restaura los archivos de la última copia de seguridad |

---

## Copias de seguridad y actualización

- **Copias de seguridad**: Se guardan automáticamente en `~/.config/darkshadows-shell-backup-<fecha>/`. Puedes revertir en cualquier momento con `./install.sh --restore`.
- **Actualización**: Abre **Ajustes → Centro de actualizaciones → Actualizar ahora** (progreso en vivo sin terminal), pulsa la notificación de actualización o ejecuta `rice-update` en una terminal.
