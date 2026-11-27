[English](../CUSTOMIZE.md) · [Español](../es/CUSTOMIZE.md) · **Português** · [← Início Docs](README.md)

# Personalizar

Tudo fica em **Configurações** (`SUPER+U`). As mesmas ações existem como comandos:

```bash
waybar-set style flat|floating|islands|island
waybar-set group none|pills|segmented
waybar-set opacity 0.9
waybar-set island-width 1000      # largura de "One island"
waybar-set power-nudge 14         # espaço à esquerda do botão de energia
waybar-set power-size 18          # tamanho do ícone de energia
waybar-set distro-icon on|off     # logo da sua distribuição
waybar-set autohide on|off
```

## Rofi
Use **Configurações > Rofi**, ou a linha de comando:

```bash
rice-rofi set theme shadow|graphite|midnight|rose|paper
rice-rofi set layout list|grid|bar
rice-rofi set position top|center|bottom
rice-rofi set transparency on|off
rice-rofi set blur on|off
rice-rofi reset          # padrões
rice-rofi restore        # restaura seus arquivos originais do rofi e Hyprland
```
O tema é gravado em `~/.config/rofi/shadows.rasi` e carregado por `~/.config/rofi/config.rasi`. Suas linhas `@theme` anteriores são comentadas (backup: `config.rasi.bak-rice-rofi`).

## Tema
```bash
rice-colors list             # todos os esquemas
rice-colors mode ocean       # auto, grey, navy, mono, slate, stone, steel, ash, ink, ocean, sky, ...
```

## Notificações (swaync)
```bash
rice-notify set pos_x left|center|right
rice-notify set layout controls-top|controls-bottom|minimal
rice-notify set style glass|solid|outline
rice-notify test             # envia uma notificação de teste
rice-notify restore          # restaura seus arquivos originais do swaync
```

## Ociosidade e Tela de Bloqueio (hypridle + hyprlock)
```bash
rice-lock set lock_after 5          # minutos, 0 = nunca
rice-lock set suspend_after 30
rice-lock set clock big|stacked|minimal
rice-lock set background screenshot|wallpaper|color
rice-lock restore                   # restaura seus hyprlock.conf e hypridle.conf originais
```

## Capturas e gravação
```bash
rice-hotcorner shot region   # captura de uma região
rice-hotcorner record full   # inicia gravação (rode "record stop" para parar)
```
