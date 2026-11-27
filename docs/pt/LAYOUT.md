[English](../LAYOUT.md) · [Español](../es/LAYOUT.md) · **Português** · [← Início Docs](README.md)

# Estrutura do Repositório

| Caminho | Conteúdo |
| --- | --- |
| `bin/` | Scripts auxiliares instalados em `~/.local/bin` (`rice-*`, `waybar-set`, `hypr-set`, etc.) |
| `quickshell/` | Aplicações Quickshell (`rice-desktop`, `rice-settings`, `rice-welcome`, `rice-lockscreen`, `rice-apps`, `rice-scene`) |
| `config/` | Dotfiles instalados em `~/.config` (Hyprland, Waybar, Kitty, Rofi, etc.; a config do niri é gerada por `bin/rice-niri`) |
| `lua/` | Complementos Lua para Hyprland (atalhos, Infinite Desktop, gestos, modo gaming, regras de janela) |
| `install/` | Auxiliares do instalador, detecção de distro (`install/gentoo.sh`) e hashes SHA-256 `checksums.txt` |
| `install.sh` | Instalador e atualizador interativo (`install`, `update`, `choose`, `restore`) |
| `sync.sh` | Copia sua configuração local de volta para o repo (trocando `$HOME` por `@HOME@` e verificando segredos) |
| `settings/` | Arquivos JSON de configuração padrão e sincronizada do shell |
| `sddm/` | Tema Material 3 para a tela de login SDDM |
| `wallpapers/` | Papéis de parede padrão copiados para `~/Pictures/Wallpapers` |
| `sounds/` | Sons de interface e notificação (CC0) |
| `community/` | Índice de temas da comunidade (`index.json`) e guia de envio |
| `nix/`, `flake.nix` | Módulo NixOS e definição de flake |
| `tests/` | Suíte de testes automatizados (`security.sh`, `qml-shared.sh`, `qml-syntax.sh`, `dock.sh`, `gentoo.sh`, `infinite.sh`, `sddm.sh`, `hotcorner.py`) |
| `docs/` | Documentação multilíngue (`en` na raiz, `es/`, `pt/`) |
| `.github/` | Workflows de CI (`ci.yml`, `release.yml`), modelo de PR e modelos de issues |
| `VERSION` | Versão atual do shell usada pelo verificador de atualizações |

## Sincronizando sua configuração

`./sync.sh` copia a configuração atual da sua máquina para o repositório (substituindo `$HOME` por `@HOME@` e verificando se não há segredos), enquanto `./install.sh` aplica `settings/` em outros computadores mantendo arquivos modificados localmente (`./install.sh --update --use-saved-settings` força as configurações salvas).

Para fluxo de branches, PRs e lançamento de versões, veja [CONTRIBUTING.md](../../CONTRIBUTING.md).
