**English** · [Español](es/INSTALL.md) · [Português](pt/INSTALL.md) · [← Docs Home](README.md)

# Installation

Install directly from `1Shad0w/DarkShadowShell` with a single command (clones/updates via `git` so `rice-update` works cleanly):

```bash
curl -fsSL https://get.aurorian.es/dotfiles | bash
```

Or clone `https://github.com/1Shad0w/DarkShadowShell` manually with `git clone` (do not download a ZIP from Releases, so `rice-update` can pull updates cleanly). Every file replaced by the installer is backed up to `~/.config/darkshadows-shell-backup-<time>/`.

---

## Supported systems

The bar, welcome screen, and Settings automatically display **your distro's logo**.

| System | Status | Notes |
| --- | --- | --- |
| **Arch Linux** | Supported | `./install.sh` |
| **CachyOS** | Supported | Uses CachyOS repos and `paru` |
| **EndeavourOS / Garuda** | Supported | Arch route via `./install.sh` |
| **Artix Linux** | Supported | OpenRC, runit, s6, or dinit (`artix-archlinux-support` + D-Bus session) |
| **Fedora / Nobara** | Supported | Uses COPR for Hyprland, Quickshell, and `awww` |
| **Fedora Atomic (Bazzite, Silverblue)** | Commands only | Installer prints the `rpm-ostree` commands |
| **Gentoo** | Supported | OpenRC or systemd via `install/gentoo.sh` |
| **NixOS** | Supported | Declarative module in `nix/module.nix` or flake |
| **Manjaro** | May not work | Held-back packages may ship Hyprland older than 0.55 |

**The Update Center works across all of them**: it shows shell updates and system packages (`pacman`, `dnf`, `emerge`, `xbps`, `zypper`, `apt`, `flatpak`, `snap`) and runs them in a terminal where your password prompt belongs. NixOS and atomic Fedoras display their own commands (`nixos-rebuild`, `rpm-ostree`) instead of running them automatically.

---


## Release channels and updates

The stable channel selects the most recently published regular GitHub release. The dev channel selects the most recently published release, including prereleases. Both use the release tag, and drafts are ignored.

The installer at `https://get.aurorian.es/dotfiles` selects stable. Use `https://get.aurorian.es/dotfiles-dev` for dev. After installation, the selected channel is saved for future update checks. You can change it in Settings or with `rice-update channel stable` and `rice-update channel dev`.

The update center checks published releases and applies the selected tag. A newer commit on a branch is available after it has been published as a release.

## Hyprland or niri

The shell supports both **Hyprland (0.55+)** and **niri (25.05+)** across every distro above:

- Default: Hyprland
- `./install.sh --wm=niri`: sets up niri
- `./install.sh --wm=both`: sets up both (choose on the login screen)

On **niri**, the bar, island, workspaces, widgets, dock, launcher, lockscreen, and Settings sliders work identically. The shell generates `~/.config/niri/config.kdl` (`rice-niri`) and validates it with `niri validate`; your custom overrides live in `~/.config/niri/user.kdl` and always win. Blur requires niri 26.04+.

---

## Distro instructions

### Arch Linux, CachyOS, EndeavourOS, Garuda
```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh
```
No AUR helper is required beforehand: `paru` or `yay` is used if already present; otherwise `yay` is set up only if needed. Bibata cursors are downloaded from GitHub (SHA-256 verified) when no AUR helper is used.

### Artix Linux (OpenRC, runit, s6, dinit)
Use the same commands as Arch. Without systemd, the installer also:
- Enables Arch's `[extra]` repository (`artix-archlinux-support`) if Hyprland is missing from Artix repos.
- Installs service scripts for your init (`networkmanager-openrc`, `bluez-openrc`, etc.) and enables D-Bus, elogind, NetworkManager, Bluetooth, and power profiles.
- Adds **Hyprland (DarkShadow)** and **niri (DarkShadow)** login sessions with D-Bus (`dbus-run-session Hyprland` from TTY).

PipeWire and the polkit agent are started automatically at login (`rice-sys session`). On NVIDIA, add `nvidia-drm.modeset=1` to your kernel parameters first.

### Fedora / Nobara
```bash
sudo dnf install -y git
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh
```
Hyprland, its tools, and Quickshell are installed from the `nett00n/hyprland` COPR, and `awww` from `scottames/awww`. On Atomic Fedora (Bazzite, Silverblue), the installer prints the required `rpm-ostree` commands.

### Gentoo
```bash
sudo emerge --noreplace dev-vcs/git
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh            # or packages only first: bash install/gentoo.sh (--pretend previews)
```
`install/gentoo.sh` enables the `guru` and `hyproverlay` repositories, writes keywords and USE flags into `/etc/portage/package.accept_keywords/darkshadow-shell` and `/etc/portage/package.use/darkshadow-shell`, uses `--autounmask` only on `package.*` files, and emerges everything (using your binhost if configured) with OpenRC or systemd services.

### NixOS
Packages are declared in your system configuration:

- **Without flakes** (`configuration.nix`):
  ```nix
  imports = [ /path/to/shadows-shell/nix/module.nix ];
  programs.shadows-shell.user = "yourname";
  programs.shadows-shell.inputGroup = true;   # optional: only for Infinite Desktop edge push
  ```
- **With flakes**:
  ```nix
  inputs.DarkShadowShell.url = "github:1Shad0w/DarkShadowShell";
  # in nixosSystem modules:
  DarkShadowShell.nixosModules.default
  ```
Run `sudo nixos-rebuild switch && ./install.sh` (set `programs.niri.enable = false;` if you do not want niri).

### Other distros
The installer lists missing dependencies (`Hyprland`, `Quickshell qs`, `swaync`, `cava`, `rofi`, `jq`, `python3`, `awww`, `hyprlock`). Install them with your package manager, then run `./install.sh`.

---

## Installer options

| Option | What it does |
| --- | --- |
| `--wm=hyprland` / `--wm=niri` / `--wm=both` | Select the window manager non-interactively |
| `--yes` | Run non-interactively without prompts |
| `--aur` / `--no-aur` | Arch: always build `yay` & AUR packages / never build `yay` |
| `--no-packages` | Skip package installation |
| `--dry-run` | Show what would happen without changing files |
| `--restore` | Restore files from the latest backup |

---

## Backups & Updating

- **Backups**: Saved automatically in `~/.config/darkshadows-shell-backup-<time>/`. Undo anytime with `./install.sh --restore`.
- **Updating**: Open **Settings → Update Center → Update now** (live progress without a terminal), click the update notification, or run `rice-update` in a terminal.
