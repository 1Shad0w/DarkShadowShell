[English](../INSTALL.md) · [Español](../es/INSTALL.md) · **Português** · [← Início Docs](README.md)

# Instalação

Instale diretamente a partir de `1Shad0w/DarkShadowShell` com um único comando (clona ou atualiza via `git` para que o `rice-update` funcione corretamente):

```bash
curl -fsSL https://get.aurorian.es/dotfiles | bash
```

Ou clone `https://github.com/1Shad0w/DarkShadowShell` manualmente com `git clone` (não use o ZIP de Releases, para que o `rice-update` consiga atualizar). Cada arquivo substituído pelo instalador é salvo em `~/.config/darkshadows-shell-backup-<data>/`.

---

## Sistemas suportados

A barra, a tela de boas-vindas e as Configurações exibem automaticamente **o logo da sua distribuição**.

| Sistema | Status | Notas |
| --- | --- | --- |
| **Arch Linux** | Suportado | `./install.sh` |
| **CachyOS** | Suportado | Usa repositórios do CachyOS e `paru` |
| **EndeavourOS / Garuda** | Suportado | Rota Arch via `./install.sh` |
| **Artix Linux** | Suportado | OpenRC, runit, s6 ou dinit (`artix-archlinux-support` + sessão D-Bus) |
| **Fedora / Nobara** | Suportado | Usa COPR para Hyprland, Quickshell e `awww` |
| **Fedora Atomic (Bazzite, Silverblue)** | Apenas comandos | O instalador exibe os comandos `rpm-ostree` |
| **Gentoo** | Suportado | OpenRC ou systemd via `install/gentoo.sh` |
| **NixOS** | Suportado | Módulo declarativo em `nix/module.nix` ou flake |
| **Manjaro** | Pode falhar | Pacotes atrasados podem trazer Hyprland anterior à 0.55 |

**A Central de atualizações funciona em todos**: mostra atualizações do shell e pacotes do sistema (`pacman`, `dnf`, `emerge`, `xbps`, `zypper`, `apt`, `flatpak`, `snap`) e os executa em um terminal onde a senha deve ser digitada. NixOS e Fedoras atômicos exibem seus próprios comandos (`nixos-rebuild`, `rpm-ostree`) em vez de executá-los automaticamente.

---

## Hyprland ou niri

O shell suporta tanto **Hyprland (0.55+)** quanto **niri (25.05+)** em qualquer distro acima:

- Padrão: Hyprland
- `./install.sh --wm=niri`: configura o niri
- `./install.sh --wm=both`: configura ambos (você escolhe na tela de login)

No **niri**, a barra, ilha, workspaces, widgets, dock, lançador, tela de bloqueio e controles de Configurações funcionam da mesma forma. O shell gera `~/.config/niri/config.kdl` (`rice-niri`) e valida com `niri validate`; suas configurações pessoais ficam em `~/.config/niri/user.kdl` e sempre vencem. O desfoque requer niri 26.04+.

---

## Instruções por distribuição

### Arch Linux, CachyOS, EndeavourOS, Garuda
```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh
```
Não é preciso ter helper de AUR antes: `paru` ou `yay` são usados se já existirem; caso contrário o `yay` é instalado apenas se necessário. Os cursores Bibata são baixados do GitHub (verificados por SHA-256) quando não há helper de AUR.

### Artix Linux (OpenRC, runit, s6, dinit)
Mesmos comandos do Arch. Sem systemd, o instalador também:
- Ativa o repositório `[extra]` do Arch (`artix-archlinux-support`) se o Hyprland não estiver nos repos do Artix.
- Instala os scripts de serviço para o seu init (`networkmanager-openrc`, `bluez-openrc`, etc.) e ativa D-Bus, elogind, NetworkManager, Bluetooth e perfis de energia.
- Adiciona as sessões **Hyprland (DarkShadow)** e **niri (DarkShadow)** com D-Bus próprio (`dbus-run-session Hyprland` no TTY).

PipeWire e o agente de senha são iniciados automaticamente no login (`rice-sys session`). Em placas NVIDIA, adicione primeiro `nvidia-drm.modeset=1` aos parâmetros do kernel.

### Fedora / Nobara
```bash
sudo dnf install -y git
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh
```
Hyprland, suas ferramentas e o Quickshell vêm do COPR `nett00n/hyprland`, e `awww` de `scottames/awww`. No Fedora Atomic (Bazzite, Silverblue), o instalador imprime os comandos `rpm-ostree`.

### Gentoo
```bash
sudo emerge --noreplace dev-vcs/git
git clone https://github.com/1Shad0w/DarkShadowShell shadows-shell && cd shadows-shell
./install.sh            # ou só os pacotes antes: bash install/gentoo.sh (--pretend pré-visualiza)
```
`install/gentoo.sh` ativa os repositórios `guru` e `hyproverlay`, grava keywords e USE flags em `/etc/portage/package.accept_keywords/darkshadow-shell` e `/etc/portage/package.use/darkshadow-shell`, usa `--autounmask` apenas nos arquivos `package.*` e compila tudo (usando seu binhost se configurado) com serviços OpenRC ou systemd.

### NixOS
Os pacotes são declarados na configuração do sistema:

- **Sem flakes** (`configuration.nix`):
  ```nix
  imports = [ /caminho/para/shadows-shell/nix/module.nix ];
  programs.shadows-shell.user = "seunome";
  programs.shadows-shell.inputGroup = true;   # opcional: apenas para empurrar janelas na borda do Infinite Desktop
  ```
- **Com flakes**:
  ```nix
  inputs.DarkShadowShell.url = "github:1Shad0w/DarkShadowShell";
  # nos seus módulos nixosSystem:
  DarkShadowShell.nixosModules.default
  ```
Execute `sudo nixos-rebuild switch && ./install.sh` (use `programs.niri.enable = false;` se não quiser o niri).

### Outras distros
O instalador lista as dependências ausentes (`Hyprland`, `Waybar`, `Quickshell qs`, `swaync`, `cava`, `rofi`, `jq`, `python3`, `awww`, `hyprlock`). Instale-as com seu gerenciador de pacotes e rode `./install.sh`.

---

## Opções do instalador

| Opção | O que faz |
| --- | --- |
| `--wm=hyprland` / `--wm=niri` / `--wm=both` | Seleciona o gerenciador de janelas sem perguntar |
| `--yes` | Executa tudo sem perguntas interativas |
| `--aur` / `--no-aur` | Arch: sempre compilar `yay` e pacotes AUR / nunca compilar `yay` |
| `--no-packages` | Pula a etapa de pacotes |
| `--dry-run` | Mostra o que seria feito sem alterar nada |
| `--restore` | Restaura os arquivos do último backup |

---

## Backups e atualização

- **Backups**: Salvos automaticamente em `~/.config/darkshadows-shell-backup-<data>/`. Desfaça a qualquer momento com `./install.sh --restore`.
- **Atualizar**: Abra **Configurações → Central de atualizações → Atualizar agora** (progresso ao vivo sem terminal), clique na notificação de atualização ou rode `rice-update` no terminal.
